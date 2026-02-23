//
//  SupabaseProcessedItem.swift
//  UtahNewsData
//
//  Typed model for the `processed_items` Supabase table.
//  Matches the schema in SUPABASE_SCHEMA.sql.
//
//  Previously defined independently in V2PipelineTester, NewsCapture, and UtahNews.
//

import Foundation

// MARK: - Processed Item (Read Model)

/// A row from the `processed_items` table in Supabase.
///
/// This is the V2 pipeline output containing fully analyzed content:
/// extracted text, entity analysis, sentiment, Utah relevance, and editorial signals.
nonisolated public struct SupabaseProcessedItem: Codable, Sendable, Identifiable, Hashable {

    // MARK: - Identity

    /// Unique identifier (UUID string or auto-generated)
    public let id: String

    /// The processed URL
    public let url: String

    // MARK: - Source Information

    /// Title of the source publication
    public let sourceTitle: String

    /// Content author (if detected)
    public let author: String?

    /// Original publish date (ISO 8601 string)
    public let publishDate: String?

    // MARK: - Content

    /// Cleaned/extracted text content from WebPage API
    public let cleanedText: String

    /// AI-generated summary
    public let summary: String

    /// Excerpt analyzed by FoundationModels
    public let fmExcerpt: String?

    // MARK: - Analysis (FoundationModels Output)

    /// JSON-encoded entity array: [{"text":"...","type":"person|organization|place"}]
    public let entitiesJson: String

    /// Extracted topic labels
    public let topics: [String]

    /// Sentiment classification: positive, negative, neutral
    public let sentimentLabel: String

    /// Sentiment score (-1.0 to 1.0)
    public let sentimentScore: Double

    /// Detected language code
    public let language: String

    // MARK: - Utah Relevance

    /// Whether this content is relevant to Utah
    public let isRelevantToUtah: Bool

    /// Utah relevance score (0.0 to 1.0)
    public let relevanceScore: Double

    /// Utah locations mentioned in the content
    public let utahLocations: [String]

    /// How relevance was determined: city_source_match, gov_domain_match, keyword_match
    public let relevanceMethod: String?

    // MARK: - Source Promotion

    /// Whether this URL is a candidate for source promotion
    public let promotionCandidate: Bool

    /// Whether this URL has been promoted to a source
    public let promotedToSource: Bool

    /// Associated source ID (if matched)
    public let sourceId: String?

    // MARK: - Classification

    /// Content type classification
    public let identifiedContentType: String

    /// Per-field confidence scores (JSONB)
    public let confidenceScores: [String: Double]?

    /// Page role: discovery_page, article_page, sitemap, etc.
    public let pageRole: String?

    /// Discovery scope: utah_wide, city_specific, regional
    public let discoveryScope: String?

    /// Classification confidence (0.0 to 1.0)
    public let classificationConfidence: Double?

    /// Assigned scan frequency for the source
    public let assignedScanFrequency: String?

    /// Number of URLs extracted from this page
    public let extractedUrlCount: Int?

    /// Extracted keywords
    public let keywords: [String]?

    // MARK: - Metadata

    /// When this item was processed (ISO 8601 string)
    public let processingTimestamp: String

    /// City name for geographic assignment
    public let cityName: String?

    /// Source domain extracted from URL
    public let sourceDomain: String?

    // MARK: - Enrichment Pipeline

    /// Current processing stage: scraped, enriching, enriched, generated
    public let processingStage: String?

    /// Which V2 instance enriched this item
    public let enrichedBy: String?

    /// When enrichment completed (ISO 8601 string)
    public let enrichedAt: String?

    // MARK: - Editorial & Structured Data (JSONB)

    /// Editorial signals for NewsCapture consumption
    public let editorialSignals: SupabaseAnyCodable?

    /// Extracted structured data (OpenGraph, JSON-LD, Twitter Card)
    public let structuredData: SupabaseAnyCodable?

    // MARK: - Public Init

    public init(
        id: String,
        url: String,
        sourceTitle: String,
        author: String?,
        publishDate: String?,
        cleanedText: String,
        summary: String,
        fmExcerpt: String?,
        entitiesJson: String,
        topics: [String],
        sentimentLabel: String,
        sentimentScore: Double,
        language: String,
        isRelevantToUtah: Bool,
        relevanceScore: Double,
        utahLocations: [String],
        relevanceMethod: String?,
        promotionCandidate: Bool,
        promotedToSource: Bool,
        sourceId: String?,
        identifiedContentType: String,
        confidenceScores: [String: Double]?,
        pageRole: String?,
        discoveryScope: String?,
        classificationConfidence: Double?,
        assignedScanFrequency: String?,
        extractedUrlCount: Int?,
        keywords: [String]?,
        processingTimestamp: String,
        cityName: String?,
        sourceDomain: String?,
        processingStage: String? = nil,
        enrichedBy: String? = nil,
        enrichedAt: String? = nil,
        editorialSignals: SupabaseAnyCodable?,
        structuredData: SupabaseAnyCodable?
    ) {
        self.id = id
        self.url = url
        self.sourceTitle = sourceTitle
        self.author = author
        self.publishDate = publishDate
        self.cleanedText = cleanedText
        self.summary = summary
        self.fmExcerpt = fmExcerpt
        self.entitiesJson = entitiesJson
        self.topics = topics
        self.sentimentLabel = sentimentLabel
        self.sentimentScore = sentimentScore
        self.language = language
        self.isRelevantToUtah = isRelevantToUtah
        self.relevanceScore = relevanceScore
        self.utahLocations = utahLocations
        self.relevanceMethod = relevanceMethod
        self.promotionCandidate = promotionCandidate
        self.promotedToSource = promotedToSource
        self.sourceId = sourceId
        self.identifiedContentType = identifiedContentType
        self.confidenceScores = confidenceScores
        self.pageRole = pageRole
        self.discoveryScope = discoveryScope
        self.classificationConfidence = classificationConfidence
        self.assignedScanFrequency = assignedScanFrequency
        self.extractedUrlCount = extractedUrlCount
        self.keywords = keywords
        self.processingTimestamp = processingTimestamp
        self.cityName = cityName
        self.sourceDomain = sourceDomain
        self.processingStage = processingStage
        self.enrichedBy = enrichedBy
        self.enrichedAt = enrichedAt
        self.editorialSignals = editorialSignals
        self.structuredData = structuredData
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id, url, summary, author, language, topics, keywords
        case sourceTitle = "source_title"
        case publishDate = "publish_date"
        case cleanedText = "cleaned_text"
        case fmExcerpt = "fm_excerpt"
        case entitiesJson = "entities_json"
        case sentimentLabel = "sentiment_label"
        case sentimentScore = "sentiment_score"
        case isRelevantToUtah = "is_relevant_to_utah"
        case relevanceScore = "relevance_score"
        case utahLocations = "utah_locations"
        case relevanceMethod = "relevance_method"
        case promotionCandidate = "promotion_candidate"
        case promotedToSource = "promoted_to_source"
        case sourceId = "source_id"
        case identifiedContentType = "identified_content_type"
        case confidenceScores = "confidence_scores"
        case pageRole = "page_role"
        case discoveryScope = "discovery_scope"
        case classificationConfidence = "classification_confidence"
        case assignedScanFrequency = "assigned_scan_frequency"
        case extractedUrlCount = "extracted_url_count"
        case processingTimestamp = "processing_timestamp"
        case cityName = "city_name"
        case sourceDomain = "source_domain"
        case processingStage = "processing_stage"
        case enrichedBy = "enriched_by"
        case enrichedAt = "enriched_at"
        case editorialSignals = "editorial_signals"
        case structuredData = "structured_data"
    }
}

// MARK: - Computed Properties

extension SupabaseProcessedItem {

    /// Domain extracted from the URL
    public var domain: String {
        guard let urlObj = URL(string: url), let host = urlObj.host else { return url }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    /// Display title (source title or domain fallback)
    public var displayTitle: String {
        sourceTitle.isEmpty ? domain : sourceTitle
    }

    /// Processing timestamp as Date
    public var processingDate: Date? {
        ISO8601DateFormatter().date(from: processingTimestamp)
    }

    /// Whether this item has been enriched by V2 with FM analysis
    public var isEnriched: Bool {
        processingStage == "enriched"
    }

    // MARK: - Hashable (identity-based)

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: SupabaseProcessedItem, rhs: SupabaseProcessedItem) -> Bool {
        lhs.id == rhs.id
    }
}
