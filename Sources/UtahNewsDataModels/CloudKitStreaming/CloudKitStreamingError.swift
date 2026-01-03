//
//  CloudKitStreamingError.swift
//  UtahNewsData
//
//  Error types for CloudKit HLS streaming operations.
//

import Foundation

// MARK: - CloudKitHLSError

/// Errors that can occur during CloudKit HLS streaming
public enum CloudKitHLSError: LocalizedError, Sendable {
    case invalidURL(String)
    case segmentNotFound(String)
    case assetNotFound
    case downloadFailed(String)
    case manifestGenerationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid cloudkit:// URL: \(url)"
        case .segmentNotFound(let path):
            return "Segment not found in CloudKit: \(path)"
        case .assetNotFound:
            return "CKAsset not found in record"
        case .downloadFailed(let message):
            return "Failed to download segment: \(message)"
        case .manifestGenerationFailed(let message):
            return "Failed to generate manifest: \(message)"
        }
    }
}

// MARK: - PlaybackURLCacheError

/// Errors that can occur during URL caching operations
public enum PlaybackURLCacheError: LocalizedError, Sendable {
    case urlNotFound(String)
    case refreshFailed(String)

    public var errorDescription: String? {
        switch self {
        case .urlNotFound(let path):
            return "URL not found for path: \(path)"
        case .refreshFailed(let message):
            return "Failed to refresh URL: \(message)"
        }
    }
}

// MARK: - CloudKitWebServiceError

/// Errors that can occur when fetching download URLs from CloudKit Web Services
public enum CloudKitWebServiceError: LocalizedError, Sendable {
    case apiTokenMissing
    case invalidResponse
    case recordNotFound(String)
    case networkError(String)
    case decodingError(String)

    public var errorDescription: String? {
        switch self {
        case .apiTokenMissing:
            return "CloudKit API token is not configured"
        case .invalidResponse:
            return "Invalid response from CloudKit Web Services"
        case .recordNotFound(let name):
            return "Record not found: \(name)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        }
    }
}
