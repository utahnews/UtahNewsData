//
//  InstitutionContentType.swift
//  UtahNewsDataModels
//
//  Defines what content pages to look for on each institution type's website
//  (e.g., city government → council agendas, public notices, press releases).
//

import Foundation

/// A content page type expected for a given institution type.
///
/// Each record maps an institution type (e.g., "city_government") to a content
/// category (e.g., "council_agendas") with URL and anchor patterns used to
/// discover the actual page on the institution's website.
public struct InstitutionContentType: Identifiable, Codable, Hashable, Sendable {
    /// Composite key: "institution_type_id__content_type"
    public let id: String
    /// Reference to institution_types.id
    public let institutionTypeId: String
    /// Machine-readable content type (e.g., "council_agendas")
    public let contentType: String
    /// Human-readable name (e.g., "City Council Agendas")
    public let displayName: String
    /// URL path fragments to match (e.g., ["/agenda", "/meetings"])
    public let urlPatterns: [String]
    /// Link text patterns to match (e.g., ["agenda", "council meeting"])
    public let anchorPatterns: [String]
    /// Patterns that disqualify a match (e.g., ["login", "archive/2019"])
    public let negativePatterns: [String]
    /// How often to re-scan: hourly, daily, weekly, monthly
    public let scanFrequency: String
    /// 1=critical, 2=important, 3=nice-to-have
    public let priority: Int

    enum CodingKeys: String, CodingKey {
        case id
        case institutionTypeId = "institution_type_id"
        case contentType = "content_type"
        case displayName = "display_name"
        case urlPatterns = "url_patterns"
        case anchorPatterns = "anchor_patterns"
        case negativePatterns = "negative_patterns"
        case scanFrequency = "scan_frequency"
        case priority
    }

    public init(
        id: String,
        institutionTypeId: String,
        contentType: String,
        displayName: String,
        urlPatterns: [String] = [],
        anchorPatterns: [String] = [],
        negativePatterns: [String] = [],
        scanFrequency: String = "weekly",
        priority: Int = 2
    ) {
        self.id = id
        self.institutionTypeId = institutionTypeId
        self.contentType = contentType
        self.displayName = displayName
        self.urlPatterns = urlPatterns
        self.anchorPatterns = anchorPatterns
        self.negativePatterns = negativePatterns
        self.scanFrequency = scanFrequency
        self.priority = priority
    }
}
