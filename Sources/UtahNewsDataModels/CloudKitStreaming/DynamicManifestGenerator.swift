//
//  DynamicManifestGenerator.swift
//  UtahNewsData
//
//  Generates HLS manifests with current HTTPS download URLs at playback time.
//

import Foundation
import os

private let logger = Logger(subsystem: "com.utahnews.data", category: "DynamicManifestGenerator")

// MARK: - DynamicManifestGenerator

/// Transforms HLS manifests by replacing cloudkit:// URLs with HTTPS download URLs
public struct DynamicManifestGenerator: Sendable {

    /// URL cache for getting current download URLs
    private let urlCache: PlaybackURLCache

    public init(urlCache: PlaybackURLCache) {
        self.urlCache = urlCache
    }

    /// Generate manifest with current HTTPS URLs
    /// - Parameters:
    ///   - original: Original manifest content with cloudkit:// URLs
    ///   - videoSlug: Video identifier for URL lookup
    /// - Returns: Manifest with HTTPS download URLs
    public func generateManifest(original: String, videoSlug: String) async throws -> String {
        var lines = original.components(separatedBy: .newlines)
        var modifiedCount = 0

        logger.debug("Generating manifest for video: \(videoSlug), \(lines.count) lines")

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // Handle master manifest: variant playlist references
            // e.g., cloudkit://video-slug/720p/prog_index.m3u8
            if trimmed.hasPrefix("cloudkit://") && trimmed.hasSuffix(".m3u8") {
                if let httpsURL = await resolveURL(from: trimmed, videoSlug: videoSlug) {
                    lines[index] = httpsURL
                    modifiedCount += 1
                }
            }

            // Handle init segment: #EXT-X-MAP:URI="cloudkit://..."
            else if trimmed.hasPrefix("#EXT-X-MAP:URI=") {
                if let rewritten = await rewriteExtXMap(line: line, videoSlug: videoSlug) {
                    lines[index] = rewritten
                    modifiedCount += 1
                }
            }

            // Handle media segments: cloudkit://video-slug/path.m4s
            else if trimmed.hasPrefix("cloudkit://") &&
                    (trimmed.hasSuffix(".m4s") || trimmed.hasSuffix(".mp4") || trimmed.hasSuffix(".ts")) {
                if let httpsURL = await resolveURL(from: trimmed, videoSlug: videoSlug) {
                    lines[index] = httpsURL
                    modifiedCount += 1
                }
            }

            // Handle byte range URLs with cloudkit:// scheme
            else if trimmed.contains("cloudkit://") {
                // Check for URI= patterns in tags
                if let rewritten = await rewriteGenericURI(line: line, videoSlug: videoSlug) {
                    lines[index] = rewritten
                    modifiedCount += 1
                }
            }
        }

        let result = lines.joined(separator: "\n")

        logger.info("Generated manifest: \(modifiedCount) URLs rewritten")

        return result
    }

    // MARK: - Private Helpers

    /// Resolve cloudkit:// URL to HTTPS download URL
    private func resolveURL(from cloudkitURL: String, videoSlug: String) async -> String? {
        // Parse cloudkit://videoSlug/relativePath
        guard let relativePath = extractRelativePath(from: cloudkitURL, videoSlug: videoSlug) else {
            logger.warning("Failed to parse cloudkit URL: \(cloudkitURL)")
            return nil
        }

        // Check cache first
        if let cachedURL = await urlCache.getURL(for: relativePath, videoSlug: videoSlug) {
            return cachedURL.absoluteString
        }

        // Try to refresh this specific URL
        do {
            let freshURL = try await urlCache.refreshURL(for: relativePath, videoSlug: videoSlug)
            return freshURL.absoluteString
        } catch {
            logger.error("Failed to resolve URL for \(relativePath): \(error.localizedDescription)")
            // Fall back to original URL - AVPlayer will handle the error
            return nil
        }
    }

    /// Extract relative path from cloudkit:// URL
    private func extractRelativePath(from urlString: String, videoSlug: String) -> String? {
        // cloudkit://video-slug/some/path.m4s -> some/path.m4s
        let prefix = "cloudkit://\(videoSlug)/"

        guard urlString.hasPrefix(prefix) else {
            // Try to parse dynamically
            guard urlString.hasPrefix("cloudkit://") else { return nil }

            let withoutScheme = urlString.replacingOccurrences(of: "cloudkit://", with: "")
            guard let slashIndex = withoutScheme.firstIndex(of: "/") else { return nil }

            return String(withoutScheme[withoutScheme.index(after: slashIndex)...])
                .removingPercentEncoding
        }

        return String(urlString.dropFirst(prefix.count)).removingPercentEncoding
    }

    /// Rewrite #EXT-X-MAP:URI="cloudkit://..." tag
    private func rewriteExtXMap(line: String, videoSlug: String) async -> String? {
        // Extract the URI value
        guard let uriStart = line.range(of: "URI=\""),
              let uriEnd = line.range(of: "\"", range: uriStart.upperBound..<line.endIndex) else {
            return nil
        }

        let uriValue = String(line[uriStart.upperBound..<uriEnd.lowerBound])

        guard uriValue.hasPrefix("cloudkit://") else {
            return nil
        }

        // Resolve to HTTPS URL
        guard let httpsURL = await resolveURL(from: uriValue, videoSlug: videoSlug) else {
            return nil
        }

        // Rebuild the line with new URL
        let beforeURI = String(line[..<uriStart.upperBound])
        let afterURI = String(line[uriEnd.lowerBound...])

        return beforeURI + httpsURL + afterURI
    }

    /// Rewrite generic URI= pattern in any HLS tag
    private func rewriteGenericURI(line: String, videoSlug: String) async -> String? {
        var result = line
        var searchRange = line.startIndex..<line.endIndex

        // Find all URI="..." patterns
        while let uriStart = result.range(of: "URI=\"", range: searchRange),
              let uriEnd = result.range(of: "\"", range: uriStart.upperBound..<result.endIndex) {

            let uriValue = String(result[uriStart.upperBound..<uriEnd.lowerBound])

            if uriValue.hasPrefix("cloudkit://"),
               let httpsURL = await resolveURL(from: uriValue, videoSlug: videoSlug) {
                // Replace the URI value
                let replacement = "URI=\"" + httpsURL + "\""
                let fullRange = uriStart.lowerBound..<result.index(after: uriEnd.lowerBound)
                result.replaceSubrange(fullRange, with: replacement)
            }

            // Move search range past this occurrence
            if let newStart = result.range(of: "\"", range: uriEnd.lowerBound..<result.endIndex) {
                searchRange = newStart.upperBound..<result.endIndex
            } else {
                break
            }
        }

        return result != line ? result : nil
    }
}

// MARK: - Manifest Validation

extension DynamicManifestGenerator {

    /// Validate that manifest contains streaming-ready URLs
    public static func validateManifest(_ content: String) -> ManifestValidationResult {
        let lines = content.components(separatedBy: .newlines)

        var hasHTTPSURLs = false
        var hasCloudKitURLs = false
        var urlCount = 0

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.hasPrefix("https://") {
                hasHTTPSURLs = true
                urlCount += 1
            } else if trimmed.hasPrefix("cloudkit://") || trimmed.contains("cloudkit://") {
                hasCloudKitURLs = true
                urlCount += 1
            }
        }

        return ManifestValidationResult(
            hasHTTPSURLs: hasHTTPSURLs,
            hasCloudKitURLs: hasCloudKitURLs,
            totalURLs: urlCount,
            isStreamingReady: hasHTTPSURLs && !hasCloudKitURLs
        )
    }
}

/// Result of manifest validation
public struct ManifestValidationResult: Sendable {
    public let hasHTTPSURLs: Bool
    public let hasCloudKitURLs: Bool
    public let totalURLs: Int
    public let isStreamingReady: Bool

    public var description: String {
        if isStreamingReady {
            return "Ready for streaming (\(totalURLs) HTTPS URLs)"
        } else if hasCloudKitURLs && hasHTTPSURLs {
            return "Mixed URLs - partially converted"
        } else if hasCloudKitURLs {
            return "Not converted - contains \(totalURLs) cloudkit:// URLs"
        } else {
            return "No URLs found"
        }
    }
}
