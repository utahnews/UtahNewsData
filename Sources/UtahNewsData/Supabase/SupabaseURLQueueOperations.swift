//
//  SupabaseURLQueueOperations.swift
//  UtahNewsData
//
//  Shared URL queue operations protocol with default implementations.
//  Eliminates duplication across V2PipelineTester, URLCapture, and UtahNews.
//
//  Each app's SupabaseService conforms to URLQueueOperations to inherit
//  shared queue logic while keeping app-specific methods separate.
//

import Foundation
import Supabase

// MARK: - Protocol

/// Shared URL queue operations for submitting and checking URLs.
///
/// Conforming types must provide a `supabaseClient` property.
/// Default implementations handle URL submission, deduplication, and batch operations.
///
/// **Usage:**
/// ```swift
/// actor MySupabaseService: URLQueueOperations {
///     let supabaseClient: SupabaseClient
///     init() { supabaseClient = SupabaseClientFactory.makeClient() }
/// }
///
/// // Now has: addURLToQueue(), checkAlreadyQueued(), batchAddURLs()
/// ```
public protocol URLQueueOperations: Sendable {
    /// The Supabase client to use for all operations
    var supabaseClient: SupabaseClient { get }
}

// MARK: - Default Implementations

extension URLQueueOperations {

    /// Add a single URL to the processing queue.
    ///
    /// Uses upsert with SHA-1 hash as ID, so duplicate URLs are silently ignored.
    ///
    /// - Parameters:
    ///   - url: The URL string to add
    ///   - discoveredFrom: Source of the URL (e.g., "urlcapture-safari-extension")
    ///   - processingMode: How to process: "first_time", "refresh", "list_item", "feed_item"
    ///   - submissionContext: Optional metadata dictionary
    ///   - cityHint: Optional city name for geographic routing
    /// - Returns: The document ID (SHA-1 hash of URL)
    public func addURLToQueue(
        url: String,
        discoveredFrom: String? = nil,
        processingMode: String? = nil,
        submissionContext: [String: String]? = nil,
        cityHint: String? = nil
    ) async throws -> String {
        let urlHash = url.sha1Hash()

        let insert = SupabaseURLQueueInsert(
            id: urlHash,
            url: url,
            status: "pending",
            discoveredFrom: discoveredFrom,
            processingMode: processingMode,
            submissionContext: submissionContext,
            cityName: cityHint
        )

        try await supabaseClient
            .schema(SupabaseConfig.schema)
            .from("url_queue")
            .upsert(insert, onConflict: "id")
            .execute()

        return urlHash
    }

    /// Check which URLs from a list already exist in the queue.
    ///
    /// Processes in batches of 100 (Supabase IN query limit).
    ///
    /// - Parameter urls: Array of URL strings to check
    /// - Returns: Set of URLs that already exist in the queue
    public func checkAlreadyQueued(urls: [String]) async throws -> Set<String> {
        var alreadyQueued = Set<String>()

        let batches = urls.chunked(into: 100)

        for batch in batches {
            let hashes = batch.map { $0.sha1Hash() }

            let response = try await supabaseClient
                .schema(SupabaseConfig.schema)
                .from("url_queue")
                .select("url")
                .in("id", values: hashes)
                .execute()

            let rows = try JSONDecoder().decode([URLRow].self, from: response.data)
            for row in rows {
                alreadyQueued.insert(row.url)
            }
        }

        return alreadyQueued
    }

    /// Batch insert URLs to the queue, skipping duplicates.
    ///
    /// Checks for existing URLs first, then inserts new ones in batches of 500.
    ///
    /// - Parameters:
    ///   - urls: Array of URL strings
    ///   - discoveredFrom: Source identifier
    ///   - processingMode: Processing mode for all URLs
    ///   - submissionContext: Optional context for all URLs
    /// - Returns: Number of URLs actually added (excluding duplicates)
    public func batchAddURLs(
        _ urls: [String],
        discoveredFrom: String,
        processingMode: String? = nil,
        submissionContext: [String: String]? = nil
    ) async throws -> Int {
        guard !urls.isEmpty else { return 0 }

        // Check which already exist
        let existing = try await checkAlreadyQueued(urls: urls)
        let newURLs = urls.filter { !existing.contains($0) }

        guard !newURLs.isEmpty else { return 0 }

        // Build insert rows
        let rows = newURLs.map { url in
            SupabaseURLQueueInsert(
                id: url.sha1Hash(),
                url: url,
                status: "pending",
                discoveredFrom: discoveredFrom,
                processingMode: processingMode,
                submissionContext: submissionContext
            )
        }

        // Insert in batches of 500
        var addedCount = 0
        let insertBatches = rows.chunked(into: 500)

        for batch in insertBatches {
            try await supabaseClient
                .schema(SupabaseConfig.schema)
                .from("url_queue")
                .upsert(batch, onConflict: "id")
                .execute()

            addedCount += batch.count
        }

        return addedCount
    }

    /// Check if a single URL exists in the queue.
    ///
    /// - Parameter url: The URL to check
    /// - Returns: True if URL exists in the queue
    public func urlExistsInQueue(_ url: String) async throws -> Bool {
        let urlHash = url.sha1Hash()

        let response = try await supabaseClient
            .schema(SupabaseConfig.schema)
            .from("url_queue")
            .select("id", head: true, count: .exact)
            .eq("id", value: urlHash)
            .execute()

        return (response.count ?? 0) > 0
    }

    /// Get the current status of a URL in the queue.
    ///
    /// - Parameter url: The URL to check
    /// - Returns: Status string or nil if not found
    public func getQueueItemStatus(for url: String) async throws -> String? {
        let urlHash = url.sha1Hash()

        let response = try await supabaseClient
            .schema(SupabaseConfig.schema)
            .from("url_queue")
            .select("status")
            .eq("id", value: urlHash)
            .limit(1)
            .execute()

        let rows = try JSONDecoder().decode([StatusRow].self, from: response.data)
        return rows.first?.status
    }
}

// MARK: - Internal Helpers

/// Minimal row for URL existence checks
private struct URLRow: Codable {
    let url: String
}

/// Minimal row for status checks
private struct StatusRow: Codable {
    let status: String
}

// MARK: - Array Extension (shared chunking utility)

extension Array {
    /// Split array into chunks of a given size.
    ///
    /// Used by batch queue operations for Supabase query limits.
    public func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
