//
//  PlaybackURLCache.swift
//  UtahNewsData
//
//  Caches CloudKit download URLs with expiry tracking for seamless HLS streaming.
//

import Foundation
import os

private let logger = Logger(subsystem: "com.utahnews.data", category: "PlaybackURLCache")

// MARK: - PlaybackURLCache

/// Caches CloudKit download URLs with automatic expiry tracking
/// Provides fast synchronous URL lookup with async background refresh
public actor PlaybackURLCache {

    // MARK: - Types

    /// Cached URL with expiry tracking
    private struct CachedURL: Sendable {
        let url: URL
        let cachedAt: Date
        let expiresAt: Date

        var isExpired: Bool {
            Date() > expiresAt
        }

        var isNearExpiry: Bool {
            // Consider "near expiry" if less than 10 minutes remaining
            Date().addingTimeInterval(600) > expiresAt
        }

        var timeRemaining: TimeInterval {
            expiresAt.timeIntervalSinceNow
        }
    }

    // MARK: - Properties

    /// URL cache keyed by "videoSlug/relativePath"
    private var cache: [String: CachedURL] = [:]

    /// Default URL validity duration (CloudKit URLs typically valid ~1 hour)
    private let defaultExpirySeconds: TimeInterval = 3000 // 50 minutes (with 10-minute buffer)

    /// CloudKit Web Service for fetching fresh URLs
    private let webService: CloudKitWebService

    /// Background refresh task
    private var refreshTask: Task<Void, Never>?

    /// Current video being cached (for background refresh)
    private var currentVideoSlug: String?

    /// In-flight refresh requests - prevents duplicate CloudKit queries for the same segment
    /// Key: cacheKey (videoSlug/relativePath), Value: Task that will resolve to the URL
    private var inFlightRequests: [String: Task<URL, Error>] = [:]

    // MARK: - Initialization

    public init(webService: CloudKitWebService) {
        self.webService = webService
        logger.info("PlaybackURLCache initialized")
    }

    /// Convenience initializer that creates its own web service
    public init() {
        self.webService = CloudKitWebService()
        logger.info("PlaybackURLCache initialized with default web service")
    }

    // MARK: - Public API

    /// Get cached URL if valid, nil if expired or not cached
    public func getURL(for relativePath: String, videoSlug: String) -> URL? {
        let key = cacheKey(videoSlug: videoSlug, relativePath: relativePath)

        guard let cached = cache[key] else {
            logger.debug("Cache miss for: \(key)")
            return nil
        }

        if cached.isExpired {
            logger.debug("Cache expired for: \(key)")
            cache.removeValue(forKey: key)
            return nil
        }

        logger.debug("Cache hit for: \(key), \(Int(cached.timeRemaining))s remaining")
        return cached.url
    }

    /// Update cache with fresh URLs
    public func updateURLs(_ urls: [String: URL], videoSlug: String, expirySeconds: TimeInterval? = nil) {
        let expiry = expirySeconds ?? defaultExpirySeconds
        let now = Date()
        let expiresAt = now.addingTimeInterval(expiry)

        for (relativePath, url) in urls {
            let key = cacheKey(videoSlug: videoSlug, relativePath: relativePath)
            cache[key] = CachedURL(url: url, cachedAt: now, expiresAt: expiresAt)
        }

        logger.info("Updated cache with \(urls.count) URLs, expires in \(Int(expiry))s")
    }

    /// Prefetch all URLs for a video's segments
    public func prefetchURLs(videoSlug: String) async throws {
        logger.info("Prefetching URLs for video: \(videoSlug)")

        let pathURLs = try await webService.fetchDownloadURLsForVideo(videoSlug: videoSlug)

        updateURLs(pathURLs, videoSlug: videoSlug)

        // Start background refresh if not already running
        currentVideoSlug = videoSlug
        startBackgroundRefresh(for: videoSlug)

        logger.info("Prefetched \(pathURLs.count) URLs for video: \(videoSlug)")
    }

    /// Refresh a specific URL (called on 403 error or cache miss)
    /// Uses request deduplication to prevent multiple concurrent CloudKit queries for the same segment
    public func refreshURL(for relativePath: String, videoSlug: String) async throws -> URL {
        let key = cacheKey(videoSlug: videoSlug, relativePath: relativePath)

        // Check if a request is already in flight for this segment
        if let existingTask = inFlightRequests[key] {
            logger.debug("Awaiting existing request for: \(relativePath)")
            return try await existingTask.value
        }

        logger.info("Refreshing URL for: \(relativePath)")

        // Create a new task for this request
        let task = Task<URL, Error> { [weak self] in
            guard let self = self else {
                throw PlaybackURLCacheError.urlNotFound(relativePath)
            }

            // Clean up when done (whether success or failure)
            defer {
                Task { await self.removeInFlightRequest(for: key) }
            }

            let pathURLs = try await self.webService.fetchDownloadURLsForVideo(
                videoSlug: videoSlug,
                segmentPaths: [relativePath]
            )

            guard let url = pathURLs[relativePath] else {
                throw PlaybackURLCacheError.urlNotFound(relativePath)
            }

            await self.updateURLs([relativePath: url], videoSlug: videoSlug)

            return url
        }

        // Store the task so other requests can await it
        inFlightRequests[key] = task

        return try await task.value
    }

    /// Remove an in-flight request from tracking (called when request completes)
    private func removeInFlightRequest(for key: String) {
        inFlightRequests.removeValue(forKey: key)
    }

    /// Clear cache for a specific video
    public func clearCache(for videoSlug: String) {
        let prefix = "\(videoSlug)/"
        let keysToRemove = cache.keys.filter { $0.hasPrefix(prefix) }

        for key in keysToRemove {
            cache.removeValue(forKey: key)
        }

        // Cancel in-flight requests for this video
        let inFlightKeysToRemove = inFlightRequests.keys.filter { $0.hasPrefix(prefix) }
        for key in inFlightKeysToRemove {
            inFlightRequests[key]?.cancel()
            inFlightRequests.removeValue(forKey: key)
        }

        // Cancel background refresh if it's for this video
        if currentVideoSlug == videoSlug {
            refreshTask?.cancel()
            refreshTask = nil
            currentVideoSlug = nil
        }

        logger.info("Cleared cache for video: \(videoSlug), removed \(keysToRemove.count) entries, cancelled \(inFlightKeysToRemove.count) in-flight requests")
    }

    /// Clear entire cache
    public func clearAllCache() {
        cache.removeAll()

        // Cancel all in-flight requests
        for (_, task) in inFlightRequests {
            task.cancel()
        }
        inFlightRequests.removeAll()

        refreshTask?.cancel()
        refreshTask = nil
        currentVideoSlug = nil
        logger.info("Cleared all cached URLs and in-flight requests")
    }

    /// Get cache statistics
    public func cacheStats() -> (total: Int, expired: Int, nearExpiry: Int) {
        var expired = 0
        var nearExpiry = 0

        for (_, cached) in cache {
            if cached.isExpired {
                expired += 1
            } else if cached.isNearExpiry {
                nearExpiry += 1
            }
        }

        return (cache.count, expired, nearExpiry)
    }

    // MARK: - Background Refresh

    /// Start background refresh timer
    private func startBackgroundRefresh(for videoSlug: String) {
        // Cancel any existing refresh task
        refreshTask?.cancel()

        refreshTask = Task { [weak self] in
            // Wait 40 minutes before first refresh (URLs valid ~60 min)
            let refreshInterval: TimeInterval = 2400 // 40 minutes

            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(refreshInterval))
                } catch {
                    // Task cancelled
                    break
                }

                guard !Task.isCancelled else { break }

                // Refresh all URLs for the video
                do {
                    try await self?.prefetchURLs(videoSlug: videoSlug)
                    logger.info("Background refresh completed for: \(videoSlug)")
                } catch {
                    logger.error("Background refresh failed: \(error.localizedDescription)")
                }
            }
        }

        logger.info("Started background refresh for video: \(videoSlug)")
    }

    // MARK: - Private Helpers

    private func cacheKey(videoSlug: String, relativePath: String) -> String {
        "\(videoSlug)/\(relativePath)"
    }
}
