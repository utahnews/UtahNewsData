//
//  CloudKitWebService.swift
//  UtahNewsData
//
//  Fetches download URLs from CloudKit Web Services API for true HTTPS streaming.
//  Uses HTTP-based Web Services API exclusively (no native CKContainer SDK).
//

import Foundation
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
/// Uses HTTP-based Web Services API exclusively (no native CKContainer SDK)
public actor CloudKitWebService {
    // CloudKit Web Services endpoints
    private let baseURL = "https://api.apple-cloudkit.com/database/1"
    private let containerID: String
    private let environment: String

    // API token for client access (configured in CloudKit Dashboard)
    private var apiToken: String?

    // Configured URLSession for reliable streaming on all network types
    private let session: URLSession

    public init(containerID: String = CloudKitStreamingConfig.containerID) {
        self.containerID = containerID

        // Always use production for the public database via Web Services API.
        // Read-only API token access works across environments.
        // Videos uploaded from the UtahNewsUploader (via native CKContainer SDK)
        // go to the production public database regardless of build config.
        self.environment = "production"

        // Configure URLSession to work reliably on cellular/constrained networks
        let config = URLSessionConfiguration.default
        config.allowsConstrainedNetworkAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)

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
            throw CloudKitWebServiceError.networkError("API token not configured")
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

        // Build request with API token as query parameter (per Apple CloudKit Web Services docs)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "ckAPIToken", value: apiToken)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        logger.debug("Fetching download URLs for \(recordNames.count) records")

        // Execute request
        let (data, response) = try await session.data(for: request)

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

    /// Fetch download URLs for all segments of a video using Web Services API
    /// - Parameters:
    ///   - videoSlug: The video's slug identifier
    ///   - segmentPaths: Optional specific paths to fetch (fetches all if nil)
    /// - Returns: Dictionary mapping relative paths to download URLs
    ///
    /// Note: Uses Web Services /query endpoint with cursor-based pagination
    public func fetchDownloadURLsForVideo(
        videoSlug: String,
        segmentPaths: [String]? = nil
    ) async throws -> [String: URL] {
        guard let apiToken = apiToken else {
            throw CloudKitWebServiceError.networkError("API token not configured")
        }

        // Build the query URL
        let endpoint = "\(baseURL)/\(containerID)/\(environment)/public/records/query"

        guard let url = URL(string: endpoint) else {
            throw CloudKitWebServiceError.invalidResponse
        }

        logger.info("Querying VideoSegment records via Web Services for video: \(videoSlug)")

        // Build query filter
        var filters: [[String: Any]] = [
            [
                "fieldName": "videoSlug",
                "comparator": "EQUALS",
                "fieldValue": ["value": videoSlug]
            ]
        ]

        // Add path filter if specific paths requested
        if let paths = segmentPaths, !paths.isEmpty {
            filters.append([
                "fieldName": "relativePath",
                "comparator": "IN",
                "fieldValue": ["value": paths]
            ])
        }

        var allRecordToPath: [String: String] = [:]
        var continuationMarker: String? = nil

        // Paginate through all results
        repeat {
            var requestBody: [String: Any] = [
                "query": [
                    "recordType": "VideoSegment",
                    "filterBy": filters
                ],
                "desiredKeys": ["relativePath", "segmentFile"],
                "resultsLimit": 200
            ]

            if let marker = continuationMarker {
                requestBody["continuationMarker"] = marker
            }

            guard let bodyData = try? JSONSerialization.data(withJSONObject: requestBody) else {
                throw CloudKitWebServiceError.decodingError("Failed to encode query request")
            }

            // Build request with API token as query parameter (per Apple CloudKit Web Services docs)
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            components.queryItems = [URLQueryItem(name: "ckAPIToken", value: apiToken)]

            var request = URLRequest(url: components.url!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = bodyData

            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw CloudKitWebServiceError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                logger.error("CloudKit query error: \(httpResponse.statusCode) - \(errorBody)")
                throw CloudKitWebServiceError.networkError("HTTP \(httpResponse.statusCode): \(errorBody)")
            }

            // Parse response
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let records = json?["records"] as? [[String: Any]] ?? []

            for record in records {
                guard let recordName = record["recordName"] as? String,
                      let fields = record["fields"] as? [String: Any],
                      let relativePathField = fields["relativePath"] as? [String: Any],
                      let relativePath = relativePathField["value"] as? String else {
                    continue
                }

                // Extract download URL directly from segmentFile field
                if let segmentFileField = fields["segmentFile"] as? [String: Any],
                   let assetValue = segmentFileField["value"] as? [String: Any],
                   let downloadURLString = assetValue["downloadURL"] as? String,
                   let downloadURL = URL(string: downloadURLString) {
                    // Store directly with path -> URL mapping
                    allRecordToPath[relativePath] = downloadURLString
                } else {
                    // Store recordName for later lookup if no download URL in response
                    allRecordToPath[recordName] = relativePath
                }
            }

            continuationMarker = json?["continuationMarker"] as? String
            logger.debug("Fetched batch: \(records.count) records, continuation: \(continuationMarker != nil)")

        } while continuationMarker != nil

        logger.info("Found \(allRecordToPath.count) total segment records via Web Services")

        guard !allRecordToPath.isEmpty else {
            return [:]
        }

        // Check if we already have download URLs (from query response)
        var pathURLs: [String: URL] = [:]
        var recordNamesToLookup: [String: String] = [:] // recordName -> relativePath

        for (key, value) in allRecordToPath {
            if key.hasPrefix("http") || key.contains("://") {
                // key is relativePath, value is URL string (unlikely based on our storage)
                continue
            } else if value.hasPrefix("http") || value.contains("://") {
                // key is relativePath, value is download URL
                if let url = URL(string: value) {
                    pathURLs[key] = url
                }
            } else {
                // key is recordName, value is relativePath - need lookup
                recordNamesToLookup[key] = value
            }
        }

        // If we need to look up download URLs separately
        if !recordNamesToLookup.isEmpty {
            let recordNames = Array(recordNamesToLookup.keys)
            let recordURLs = try await fetchDownloadURLs(recordNames: recordNames)

            for (recordName, url) in recordURLs {
                if let relativePath = recordNamesToLookup[recordName] {
                    pathURLs[relativePath] = url
                }
            }
        }

        return pathURLs
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
