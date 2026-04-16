//
//  CloudKitHLSResourceLoader.swift
//  UtahNewsData
//
//  Custom AVAssetResourceLoaderDelegate for handling cloudkit:// URLs in HLS manifests.
//  Intercepts AVPlayer requests and fetches segments via CloudKit Web Services API.
//
//  Usage:
//  1. Inject master manifest from Firestore via injectMasterManifest(content:for:)
//  2. Enable HTTPS streaming via enableHTTPSStreaming()
//  3. Create AVURLAsset with cloudkit:// URL and set this as resource loader delegate
//

import Foundation
import AVFoundation
import os

private let resourceLogger = Logger(subsystem: "com.utahnews.data", category: "HLSResourceLoader")

/// Custom resource loader for handling cloudkit:// URLs in HLS manifests
/// Intercepts AVPlayer requests and fetches segments via CloudKit Web Services API
public final class CloudKitHLSResourceLoader: NSObject, AVAssetResourceLoaderDelegate, Sendable {
    // Cache for master manifests - accessed only from resource loader queue
    nonisolated(unsafe) private var masterManifests: [String: String] = [:]

    // MARK: - Streaming Support

    /// CloudKit Web Service for fetching HTTPS download URLs
    private let webService: CloudKitWebService

    /// URL cache for HTTPS streaming (shared instance)
    private let urlCache: PlaybackURLCache

    /// Manifest generator for dynamic URL injection
    private let manifestGenerator: DynamicManifestGenerator

    /// Whether HTTPS streaming is enabled (API token configured)
    nonisolated(unsafe) private var httpsStreamingEnabled = false

    /// Configured URLSession for reliable segment downloads on cellular/constrained networks
    private let downloadSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.allowsConstrainedNetworkAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()

    public override init() {
        // Initialize streaming components - share single webService instance
        let sharedWebService = CloudKitWebService()
        self.webService = sharedWebService
        self.urlCache = PlaybackURLCache(webService: sharedWebService)
        self.manifestGenerator = DynamicManifestGenerator(urlCache: urlCache)

        super.init()

        resourceLogger.info("CloudKitHLSResourceLoader initialized")
    }

    /// Initialize with custom components (for testing or shared instances)
    public init(webService: CloudKitWebService, urlCache: PlaybackURLCache, manifestGenerator: DynamicManifestGenerator) {

        self.webService = webService
        self.urlCache = urlCache
        self.manifestGenerator = manifestGenerator

        super.init()
    }

    // MARK: - Configuration

    /// Enable HTTPS streaming mode with default API token
    public func enableHTTPSStreaming() async {
        await webService.configure(apiToken: CloudKitStreamingConfig.apiToken)
        httpsStreamingEnabled = true
        resourceLogger.info("HTTPS streaming enabled with default token")
    }

    /// Enable HTTPS streaming mode with custom API token
    public func enableHTTPSStreaming(apiToken: String) async {
        await webService.configure(apiToken: apiToken)
        httpsStreamingEnabled = true
        resourceLogger.info("HTTPS streaming enabled with custom token")
    }

    /// Prefetch all URLs for a video (call before playback)
    public func prefetchURLs(for videoSlug: String) async throws {
        resourceLogger.info("Prefetching URLs for video: \(videoSlug)")
        try await urlCache.prefetchURLs(videoSlug: videoSlug)
    }

    /// Access to URL cache for external prefetching
    public var sharedURLCache: PlaybackURLCache {
        urlCache
    }

    /// Inject master manifest content to be served when requested.
    /// Call this before playback with manifest content from Firestore.
    public func injectMasterManifest(content: String, for videoSlug: String) {
        resourceLogger.debug("Injecting master manifest for slug: \(videoSlug)")
        masterManifests[videoSlug] = content
    }

    /// Clear cached manifest for a video
    public func clearManifest(for videoSlug: String) {
        masterManifests.removeValue(forKey: videoSlug)
    }

    /// Clear all cached manifests
    public func clearAllManifests() {
        masterManifests.removeAll()
    }

    // MARK: - AVAssetResourceLoaderDelegate

    public func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        guard let url = loadingRequest.request.url,
              url.scheme == CloudKitStreamingConfig.urlScheme else {
            resourceLogger.warning("Not a cloudkit:// URL: \(loadingRequest.request.url?.absoluteString ?? "nil")")
            return false
        }

        let requestID = UUID().uuidString.prefix(8)
        resourceLogger.debug("[\(requestID)] Handling request for: \(url.absoluteString)")

        // Handle request asynchronously
        Task {
            do {
                guard httpsStreamingEnabled else {
                    throw CloudKitHLSError.downloadFailed("HTTPS streaming not enabled. Call enableHTTPSStreaming() first.")
                }
                try await handleStreamingRequest(loadingRequest, for: url, requestID: String(requestID))
            } catch {
                resourceLogger.error("[\(requestID)] Error handling request: \(error.localizedDescription)")
                loadingRequest.finishLoading(with: error)
            }
        }

        return true
    }

    /// Handles renewal of a resource whose prior response (302 redirect URL)
    /// has expired mid-playback. AVPlayer calls this when a cached CloudKit
    /// signed URL 403s after the 60-minute validity window; we invalidate
    /// the cache and re-fetch a fresh URL.
    ///
    /// Without implementing this, a renewal failure terminates playback. With
    /// it, users get seamless recovery across long-form content.
    ///
    /// Apple Docs: https://developer.apple.com/documentation/avfoundation/avassetresourceloaderdelegate/1388027-resourceloader
    public func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest
    ) -> Bool {
        guard let url = renewalRequest.request.url,
              url.scheme == CloudKitStreamingConfig.urlScheme,
              let (videoSlug, relativePath) = parseCloudKitURL(url),
              let decodedPath = relativePath.removingPercentEncoding
        else { return false }

        let requestID = UUID().uuidString.prefix(8)
        resourceLogger.info("[\(requestID)] Renewal requested for: \(decodedPath)")

        Task {
            do {
                guard httpsStreamingEnabled else {
                    throw CloudKitHLSError.downloadFailed("HTTPS streaming not enabled")
                }
                // Invalidate prior cache entry and get a fresh signed URL.
                let freshURL = try await self.urlCache.refreshURL(
                    for: decodedPath, videoSlug: videoSlug
                )
                self.redirectToURL(renewalRequest, url: freshURL)
            } catch {
                resourceLogger.error("[\(requestID)] Renewal failed: \(error.localizedDescription)")
                renewalRequest.finishLoading(with: error)
            }
        }
        return true
    }

    // MARK: - HTTPS Streaming Mode

    /// Handle request using HTTPS streaming URLs
    private func handleStreamingRequest(
        _ loadingRequest: AVAssetResourceLoadingRequest,
        for url: URL,
        requestID: String
    ) async throws {
        guard let (videoSlug, relativePath) = parseCloudKitURL(url) else {
            throw CloudKitHLSError.invalidURL(url.absoluteString)
        }

        guard let decodedPath = relativePath.removingPercentEncoding else {
            throw CloudKitHLSError.invalidURL(url.absoluteString)
        }

        resourceLogger.debug("[\(requestID)] HTTPS mode - videoSlug: '\(videoSlug)', path: '\(decodedPath)'")

        // Handle master manifest
        if decodedPath == "master.m3u8" {
            guard let originalManifest = masterManifests[videoSlug] else {
                throw CloudKitHLSError.segmentNotFound(decodedPath)
            }

            // Generate manifest with current HTTPS URLs
            let streamingManifest = try await manifestGenerator.generateManifest(
                original: originalManifest,
                videoSlug: videoSlug
            )

            let data = Data(streamingManifest.utf8)
            resourceLogger.debug("[\(requestID)] Serving streaming master manifest (\(data.count) bytes)")

            fillContentInfo(loadingRequest, contentType: "application/vnd.apple.mpegurl", length: data.count)
            fillDataRequest(loadingRequest, data: data)
            loadingRequest.finishLoading()
            return
        }

        // Handle variant manifests (.m3u8)
        if decodedPath.hasSuffix(".m3u8") {
            // Fetch variant manifest from CloudKit, then rewrite URLs
            let manifestData = try await fetchSegmentData(videoSlug: videoSlug, relativePath: decodedPath, requestID: requestID)

            guard let originalContent = String(data: manifestData, encoding: .utf8) else {
                throw CloudKitHLSError.downloadFailed("Failed to decode manifest as UTF-8")
            }

            // Rewrite URLs in variant manifest
            let streamingManifest = try await manifestGenerator.generateManifest(
                original: originalContent,
                videoSlug: videoSlug
            )

            let data = Data(streamingManifest.utf8)
            resourceLogger.debug("[\(requestID)] Serving streaming variant manifest (\(data.count) bytes)")

            fillContentInfo(loadingRequest, contentType: "application/vnd.apple.mpegurl", length: data.count)
            fillDataRequest(loadingRequest, data: data)
            loadingRequest.finishLoading()
            return
        }

        // Handle media segments — redirect to HTTPS URL with exponential
        // backoff + jitter. On 503/429 responses the upstream error should
        // carry a Retry-After hint (parsed in `backoffDelay`), otherwise we
        // fall back to 0.5s * 2^(attempt-1) with ±20% jitter, capped at 8s.
        let maxAttempts = 4
        for attempt in 1...maxAttempts {
            // Try cached URL first
            if let cachedURL = await urlCache.getURL(for: decodedPath, videoSlug: videoSlug) {
                resourceLogger.debug("[\(requestID)] Redirecting to HTTPS: \(cachedURL.absoluteString.prefix(80))...")
                redirectToURL(loadingRequest, url: cachedURL)
                return
            }

            // URL not cached - try to refresh from CloudKit Web Services
            do {
                let freshURL = try await urlCache.refreshURL(for: decodedPath, videoSlug: videoSlug)
                resourceLogger.debug("[\(requestID)] Refreshed URL, redirecting to HTTPS")
                redirectToURL(loadingRequest, url: freshURL)
                return
            } catch {
                if attempt < maxAttempts {
                    let delayMs = Self.backoffDelay(attempt: attempt, error: error)
                    resourceLogger.warning(
                        "[\(requestID)] Attempt \(attempt)/\(maxAttempts) failed for \(decodedPath) (\(error.localizedDescription)); retrying in \(delayMs)ms"
                    )
                    try? await Task.sleep(for: .milliseconds(delayMs))
                } else {
                    resourceLogger.error("[\(requestID)] Failed to get HTTPS URL after \(maxAttempts) attempts: \(error.localizedDescription)")
                    throw CloudKitHLSError.downloadFailed("Failed to get streaming URL after \(maxAttempts) attempts: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Redirect AVPlayer to an HTTPS URL
    private func redirectToURL(_ loadingRequest: AVAssetResourceLoadingRequest, url: URL) {
        let redirectRequest = URLRequest(url: url)
        loadingRequest.redirect = redirectRequest

        let response = HTTPURLResponse(
            url: loadingRequest.request.url!,
            statusCode: 302,
            httpVersion: "HTTP/1.1",
            headerFields: ["Location": url.absoluteString]
        )
        loadingRequest.response = response
        loadingRequest.finishLoading()
    }

    /// Fill content information request
    private func fillContentInfo(_ loadingRequest: AVAssetResourceLoadingRequest, contentType: String, length: Int) {
        if let contentInfo = loadingRequest.contentInformationRequest {
            contentInfo.contentLength = Int64(length)
            contentInfo.isByteRangeAccessSupported = true
            contentInfo.contentType = contentType
        }
    }

    /// Fill data request
    private func fillDataRequest(_ loadingRequest: AVAssetResourceLoadingRequest, data: Data) {
        if let dataRequest = loadingRequest.dataRequest {
            let offset = Int(dataRequest.currentOffset)
            let requestedLength = dataRequest.requestedLength
            let remainingBytes = data.count - offset
            let bytesToSend = requestedLength > 0 ? min(requestedLength, remainingBytes) : remainingBytes

            guard offset >= 0 && offset < data.count else { return }

            let endOffset = min(offset + bytesToSend, data.count)
            let subdata = data.subdata(in: offset..<endOffset)
            dataRequest.respond(with: subdata)
        }
    }

    /// Fetch segment data via Web Services API (for variant manifests)
    /// Uses configured downloadSession for reliable cellular/constrained network access.
    ///
    /// Responses with 503 / 429 status codes are explicitly retry-able with
    /// exponential backoff; the `Retry-After` response header (if present) is
    /// honored verbatim. Other non-200 statuses treat the cached URL as stale,
    /// invalidate it, and retry with a fresh URL.
    private func fetchSegmentData(videoSlug: String, relativePath: String, requestID: String) async throws -> Data {
        resourceLogger.debug("[\(requestID)] Fetching segment data via Web Services: \(relativePath)")

        let maxAttempts = 4
        for attempt in 1...maxAttempts {
            do {
                let url: URL
                if let cached = await urlCache.getURL(for: relativePath, videoSlug: videoSlug) {
                    url = cached
                } else {
                    url = try await urlCache.refreshURL(for: relativePath, videoSlug: videoSlug)
                }

                let (data, response) = try await downloadSession.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw CloudKitHLSError.downloadFailed("Non-HTTP response")
                }

                switch httpResponse.statusCode {
                case 200:
                    return data

                case 429, 503:
                    // Rate-limited / service overloaded. Respect Retry-After.
                    let hintMs = Self.retryAfterMilliseconds(from: httpResponse)
                    if attempt < maxAttempts {
                        let delayMs = hintMs ?? Self.backoffDelay(attempt: attempt, error: nil)
                        resourceLogger.warning(
                            "[\(requestID)] \(httpResponse.statusCode) from CDN for \(relativePath); retrying in \(delayMs)ms"
                        )
                        try? await Task.sleep(for: .milliseconds(delayMs))
                        continue
                    }
                    throw CloudKitHLSError.downloadFailed("HTTP \(httpResponse.statusCode) after \(maxAttempts) attempts")

                case 403, 410:
                    // Signed URL expired / gone — force refresh on next loop.
                    await urlCache.clearCache(for: videoSlug)
                    if attempt < maxAttempts { continue }
                    throw CloudKitHLSError.downloadFailed("HTTP \(httpResponse.statusCode) (URL expired)")

                default:
                    throw CloudKitHLSError.downloadFailed("HTTP \(httpResponse.statusCode)")
                }
            } catch {
                if attempt < maxAttempts {
                    let delayMs = Self.backoffDelay(attempt: attempt, error: error)
                    resourceLogger.warning("[\(requestID)] Attempt \(attempt)/\(maxAttempts) failed for segment \(relativePath): \(error.localizedDescription); retrying in \(delayMs)ms")
                    try? await Task.sleep(for: .milliseconds(delayMs))
                } else {
                    resourceLogger.error("[\(requestID)] Failed to fetch segment after \(maxAttempts) attempts: \(error.localizedDescription)")
                    throw CloudKitHLSError.segmentNotFound(relativePath)
                }
            }
        }

        // Should not reach here due to throw in final attempt, but satisfy compiler
        throw CloudKitHLSError.segmentNotFound(relativePath)
    }

    // MARK: - Backoff helpers

    /// Compute retry delay in milliseconds using exponential backoff with ±20%
    /// jitter, capped at 8s. `attempt` is 1-indexed.
    ///
    /// 500ms, 1000ms, 2000ms, 4000ms, 8000ms (clamped).
    nonisolated private static func backoffDelay(attempt: Int, error: Error?) -> Int {
        let base = 500 << max(0, attempt - 1)                   // 500 * 2^(n-1)
        let capped = min(base, 8_000)
        // Jitter ±20%
        let jitter = Int.random(in: -(capped / 5)...(capped / 5))
        return max(50, capped + jitter)
    }

    /// Parse the `Retry-After` header (seconds or HTTP-date) into milliseconds.
    nonisolated private static func retryAfterMilliseconds(from response: HTTPURLResponse) -> Int? {
        guard let raw = (response.value(forHTTPHeaderField: "Retry-After")
            ?? response.value(forHTTPHeaderField: "retry-after"))?.trimmingCharacters(in: .whitespaces)
        else { return nil }

        if let seconds = Int(raw) {
            return max(50, seconds * 1000)
        }
        // HTTP-date form
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        if let date = formatter.date(from: raw) {
            let delta = date.timeIntervalSinceNow
            guard delta > 0 else { return 50 }
            return Int(delta * 1000)
        }
        return nil
    }

    // MARK: - URL Parsing

    private func parseCloudKitURL(_ url: URL) -> (videoSlug: String, relativePath: String)? {
        guard url.scheme == CloudKitStreamingConfig.urlScheme else { return nil }

        let urlString = url.absoluteString
        let withoutScheme = urlString.replacingOccurrences(of: "\(CloudKitStreamingConfig.urlScheme)://", with: "")

        guard let firstSlashIndex = withoutScheme.firstIndex(of: "/") else { return nil }

        let videoSlug = String(withoutScheme[..<firstSlashIndex])
        let relativePath = String(withoutScheme[withoutScheme.index(after: firstSlashIndex)...])

        return (videoSlug, relativePath)
    }
}

// MARK: - Convenience Factory

extension CloudKitHLSResourceLoader {

    /// Create a configured resource loader ready for HTTPS streaming
    public static func configuredLoader() async -> CloudKitHLSResourceLoader {
        let loader = CloudKitHLSResourceLoader()
        await loader.enableHTTPSStreaming()
        return loader
    }

    /// Create streaming URL for a video
    public static func streamingURL(for videoSlug: String) -> URL {
        URL(string: "\(CloudKitStreamingConfig.urlScheme)://\(videoSlug)/master.m3u8")!
    }
}
