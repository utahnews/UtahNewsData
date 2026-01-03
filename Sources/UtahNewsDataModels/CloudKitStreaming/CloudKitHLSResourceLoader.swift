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

        // Handle media segments - redirect to HTTPS URL
        if let cachedURL = await urlCache.getURL(for: decodedPath, videoSlug: videoSlug) {
            resourceLogger.debug("[\(requestID)] Redirecting to HTTPS: \(cachedURL.absoluteString.prefix(80))...")
            redirectToURL(loadingRequest, url: cachedURL)
            return
        }

        // URL not cached - try to refresh
        do {
            let freshURL = try await urlCache.refreshURL(for: decodedPath, videoSlug: videoSlug)
            resourceLogger.debug("[\(requestID)] Refreshed URL, redirecting to HTTPS")
            redirectToURL(loadingRequest, url: freshURL)
        } catch {
            // Web Services failed - cannot fall back to native SDK (doesn't work in UtahNews)
            resourceLogger.error("[\(requestID)] Failed to get HTTPS URL for segment: \(error.localizedDescription)")
            throw CloudKitHLSError.downloadFailed("Failed to get streaming URL: \(error.localizedDescription)")
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
    private func fetchSegmentData(videoSlug: String, relativePath: String, requestID: String) async throws -> Data {
        resourceLogger.debug("[\(requestID)] Fetching segment data via Web Services: \(relativePath)")

        // Use URL cache to get the download URL, then fetch content
        // First try to get from cache
        if let cachedURL = await urlCache.getURL(for: relativePath, videoSlug: videoSlug) {
            resourceLogger.debug("[\(requestID)] Got cached URL for segment, downloading content")
            let (data, response) = try await URLSession.shared.data(from: cachedURL)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw CloudKitHLSError.downloadFailed("HTTP error downloading segment")
            }

            return data
        }

        // Try to refresh/fetch the URL
        do {
            let freshURL = try await urlCache.refreshURL(for: relativePath, videoSlug: videoSlug)
            resourceLogger.debug("[\(requestID)] Got fresh URL for segment, downloading content")

            let (data, response) = try await URLSession.shared.data(from: freshURL)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw CloudKitHLSError.downloadFailed("HTTP error downloading segment")
            }

            return data
        } catch {
            resourceLogger.error("[\(requestID)] Failed to fetch segment via Web Services: \(error.localizedDescription)")
            throw CloudKitHLSError.segmentNotFound(relativePath)
        }
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
