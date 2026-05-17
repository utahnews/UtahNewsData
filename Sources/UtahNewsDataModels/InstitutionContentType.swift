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
    /// One-paragraph plain-English description of what data the extraction
    /// pipeline should expect to find on URLs of this kind (Sprint Z.3).
    /// Example: "Roster of city council members with name, district, term,
    /// email, phone, and possibly a photo. Typically lives at /council
    /// or /elected-officials."
    public let expectedDataDescription: String?
    /// Optional structured list of expected output fields, e.g.
    /// `["name", "position", "term_start", "term_end", "email"]`.
    /// Drives downstream extraction validation ("did we get all expected fields?")
    public let extractionSchema: ExtractionSchema?

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
        case expectedDataDescription = "expected_data_description"
        case extractionSchema = "extraction_schema"
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
        priority: Int = 2,
        expectedDataDescription: String? = nil,
        extractionSchema: ExtractionSchema? = nil
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
        self.expectedDataDescription = expectedDataDescription
        self.extractionSchema = extractionSchema
    }
}

/// Optional structured shape describing the fields we expect to extract
/// from URLs of a given (institution_type, content_type) pair. Stored as
/// jsonb in `institution_content_types.extraction_schema`. Only the
/// `fields` key is used today; the struct is extensible if we add more.
public struct ExtractionSchema: Codable, Hashable, Sendable {
    /// List of expected output field names per item (snake_case),
    /// e.g. `["name", "position", "term_start", "email"]`.
    public let fields: [String]?

    public init(fields: [String]? = nil) {
        self.fields = fields
    }
}
