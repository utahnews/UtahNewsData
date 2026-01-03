//
//  CloudKitWebService.swift
//  UtahNewsData
//
//  Fetches download URLs from CloudKit Web Services API for true HTTPS streaming.
//

import Foundation
import CloudKit
import os

private let logger = Logger(subsystem: "com.utahnews.data", category: "CloudKitWebService")

// MARK: - Response Types

/// CloudKit Web Services record lookup response
public struct CKWSRecordLookupResponse: Decodable, Sendable {
    public let records: [CKWSRecord]?
}

public struct CKWSRecord: Decodable, Sendable {
    public let recordName: String?
    public let recordType: String?
    public let fields: [String: CKWSField]?
}

public struct CKWSField: Decodable, Sendable {
    public let value: CKWSAssetValue?
    public let type: String?

    private enum CodingKeys: String, CodingKey {
        case value
        case type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decodeIfPresent(String.self, forKey: .type)

        // value can be a nested object (for assets) or a simple value
        if let assetValue = try? container.decode(CKWSAssetValue.self, forKey: .value) {
            value = assetValue
        } else {
            value = nil
        }
    }
}

public struct CKWSAssetValue: Decodable, Sendable {
    public let downloadURL: String?
    public let fileChecksum: String?
    public let size: Int?
}

// MARK: - CloudKitWebService

/// Service for fetching download URLs from CloudKit Web Services API
public actor CloudKitWebService {
    // CloudKit Web Services endpoints
    private let baseURL = "https://api.apple-cloudkit.com/database/1"
    private let containerID: String
    private let environment: String

    // API token for client access (configured in CloudKit Dashboard)
    private var apiToken: String?

    // Native CloudKit for fallback and token retrieval
    private let container: CKContainer
    private let publicDB: CKDatabase

    public init(containerID: String = CloudKitStreamingConfig.containerID) {
        self.containerID = containerID
        self.container = CKContainer(identifier: containerID)
        self.publicDB = container.publicCloudDatabase

        // Use production environment for release, development for debug
        #if DEBUG
        self.environment = "development"
        #else
        self.environment = "production"
        #endif

        logger.info("CloudKitWebService initialized for \(self.environment) environment")
    }

    /// Configure API token (from CloudKit Dashboard)
    public func configure(apiToken: String) {
        self.apiToken = apiToken
        logger.info("API token configured")
    }

    /// Fetch download URLs for multiple VideoSegment records
    /// - Parameter recordNames: CloudKit record names to fetch
    /// - Returns: Dictionary mapping record names to download URLs
    public func fetchDownloadURLs(recordNames: [String]) async throws -> [String: URL] {
        guard let apiToken = apiToken else {
            logger.warning("API token not configured, falling back to native SDK")
            return try await fetchDownloadURLsViaNativeSDK(recordNames: recordNames)
        }

        // Build the API URL
        let endpoint = "\(baseURL)/\(containerID)/\(environment)/public/records/lookup"

        guard let url = URL(string: endpoint) else {
            throw CloudKitWebServiceError.invalidResponse
        }

        // Build request body
        let requestBody: [String: Any] = [
            "records": recordNames.map { ["recordName": $0] },
            "desiredKeys": ["segmentFile", "relativePath", "videoSlug"]
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw CloudKitWebServiceError.decodingError("Failed to encode request")
        }

        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiToken, forHTTPHeaderField: "X-Apple-CloudKit-Request-APIToken")
        request.httpBody = bodyData

        logger.debug("Fetching download URLs for \(recordNames.count) records")

        // Execute request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudKitWebServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            logger.error("CloudKit Web Services error: \(httpResponse.statusCode) - \(errorBody)")
            throw CloudKitWebServiceError.networkError("HTTP \(httpResponse.statusCode): \(errorBody)")
        }

        // Parse response
        let decoder = JSONDecoder()
        let lookupResponse = try decoder.decode(CKWSRecordLookupResponse.self, from: data)

        var urlMap: [String: URL] = [:]

        for record in lookupResponse.records ?? [] {
            guard let recordName = record.recordName,
                  let fields = record.fields,
                  let segmentField = fields["segmentFile"],
                  let assetValue = segmentField.value,
                  let downloadURLString = assetValue.downloadURL,
                  let downloadURL = URL(string: downloadURLString) else {
                continue
            }

            urlMap[recordName] = downloadURL
            logger.debug("Got download URL for \(recordName)")
        }

        logger.info("Fetched \(urlMap.count) download URLs")
        return urlMap
    }

    /// Fetch download URLs for all segments of a video
    /// - Parameters:
    ///   - videoSlug: The video's slug identifier
    ///   - segmentPaths: Optional specific paths to fetch (fetches all if nil)
    /// - Returns: Dictionary mapping relative paths to download URLs
    ///
    /// Note: Uses cursor-based pagination to fetch ALL segments (CloudKit limits to ~100 per query)
    public func fetchDownloadURLsForVideo(
        videoSlug: String,
        segmentPaths: [String]? = nil
    ) async throws -> [String: URL] {
        // First, query for segment record IDs with pagination
        let predicate: NSPredicate
        if let paths = segmentPaths, !paths.isEmpty {
            predicate = NSPredicate(
                format: "videoSlug == %@ AND relativePath IN %@",
                videoSlug, paths
            )
        } else {
            predicate = NSPredicate(format: "videoSlug == %@", videoSlug)
        }

        let query = CKQuery(recordType: "VideoSegment", predicate: predicate)

        logger.info("Querying VideoSegment records for video: \(videoSlug) (with pagination)")

        // Use pagination to fetch ALL segment records
        var allRecordToPath: [String: String] = [:]

        // First query with cursor support
        let (firstMatchResults, firstCursor) = try await publicDB.records(
            matching: query,
            desiredKeys: ["relativePath"],
            resultsLimit: CKQueryOperation.maximumResults
        )

        // Process first batch
        for (recordID, result) in firstMatchResults {
            if case .success(let record) = result,
               let relativePath = record["relativePath"] as? String {
                allRecordToPath[recordID.recordName] = relativePath
            }
        }

        logger.debug("First batch: \(firstMatchResults.count) records")

        // Continue with cursor until no more results
        var cursor = firstCursor
        var batchNumber = 1

        while let currentCursor = cursor {
            batchNumber += 1
            let (moreMatchResults, nextCursor) = try await publicDB.records(
                continuingMatchFrom: currentCursor,
                desiredKeys: ["relativePath"],
                resultsLimit: CKQueryOperation.maximumResults
            )

            for (recordID, result) in moreMatchResults {
                if case .success(let record) = result,
                   let relativePath = record["relativePath"] as? String {
                    allRecordToPath[recordID.recordName] = relativePath
                }
            }

            logger.debug("Batch \(batchNumber): \(moreMatchResults.count) records")
            cursor = nextCursor
        }

        logger.info("Found \(allRecordToPath.count) total segment records (pagination complete)")

        guard !allRecordToPath.isEmpty else {
            return [:]
        }

        // Fetch download URLs for all records
        let recordNames = Array(allRecordToPath.keys)
        let recordURLs = try await fetchDownloadURLs(recordNames: recordNames)

        // Map back to relative paths
        var pathURLs: [String: URL] = [:]
        for (recordName, url) in recordURLs {
            if let relativePath = allRecordToPath[recordName] {
                pathURLs[relativePath] = url
            }
        }

        return pathURLs
    }

    // MARK: - Native SDK Fallback

    /// Fallback method using native CloudKit SDK
    /// Note: This downloads the assets to get URLs, which is less efficient
    private func fetchDownloadURLsViaNativeSDK(recordNames: [String]) async throws -> [String: URL] {
        logger.debug("Using native SDK fallback for \(recordNames.count) records")

        var urlMap: [String: URL] = [:]

        for recordName in recordNames {
            let recordID = CKRecord.ID(recordName: recordName)

            do {
                let record = try await publicDB.record(for: recordID)

                // CKAsset only provides local fileURL, not streaming URL
                // This triggers a download, which defeats the purpose of streaming
                if let asset = record["segmentFile"] as? CKAsset,
                   let fileURL = asset.fileURL {
                    urlMap[recordName] = fileURL
                }
            } catch {
                logger.warning("Failed to fetch record \(recordName): \(error.localizedDescription)")
            }
        }

        return urlMap
    }
}

// MARK: - API Token Configuration

extension CloudKitWebService {
    /// Instructions for configuring the API token
    public static var tokenConfigurationGuide: String {
        """
        To enable true HTTPS streaming, configure a CloudKit API token:

        1. Go to https://icloud.developer.apple.com
        2. Select your container: iCloud.com.appLaunchers.UtahNews
        3. Go to "API Access" section
        4. Create a new API token with:
           - Token Name: "UtahNews-Streaming"
           - Permissions: Read (for public database)
        5. Copy the token and configure it:

           await cloudKitWebService.configure(apiToken: "your-token-here")

        Note: The API token is NOT a secret. It identifies your app
        but doesn't grant write access without proper authentication.
        """
    }
}
