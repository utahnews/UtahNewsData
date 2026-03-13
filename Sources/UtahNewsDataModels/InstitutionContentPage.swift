//
//  InstitutionContentPage.swift
//  UtahNewsDataModels
//
//  A discovered content page URL for a specific institution (e.g., the
//  calendar page on a school's website, or the press release page on a
//  police department's site).
//

import Foundation

/// A discovered content page on an institution's website.
///
/// Links an institution (e.g., "Lehi City Government") to a specific sub-page
/// (e.g., "https://lehi-ut.gov/meetings/") matched against an expected content
/// type (e.g., "council_agendas").
public struct InstitutionContentPage: Identifiable, Codable, Hashable, Sendable {
    /// Unique identifier (UUID)
    public let id: String
    /// Reference to city_institutions.id
    public let institutionId: String
    /// Reference to institution_content_types.id
    public let contentTypeId: String
    /// Discovered page URL
    public let url: String
    /// Page title or anchor text
    public let title: String?
    /// How the page was found
    public let matchMethod: MatchMethod
    /// Match confidence 0.00–1.00
    public let confidence: Double
    /// Lifecycle status
    public let status: Status
    /// FK to city_sources after promotion
    public let promotedSourceId: String?
    /// When the page was last crawled
    public let lastCrawledAt: Date?
    /// When the page was first discovered
    public let discoveredAt: Date?

    public enum MatchMethod: String, Codable, Hashable, Sendable, CaseIterable {
        case urlPattern = "url_pattern"
        case anchorText = "anchor_text"
        case both
        case manual
    }

    public enum Status: String, Codable, Hashable, Sendable, CaseIterable {
        case discovered
        case verified
        case promoted
        case invalid
        case stale
    }

    enum CodingKeys: String, CodingKey {
        case id, url, title, confidence, status
        case institutionId = "institution_id"
        case contentTypeId = "content_type_id"
        case matchMethod = "match_method"
        case promotedSourceId = "promoted_source_id"
        case lastCrawledAt = "last_crawled_at"
        case discoveredAt = "discovered_at"
    }

    public init(
        id: String = UUID().uuidString,
        institutionId: String,
        contentTypeId: String,
        url: String,
        title: String? = nil,
        matchMethod: MatchMethod = .urlPattern,
        confidence: Double = 0.50,
        status: Status = .discovered,
        promotedSourceId: String? = nil,
        lastCrawledAt: Date? = nil,
        discoveredAt: Date? = nil
    ) {
        self.id = id
        self.institutionId = institutionId
        self.contentTypeId = contentTypeId
        self.url = url
        self.title = title
        self.matchMethod = matchMethod
        self.confidence = confidence
        self.status = status
        self.promotedSourceId = promotedSourceId
        self.lastCrawledAt = lastCrawledAt
        self.discoveredAt = discoveredAt
    }
}
