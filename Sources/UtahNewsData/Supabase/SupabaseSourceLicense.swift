//
//  SupabaseSourceLicense.swift
//  UtahNewsData
//
//  Source domain license and fair-use metadata for citation tracking.
//  Maps to the `pipeline.source_licenses` table.
//

import Foundation

/// License and fair-use metadata for a news source domain.
nonisolated public struct SupabaseSourceLicense: Codable, Sendable, Identifiable {
    public let id: String
    public let sourceDomain: String
    public var licenseType: String
    public var allowsSyndication: Bool
    public var requiresAttribution: Bool
    public var maxQuoteWords: Int?
    public var robotsTxtStatus: String?
    public var lastCheckedAt: Date?
    public var notes: String?
    public let createdAt: Date
    public var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, notes
        case sourceDomain = "source_domain"
        case licenseType = "license_type"
        case allowsSyndication = "allows_syndication"
        case requiresAttribution = "requires_attribution"
        case maxQuoteWords = "max_quote_words"
        case robotsTxtStatus = "robots_txt_status"
        case lastCheckedAt = "last_checked_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
