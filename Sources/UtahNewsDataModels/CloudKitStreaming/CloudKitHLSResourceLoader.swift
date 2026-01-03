//
//  CloudKitHLSResourceLoader.swift
//  UtahNewsData
//
//  Custom AVAssetResourceLoaderDelegate for handling cloudkit:// URLs in HLS manifests.
//  Intercepts AVPlayer requests and fetches segments from CloudKit Public Database.
//
//  Supports two modes:
//  1. **HTTPS Streaming** (preferred): Uses CloudKit Web Services to get direct HTTPS URLs
//  2. **Native SDK Fallback**: Downloads segments via CKAsset when Web Services not configured
//

import Foundation
import AVFoundation
import CloudKit
import os

private let resourceLogger = Logger(subsystem: "com.utahnews.data", category: "HLSResourceLoader")

/// Custom resource loader for handling cloudkit:// URLs in HLS manifests
/// Intercepts AVPlayer requests and fetches segments from CloudKit Public Database
public final class CloudKitHLSResourceLoader: NSObject, AVAssetResourceLoaderDelegate, Sendable {
    private let container: CKContainer
    private let publicDB: CKDatabase

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

    // Cache directory for downloaded segments (fallback mode)
    private let cacheDirectory: URL = {
        let tempDir = FileManager.default.temporaryDirectory
        let cacheDir = tempDir.appendingPathComponent("CloudKitHLSCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        return cacheDir
    }()

    public override init() {
        container = CKContainer(identifier: CloudKitStreamingConfig.containerID)
        publicDB = container.publicCloudDatabase

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
        container = CKContainer(identifier: CloudKitStreamingConfig.containerID)
        publicDB = container.publicCloudDatabase

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

    /// Inject master manifest content to be served when requested
    public func injectMasterManifest(content: String, for videoSlug: String) {
        resourceLogger.debug("Injecting master manifest for slug: \(videoSlug)")
        masterManifests[videoSlug] = content
    }

    /// Fetch master manifest from CloudKit VideoAsset record
    /// Call this before playback if manifest content is not available locally
    public func fetchMasterManifest(for videoSlug: String) async throws -> String {
        resourceLogger.info("Fetching master manifest from CloudKit for: \(videoSlug)")

        // Query VideoAsset by slug
        let predicate = NSPredicate(format: "slug == %@", videoSlug)
        let query = CKQuery(recordType: "VideoAsset", predicate: predicate)
        let results = try await publicDB.records(matching: query)

        guard let firstResult = results.matchResults.first else {
            throw CloudKitHLSError.segmentNotFound("VideoAsset not found for slug: \(videoSlug)")
        }

        let (_, result) = firstResult
        let record = try result.get()

        // Get the manifest CKAsset
        guard let manifestAsset = record["manifest"] as? CKAsset,
              let manifestFileURL = manifestAsset.fileURL else {
            throw CloudKitHLSError.assetNotFound
        }

        // Read the manifest content
        let manifestContent = try String(contentsOf: manifestFileURL, encoding: .utf8)
        resourceLogger.info("Fetched master manifest (\(manifestContent.count) chars) for: \(videoSlug)")

        // Cache it for future requests
        masterManifests[videoSlug] = manifestContent

        return manifestContent
    }

    /// Ensure master manifest is available (fetch from CloudKit if needed)
    public func ensureMasterManifest(for videoSlug: String) async throws {
        if masterManifests[videoSlug] != nil {
            resourceLogger.debug("Master manifest already cached for: \(videoSlug)")
            return
        }

        _ = try await fetchMasterManifest(for: videoSlug)
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
                if httpsStreamingEnabled {
                    // Use HTTPS streaming
                    try await handleStreamingRequest(loadingRequest, for: url, requestID: String(requestID))
                } else {
                    // Legacy: Download via native SDK
                    try await handleLoadingRequest(loadingRequest, for: url, requestID: String(requestID))
                }
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
            // Fall back to native SDK
            resourceLogger.warning("[\(requestID)] HTTPS URL not available, falling back to native SDK")
            try await handleLoadingRequest(loadingRequest, for: url, requestID: requestID)
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

    // MARK: - Native SDK Fallback Mode

    private func handleLoadingRequest(
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

        resourceLogger.debug("[\(requestID)] Native SDK mode - videoSlug: '\(videoSlug)', relativePath: '\(decodedPath)'")

        // Check if this is a master manifest request
        if decodedPath == "master.m3u8" {
            resourceLogger.debug("[\(requestID)] Master manifest requested")
            guard let manifestContent = masterManifests[videoSlug] else {
                throw CloudKitHLSError.segmentNotFound(decodedPath)
            }

            let data = Data(manifestContent.utf8)
            resourceLogger.debug("[\(requestID)] Returning cached master manifest (\(data.count) bytes)")

            fillContentInfo(loadingRequest, contentType: "application/vnd.apple.mpegurl", length: data.count)
            fillDataRequest(loadingRequest, data: data)
            loadingRequest.finishLoading()
            return
        }

        // Query CloudKit for this segment
        let predicate: NSPredicate
        if decodedPath.hasSuffix(".m3u8") {
            predicate = NSPredicate(
                format: "videoSlug == %@ AND relativePath == %@ AND segmentType == %@",
                videoSlug,
                decodedPath,
                "variant"
            )
        } else {
            predicate = NSPredicate(
                format: "videoSlug == %@ AND relativePath == %@ AND segmentType != %@",
                videoSlug,
                decodedPath,
                "variant"
            )
        }

        let query = CKQuery(recordType: "VideoSegment", predicate: predicate)
        let results = try await publicDB.records(matching: query)

        guard let firstResult = results.matchResults.first else {
            throw CloudKitHLSError.segmentNotFound(decodedPath)
        }

        let (recordID, result) = firstResult
        let record = try result.get()

        resourceLogger.debug("[\(requestID)] Found CloudKit record: \(recordID.recordName)")

        guard let asset = record["segmentFile"] as? CKAsset,
              let assetFileURL = asset.fileURL else {
            throw CloudKitHLSError.assetNotFound
        }

        let data = try Data(contentsOf: assetFileURL)
        resourceLogger.debug("[\(requestID)] Loaded \(data.count) bytes")

        // For video segments, cache to local file and provide redirect
        if !decodedPath.hasSuffix(".m3u8") {
            let cacheFileName = "\(videoSlug)_\(decodedPath.replacingOccurrences(of: "/", with: "_"))"
            let cacheFileURL = cacheDirectory.appendingPathComponent(cacheFileName)

            if !FileManager.default.fileExists(atPath: cacheFileURL.path) {
                try data.write(to: cacheFileURL)
                resourceLogger.debug("[\(requestID)] Cached to: \(cacheFileURL.path)")
            }

            redirectToURL(loadingRequest, url: cacheFileURL)
            return
        }

        // For manifests, serve directly
        let contentType = decodedPath.hasSuffix(".m3u8") ? "application/vnd.apple.mpegurl" : "video/mp4"
        fillContentInfo(loadingRequest, contentType: contentType, length: data.count)
        fillDataRequest(loadingRequest, data: data)
        loadingRequest.finishLoading()
    }

    /// Fetch segment data from CloudKit (for streaming mode manifest fetching)
    private func fetchSegmentData(videoSlug: String, relativePath: String, requestID: String) async throws -> Data {
        resourceLogger.debug("[\(requestID)] Fetching segment data: \(relativePath)")

        let predicate: NSPredicate
        if relativePath.hasSuffix(".m3u8") {
            predicate = NSPredicate(
                format: "videoSlug == %@ AND relativePath == %@ AND segmentType == %@",
                videoSlug,
                relativePath,
                "variant"
            )
        } else {
            predicate = NSPredicate(
                format: "videoSlug == %@ AND relativePath == %@ AND segmentType != %@",
                videoSlug,
                relativePath,
                "variant"
            )
        }

        let query = CKQuery(recordType: "VideoSegment", predicate: predicate)
        let results = try await publicDB.records(matching: query)

        guard let firstResult = results.matchResults.first else {
            throw CloudKitHLSError.segmentNotFound(relativePath)
        }

        let (_, result) = firstResult
        let record = try result.get()

        guard let asset = record["segmentFile"] as? CKAsset,
              let assetFileURL = asset.fileURL else {
            throw CloudKitHLSError.assetNotFound
        }

        return try Data(contentsOf: assetFileURL)
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
