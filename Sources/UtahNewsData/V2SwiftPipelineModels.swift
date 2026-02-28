//
//  V2SwiftPipelineModels.swift
//  UtahNewsData
//
//  Swift-Native V2 Pipeline Data Models
//  Used by V2PipelineTester, UtahNews, NewsCapture for processed_items_v2 collection
//
//  These models represent the Swift-native 3-agent pipeline (not the Python V2 agent pipeline)
//  Collection: processed_items_v2
//

import Foundation
@preconcurrency import FirebaseFirestore

// MARK: - Type-Safe Enums

/// Relevance detection method (replaces magic strings)
/// LEGACY: rawValues use snake_case from retired Python pipeline - DO NOT CHANGE
public enum RelevanceMethod: String, Codable, Sendable {
    case citySourceMatch = "city_source_match"  // LEGACY snake_case
    case govDomainMatch = "gov_domain_match"    // LEGACY snake_case
    case keywordMatch = "keyword_match"         // LEGACY snake_case
}

/// Sentiment classification (replaces magic strings)
public enum SentimentLabel: String, Codable, Sendable {
    case positive
    case negative
    case neutral
}

/// Content type classification (replaces magic strings)
/// Expanded for data intelligence pipeline to handle government/civic page types
public enum ContentType: String, Codable, Sendable, CaseIterable {
    // Original types
    case article
    case video
    case audio
    case document
    case webpage
    case unknown

    // Government/Civic page types (Phase 1 expansion)
    case meetingAgenda = "meeting_agenda"
    case meetingMinutes = "meeting_minutes"
    case eventCalendar = "event_calendar"
    case eventListing = "event_listing"
    case contactDirectory = "contact_directory"
    case jobPosting = "job_posting"
    case publicNotice = "public_notice"
    case pressRelease = "press_release"
    case organizationPage = "organization_page"
    case personnelRoster = "personnel_roster"

    /// Custom decoder for case-insensitive decoding (handles "Article" or "article")
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        // Try case-insensitive match
        switch rawValue.lowercased().replacingOccurrences(of: "_", with: "") {
        case "article": self = .article
        case "video": self = .video
        case "audio": self = .audio
        case "document": self = .document
        case "webpage": self = .webpage
        case "meetingagenda": self = .meetingAgenda
        case "meetingminutes": self = .meetingMinutes
        case "eventcalendar": self = .eventCalendar
        case "eventlisting": self = .eventListing
        case "contactdirectory": self = .contactDirectory
        case "jobposting": self = .jobPosting
        case "publicnotice": self = .publicNotice
        case "pressrelease": self = .pressRelease
        case "organizationpage": self = .organizationPage
        case "personnelroster": self = .personnelRoster
        default: self = .unknown
        }
    }

    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .article: return "Article"
        case .video: return "Video"
        case .audio: return "Audio"
        case .document: return "Document"
        case .webpage: return "Web Page"
        case .unknown: return "Unknown"
        case .meetingAgenda: return "Meeting Agenda"
        case .meetingMinutes: return "Meeting Minutes"
        case .eventCalendar: return "Event Calendar"
        case .eventListing: return "Event Listing"
        case .contactDirectory: return "Contact Directory"
        case .jobPosting: return "Job Posting"
        case .publicNotice: return "Public Notice"
        case .pressRelease: return "Press Release"
        case .organizationPage: return "Organization Page"
        case .personnelRoster: return "Personnel Roster"
        }
    }

    /// Whether this content type typically contains news/articles
    public var isNewsContent: Bool {
        switch self {
        case .article, .pressRelease: return true
        default: return false
        }
    }

    /// Whether this content type is a structured data source (calendars, directories)
    public var isStructuredData: Bool {
        switch self {
        case .meetingAgenda, .meetingMinutes, .eventCalendar, .eventListing,
             .contactDirectory, .jobPosting, .personnelRoster:
            return true
        default:
            return false
        }
    }
}

/// Processing status for services (replaces magic strings)
public enum ProcessingStatus: String, Codable, Sendable {
    case success
    case error

    public var isSuccess: Bool {
        self == .success
    }
}

// MARK: - Publish-Date Provenance

/// Source used to infer `publishedAt`
public enum PublishedAtSource: String, Codable, Sendable {
    case rawContent = "raw_content"
    case pageRescan = "page_rescan"
    case aiFoundation = "ai_foundation"
    case aiLocalLmstudio = "ai_local_lmstudio"
    case aiCloud = "ai_cloud"
    case unknown

    public var isAI: Bool {
        switch self {
        case .aiFoundation, .aiLocalLmstudio, .aiCloud:
            return true
        default:
            return false
        }
    }
}

/// Confidence level for publish-date determination
public enum PublishedAtConfidence: String, Codable, Sendable {
    case high
    case medium
    case low

    /// Numeric score for threshold comparisons (WS-B guardrail).
    /// high = 0.95, medium = 0.75, low = 0.40
    public var numericScore: Double {
        switch self {
        case .high: return 0.95
        case .medium: return 0.75
        case .low: return 0.40
        }
    }

    /// Whether this confidence meets the WS-B drafting threshold (>= 0.93).
    public var meetsDraftingThreshold: Bool {
        numericScore >= 0.93
    }
}

// MARK: - Entity Models

/// Entity extracted by Foundation Models
/// Matches Python's IntelligenceEntity
public struct IntelligenceEntity: Codable, Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let text: String
    public let type: String  // "person", "organization", "place"

    public init(text: String, type: String) {
        self.text = text
        self.type = type
    }

    enum CodingKeys: String, CodingKey {
        case text, type
    }
}

// MARK: - WebKit Models

/// Image metadata extracted from web pages
public struct ImageMetadata: Codable, Hashable, Sendable {
    public let src: String
    public let alt: String?
    public let width: Int?
    public let height: Int?

    public init(src: String, alt: String? = nil, width: Int? = nil, height: Int? = nil) {
        self.src = src
        self.alt = alt
        self.width = width
        self.height = height
    }
}

/// Contact information extracted from web pages
/// Different from UtahNewsDataModels.ContactInfo - this is for raw page extraction
public struct WebPageContactInfo: Codable, Hashable, Sendable {
    public let phones: [String]?
    public let emails: [String]?
    public let addresses: [String]?

    public init(phones: [String]? = nil, emails: [String]? = nil, addresses: [String]? = nil) {
        self.phones = phones
        self.emails = emails
        self.addresses = addresses
    }
}

/// Complete content and metadata extracted by WebKit
/// Matches Python's WebKitEnrichedContent
public struct WebKitEnrichedContent: Codable, Identifiable, Hashable, Sendable {
    public let id = UUID()

    /// WebKit extraction status
    public let status: ProcessingStatus

    /// Core Content
    public let cleanText: String
    public let fmExcerpt: String?  // Optimized excerpt for Foundation Models (<8k chars)

    /// Rich Metadata
    public let title: String?
    public let description: String?  // This becomes our summary
    public let keywords: [String]?

    /// Content Metadata
    public let language: String?
    public let author: String?
    public let publishDate: Date?

    /// Source Tracking
    public let sourceURL: String

    /// Error Handling
    public let errorMessage: String?

    /// Structured Data (JSON-LD, OpenGraph, etc.)
    nonisolated(unsafe) public let structuredData: [String: AnyCodable]?

    /// Extracted Images
    public let images: [ImageMetadata]?

    /// Contact Information
    public let contactInfo: WebPageContactInfo?

    public init(
        status: ProcessingStatus,
        cleanText: String,
        fmExcerpt: String? = nil,
        title: String? = nil,
        description: String? = nil,
        keywords: [String]? = nil,
        language: String? = nil,
        author: String? = nil,
        publishDate: Date? = nil,
        sourceURL: String,
        errorMessage: String? = nil,
        structuredData: [String: AnyCodable]? = nil,
        images: [ImageMetadata]? = nil,
        contactInfo: WebPageContactInfo? = nil
    ) {
        self.status = status
        self.cleanText = cleanText
        self.fmExcerpt = fmExcerpt
        self.title = title
        self.description = description
        self.keywords = keywords
        self.language = language
        self.author = author
        self.publishDate = publishDate
        self.sourceURL = sourceURL
        self.errorMessage = errorMessage
        self.structuredData = structuredData
        self.images = images
        self.contactInfo = contactInfo
    }

    // LEGACY: snake_case fields from retired Python pipeline - DO NOT CHANGE
    // See FIRESTORE_SCHEMA.md for complete documentation
    enum CodingKeys: String, CodingKey {
        case status
        case cleanText = "clean_text"           // LEGACY snake_case
        case fmExcerpt = "fm_excerpt"           // LEGACY snake_case
        case title
        case description
        case keywords
        case language
        case author
        case publishDate = "publish_date"       // LEGACY snake_case
        case sourceURL = "source_url"           // LEGACY snake_case
        case errorMessage = "error_message"     // LEGACY snake_case
        case structuredData = "structured_data" // LEGACY snake_case
        case images
        case contactInfo = "contact_info"       // LEGACY snake_case
    }
}

// MARK: - Foundation Models

/// Complete analysis from Apple Foundation Models
/// Matches Python's FoundationModelsAnalysis
public struct FoundationModelsAnalysis: Codable, Hashable, Sendable {
    /// Analysis status
    public let status: ProcessingStatus

    /// Entity Extraction
    public let entities: [IntelligenceEntity]?

    /// Topic Classification
    public let topics: [String]?

    /// Sentiment Analysis
    public let sentimentLabel: SentimentLabel?
    public let sentimentScore: Double?  // -1.0 to +1.0

    /// Language Detection
    public let dominantLanguage: String?  // e.g., "en"

    /// Quality Metrics
    public let confidence: Double  // 0.0-1.0
    public let processingTimeMs: Int?

    /// Error Handling
    public let errorCode: String?
    public let errorMessage: String?

    public init(
        status: ProcessingStatus,
        entities: [IntelligenceEntity]? = nil,
        topics: [String]? = nil,
        sentimentLabel: SentimentLabel? = nil,
        sentimentScore: Double? = nil,
        dominantLanguage: String? = nil,
        confidence: Double,
        processingTimeMs: Int? = nil,
        errorCode: String? = nil,
        errorMessage: String? = nil
    ) {
        self.status = status
        self.entities = entities
        self.topics = topics
        self.sentimentLabel = sentimentLabel
        self.sentimentScore = sentimentScore
        self.dominantLanguage = dominantLanguage
        self.confidence = confidence
        self.processingTimeMs = processingTimeMs
        self.errorCode = errorCode
        self.errorMessage = errorMessage
    }

    // LEGACY: snake_case fields from retired Python pipeline - DO NOT CHANGE
    // See FIRESTORE_SCHEMA.md for complete documentation
    enum CodingKeys: String, CodingKey {
        case status
        case entities
        case topics
        case sentimentLabel = "sentiment_label"       // LEGACY snake_case
        case sentimentScore = "sentiment_score"       // LEGACY snake_case
        case dominantLanguage = "dominant_language"   // LEGACY snake_case
        case confidence
        case processingTimeMs = "processing_time_ms"  // LEGACY snake_case
        case errorCode = "error_code"                 // LEGACY snake_case
        case errorMessage = "error_message"           // LEGACY snake_case
    }
}

// MARK: - Editorial Signals

/// Editorial signals computed during processing for NewsCapture to consume.
/// V2PipelineTester outputs these signals; NewsCapture makes editorial decisions.
/// This separates "extraction/enrichment" (V2) from "editorial workflow" (NewsCapture).
public struct EditorialSignals: Codable, Hashable, Sendable {
    /// Content type meets article criteria (article, pressRelease = true)
    public let meetsArticleCriteria: Bool

    /// High-profile entity detection (Governor, Senator, Mayor, etc.)
    public let hasHighProfileEntities: Bool
    public let highProfileEntityNames: [String]?

    /// Breaking/urgent keyword detection
    public let hasBreakingKeywords: Bool
    public let breakingKeywords: [String]?

    /// Quality signal count for ranking (higher = more newsworthy signals)
    public let qualitySignalCount: Int
    public let qualitySignals: [String]

    /// Suggested priority (NewsCapture can override)
    /// Values: "low", "normal", "high", "breaking"
    public let suggestedPriority: String

    public init(
        meetsArticleCriteria: Bool,
        hasHighProfileEntities: Bool,
        highProfileEntityNames: [String]? = nil,
        hasBreakingKeywords: Bool,
        breakingKeywords: [String]? = nil,
        qualitySignalCount: Int,
        qualitySignals: [String],
        suggestedPriority: String
    ) {
        self.meetsArticleCriteria = meetsArticleCriteria
        self.hasHighProfileEntities = hasHighProfileEntities
        self.highProfileEntityNames = highProfileEntityNames
        self.hasBreakingKeywords = hasBreakingKeywords
        self.breakingKeywords = breakingKeywords
        self.qualitySignalCount = qualitySignalCount
        self.qualitySignals = qualitySignals
        self.suggestedPriority = suggestedPriority
    }
}

// MARK: - Final Data Payload

/// Final processed data payload for processed_items_v2 collection
/// This is the complete output from the Swift V2 Pipeline
public struct FinalDataPayloadV2: Codable, Identifiable, Hashable, Sendable {

    // Document ID from Firestore
    @DocumentID public var id: String?

    // ===== Source Information =====
    public let url: String
    public let sourceTitle: String

    // ===== Content (from WebKit) =====
    public let cleanedText: String
    public let summary: String
    public let author: String?
    public let publishDate: Date?

    // ===== Analysis (from Foundation Models) =====
    public let entitiesJson: String  // JSON-encoded list of entities
    public let topics: [String]
    public let sentimentLabel: SentimentLabel
    public let sentimentScore: Double
    public let language: String

    // ===== Utah-Specific =====
    public let isRelevantToUtah: Bool
    public let relevanceScore: Double
    public let utahLocations: [String]

    // ===== Source Promotion Tracking =====
    public let relevanceMethod: RelevanceMethod?
    public let promotionCandidate: Bool  // Should be considered for promotion to permanent source
    public let promotedToSource: Bool    // Has been promoted to cities/{city}/sources collection
    public let sourceId: String?         // Reference to source document if promoted

    // ===== Metadata =====
    public let processingTimestamp: Date
    public let identifiedContentType: ContentType
    public let confidenceScores: [String: Double]

    /// Canonical publish date parsed from source (nullable)
    public let publishedAt: Date?

    /// How `publishedAt` was derived
    public let publishedAtSource: PublishedAtSource

    /// Confidence in `publishedAt` inference
    public let publishedAtConfidence: PublishedAtConfidence

    /// True when content is evergreen/undated (no conclusive publish date)
    public let isEvergreen: Bool

    /// Discovered timestamp for this item
    public let discoveredAt: Date

    /// Ingested/enriched timestamp (separate from publish date)
    public let ingestedAt: Date

    // Optional enrichment
    nonisolated(unsafe) public let structuredData: [String: AnyCodable]?

    // ===== Raw Data Preservation (NEW 2025 - camelCase per policy) =====
    /// The excerpt that was analyzed by FoundationModels (for debugging/inspection)
    public let fmExcerpt: String?
    /// Meta keywords extracted from the page
    public let keywords: [String]?

    // ===== Page Role Classification (NEW 2025 - camelCase per policy) =====
    /// Classified page role (discovery_page, article_page, sitemap, etc.)
    public let pageRole: String?
    /// Discovery scope for list pages (utah_wide, city_specific, regional)
    public let discoveryScope: String?
    /// Classification confidence (0.0 - 1.0)
    public let classificationConfidence: Double?
    /// Assigned scan frequency based on role (hourly, daily, weekly, monthly, manual)
    public let assignedScanFrequency: String?
    /// Number of URLs extracted (for discovery pages)
    public let extractedURLCount: Int?

    // ===== Editorial Signals (NEW 2026 - camelCase per policy) =====
    /// Signals computed during processing for NewsCapture's editorial workflow.
    /// V2 outputs signals; NewsCapture makes editorial decisions.
    public let editorialSignals: EditorialSignals?

    // LEGACY: All snake_case fields below are from retired Python V2 pipeline
    // DO NOT change to camelCase - breaks other dependent systems (web dashboards, analytics, backend services)
    // See FIRESTORE_SCHEMA.md for complete legacy field reference
    // Policy: All NEW fields added after 2025 MUST use camelCase (no CodingKeys mapping needed)
    // NOTE: 'id' is NOT included here - @DocumentID is populated automatically by Firebase SDK
    enum CodingKeys: String, CodingKey {
        // id is intentionally omitted - @DocumentID is set by Firebase from document reference
        case url
        case sourceTitle = "source_title"                      // LEGACY snake_case
        case cleanedText = "cleaned_text"                      // LEGACY snake_case
        case summary
        case author
        case publishDate = "publish_date"                      // LEGACY snake_case
        case entitiesJson = "entities_json"                    // LEGACY snake_case
        case topics
        case sentimentLabel = "sentiment_label"                // LEGACY snake_case
        case sentimentScore = "sentiment_score"                // LEGACY snake_case
        case language
        case isRelevantToUtah = "is_relevant_to_utah"          // LEGACY snake_case
        case relevanceScore = "relevance_score"                // LEGACY snake_case
        case utahLocations = "utah_locations"                  // LEGACY snake_case
        case relevanceMethod = "relevance_method"              // LEGACY snake_case
        case promotionCandidate = "promotion_candidate"        // LEGACY snake_case
        case promotedToSource = "promoted_to_source"           // LEGACY snake_case
        case sourceId = "source_id"                           // LEGACY snake_case
        case processingTimestamp = "processing_timestamp"      // LEGACY snake_case
        case identifiedContentType = "identified_content_type" // LEGACY snake_case
        case confidenceScores = "confidence_scores"            // LEGACY snake_case
        case publishedAt = "published_at"                      // Canonical publish date
        case publishedAtSource = "published_at_source"          // Canonical publish source
        case publishedAtConfidence = "published_at_confidence"  // Canonical publish confidence
        case isEvergreen = "is_evergreen"                      // Canonical evergreen flag
        case discoveredAt = "discovered_at"                    // Canonical discovered time
        case ingestedAt = "ingested_at"                       // Canonical ingest time
        case structuredData = "structured_data"                // LEGACY snake_case
        // NEW 2025 fields - camelCase per policy (no custom rawValue needed)
        case fmExcerpt
        case keywords
        case pageRole
        case discoveryScope
        case classificationConfidence
        case assignedScanFrequency
        case extractedURLCount
        // NEW 2026 field - editorial signals for NewsCapture
        case editorialSignals
    }

    // MARK: - Initializers

    /// Explicit initializer for programmatic creation
    public init(
        id: String? = nil,
        url: String,
        sourceTitle: String,
        cleanedText: String,
        summary: String,
        author: String?,
        publishDate: Date?,
        entitiesJson: String,
        topics: [String],
        sentimentLabel: SentimentLabel,
        sentimentScore: Double,
        language: String,
        isRelevantToUtah: Bool,
        relevanceScore: Double,
        utahLocations: [String],
        relevanceMethod: RelevanceMethod? = nil,
        promotionCandidate: Bool = false,
        promotedToSource: Bool = false,
        sourceId: String? = nil,
        processingTimestamp: Date,
        identifiedContentType: ContentType,
        confidenceScores: [String: Double],
        structuredData: [String: AnyCodable]?,
        fmExcerpt: String? = nil,
        keywords: [String]? = nil,
        // Page Role Classification
        pageRole: String? = nil,
        discoveryScope: String? = nil,
        classificationConfidence: Double? = nil,
        assignedScanFrequency: String? = nil,
        extractedURLCount: Int? = nil,
        // Canonical publish metadata / editorial guardrails
        publishedAt: Date? = nil,
        publishedAtSource: PublishedAtSource = .unknown,
        publishedAtConfidence: PublishedAtConfidence = .low,
        isEvergreen: Bool? = nil,
        discoveredAt: Date? = nil,
        ingestedAt: Date? = nil,
        // Editorial Signals
        editorialSignals: EditorialSignals? = nil
    ) {
        self._id = DocumentID(wrappedValue: id)
        let resolvedPublishedAt = publishedAt ?? publishDate
        self.url = url
        self.sourceTitle = sourceTitle
        self.cleanedText = cleanedText
        self.summary = summary
        self.author = author
        self.publishDate = publishDate
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
        self.processingTimestamp = processingTimestamp
        self.identifiedContentType = identifiedContentType
        self.confidenceScores = confidenceScores
        self.publishedAt = resolvedPublishedAt

        let inferredSource: PublishedAtSource
        let inferredConfidence: PublishedAtConfidence
        if let source = (publishDate != nil ? (publishedAtSource == .unknown ? .rawContent : publishedAtSource) : nil) {
            inferredSource = source
            inferredConfidence = publishedAtConfidence
        } else if resolvedPublishedAt != nil {
            inferredSource = .rawContent
            inferredConfidence = .high
        } else {
            inferredSource = .unknown
            inferredConfidence = .low
        }

        self.publishedAtSource = inferredSource
        self.publishedAtConfidence = inferredConfidence
        self.isEvergreen = isEvergreen ?? (resolvedPublishedAt == nil)
        self.discoveredAt = discoveredAt ?? processingTimestamp
        self.ingestedAt = ingestedAt ?? processingTimestamp
        self.structuredData = structuredData
        self.fmExcerpt = fmExcerpt
        self.keywords = keywords
        self.pageRole = pageRole
        self.discoveryScope = discoveryScope
        self.classificationConfidence = classificationConfidence
        self.assignedScanFrequency = assignedScanFrequency
        self.extractedURLCount = extractedURLCount
        self.editorialSignals = editorialSignals
    }

    // Custom decoding to handle Firestore Timestamps
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // @DocumentID is NOT decoded from data - Firebase SDK populates it from document reference
        // Initialize with nil; Firebase's doc.data(as:) and @FirestoreQuery will set it automatically
        _id = DocumentID(wrappedValue: nil)

        // Required fields
        url = try container.decode(String.self, forKey: .url)
        sourceTitle = try container.decode(String.self, forKey: .sourceTitle)
        cleanedText = try container.decode(String.self, forKey: .cleanedText)
        summary = try container.decode(String.self, forKey: .summary)
        author = try container.decodeIfPresent(String.self, forKey: .author)

        // Decode dates (handle Firestore Timestamp format)
        publishDate = try? Self.decodeFirestoreDate(from: container, forKey: .publishDate)
        processingTimestamp = (try? Self.decodeFirestoreDate(from: container, forKey: .processingTimestamp)) ?? Date()
        publishedAt = try? Self.decodeFirestoreDate(from: container, forKey: .publishedAt)

        var inferredSource = (try? container.decode(PublishedAtSource.self, forKey: .publishedAtSource)) ?? .unknown
        var inferredConfidence = (try? container.decode(PublishedAtConfidence.self, forKey: .publishedAtConfidence)) ?? .low
        if publishedAt != nil && inferredSource == .unknown && inferredConfidence == .low {
            inferredSource = .rawContent
            inferredConfidence = .medium
        }

        publishedAtSource = inferredSource
        publishedAtConfidence = inferredConfidence
        isEvergreen = (try? container.decode(Bool.self, forKey: .isEvergreen)) ?? (publishedAt == nil)
        discoveredAt = (try? Self.decodeFirestoreDate(from: container, forKey: .discoveredAt)) ?? processingTimestamp
        ingestedAt = (try? Self.decodeFirestoreDate(from: container, forKey: .ingestedAt)) ?? processingTimestamp

        // Analysis fields
        entitiesJson = try container.decode(String.self, forKey: .entitiesJson)
        topics = try container.decode([String].self, forKey: .topics)
        sentimentLabel = try container.decode(SentimentLabel.self, forKey: .sentimentLabel)
        sentimentScore = try container.decode(Double.self, forKey: .sentimentScore)
        language = try container.decode(String.self, forKey: .language)

        // Utah-specific
        isRelevantToUtah = try container.decode(Bool.self, forKey: .isRelevantToUtah)
        relevanceScore = try container.decode(Double.self, forKey: .relevanceScore)
        utahLocations = try container.decode([String].self, forKey: .utahLocations)

        // Source promotion tracking (new fields, provide defaults for backward compatibility)
        relevanceMethod = try container.decodeIfPresent(RelevanceMethod.self, forKey: .relevanceMethod)
        promotionCandidate = (try? container.decode(Bool.self, forKey: .promotionCandidate)) ?? false
        promotedToSource = (try? container.decode(Bool.self, forKey: .promotedToSource)) ?? false
        sourceId = try container.decodeIfPresent(String.self, forKey: .sourceId)

        // Metadata
        identifiedContentType = try container.decode(ContentType.self, forKey: .identifiedContentType)
        confidenceScores = try container.decode([String: Double].self, forKey: .confidenceScores)
        structuredData = try container.decodeIfPresent([String: AnyCodable].self, forKey: .structuredData)

        // NEW 2025 fields - optional for backward compatibility with existing documents
        fmExcerpt = try container.decodeIfPresent(String.self, forKey: .fmExcerpt)
        keywords = try container.decodeIfPresent([String].self, forKey: .keywords)

        // Page Role Classification fields - optional for backward compatibility
        pageRole = try container.decodeIfPresent(String.self, forKey: .pageRole)
        discoveryScope = try container.decodeIfPresent(String.self, forKey: .discoveryScope)
        classificationConfidence = try container.decodeIfPresent(Double.self, forKey: .classificationConfidence)
        assignedScanFrequency = try container.decodeIfPresent(String.self, forKey: .assignedScanFrequency)
        extractedURLCount = try container.decodeIfPresent(Int.self, forKey: .extractedURLCount)

        // NEW 2026 field - Editorial Signals for NewsCapture
        editorialSignals = try container.decodeIfPresent(EditorialSignals.self, forKey: .editorialSignals)
    }

    // Helper to decode Firestore Timestamp or Date
    private static func decodeFirestoreDate(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Date? {
        // Try to decode as Date directly (works if Firebase SDK auto-converts)
        if let date = try? container.decode(Date.self, forKey: key) {
            return date
        }

        // Try to decode as Firestore Timestamp dictionary
        if let timestamp = try? container.decode(Timestamp.self, forKey: key) {
            return timestamp.dateValue()
        }

        return nil
    }

    // MARK: - Computed Properties

    /// Canonical conclusive publish date indicator (WS-B: requires >= 0.93 confidence)
    public var hasConclusivePublishedAt: Bool {
        let hasDate = publishedAt != nil
        let hasStrongSource = publishedAtSource != .unknown
        let meetsThreshold = publishedAtConfidence.meetsDraftingThreshold
        return hasDate && hasStrongSource && meetsThreshold
    }

    /// Draft eligibility from this payload (WS-B guardrail enforced)
    public var isDraftEligible: Bool {
        return hasConclusivePublishedAt && !isEvergreen
    }

    /// Structured guardrail evaluation for audit logging (WS-B)
    public var dateGuardrailResult: DateGuardrailResult {
        DateGuardrailResult.evaluate(
            publishedAt: publishedAt,
            publishedAtSource: publishedAtSource,
            publishedAtConfidence: publishedAtConfidence,
            isEvergreen: isEvergreen,
            discoveredAt: discoveredAt,
            ingestedAt: ingestedAt
        )
    }

    /// Parse entities from JSON string
    public var entities: [IntelligenceEntity] {
        guard let data = entitiesJson.data(using: .utf8) else { return [] }

        // Try to decode as array of entity dictionaries
        if let entityDicts = try? JSONDecoder().decode([[String: AnyCodable]].self, from: data) {
            return entityDicts.compactMap { dict in
                guard let typeValue = dict["type"]?.value as? String,
                      let dataDict = dict["data"]?.value as? [String: Any],
                      let name = dataDict["name"] as? String else {
                    return nil
                }
                return IntelligenceEntity(text: name, type: typeValue)
            }
        }

        // Fallback: try direct IntelligenceEntity array
        if let entities = try? JSONDecoder().decode([IntelligenceEntity].self, from: data) {
            return entities
        }

        return []
    }

    /// Group entities by type
    public var entitiesByType: [String: [IntelligenceEntity]] {
        Dictionary(grouping: entities, by: { $0.type })
    }

    /// Sentiment display string
    public var sentimentDisplay: String {
        let emoji: String
        switch sentimentLabel {
        case .positive: emoji = "😊"
        case .negative: emoji = "😔"
        case .neutral: emoji = "😐"
        }
        return "\(emoji) \(sentimentLabel.rawValue.capitalized) (\(String(format: "%.2f", sentimentScore)))"
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        // Use URL as primary identifier since ID might be nil
        hasher.combine(url)
        hasher.combine(processingTimestamp)
    }

    public static func == (lhs: FinalDataPayloadV2, rhs: FinalDataPayloadV2) -> Bool {
        // Compare by URL and timestamp to handle nil IDs
        lhs.url == rhs.url && lhs.processingTimestamp == rhs.processingTimestamp
    }
}

// MARK: - Helper for Any Codable

/// Helper for encoding/decoding heterogeneous JSON
/// Note: Not Sendable due to 'Any' type - use with caution in concurrent contexts
public struct AnyCodable: Codable, Hashable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }

    // MARK: - Hashable

    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case let (l as Bool, r as Bool): return l == r
        case let (l as Int, r as Int): return l == r
        case let (l as Double, r as Double): return l == r
        case let (l as String, r as String): return l == r
        case let (l as [Any], r as [Any]): return l.count == r.count
        case let (l as [String: Any], r as [String: Any]): return l.count == r.count
        default: return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch value {
        case let bool as Bool: hasher.combine(bool)
        case let int as Int: hasher.combine(int)
        case let double as Double: hasher.combine(double)
        case let string as String: hasher.combine(string)
        case let array as [Any]: hasher.combine(array.count)
        case let dict as [String: Any]: hasher.combine(dict.count)
        default: hasher.combine(0)
        }
    }
}

// MARK: - Fresh Content Stream Models

/// Content status for fresh_content collection
public enum ContentStatus: String, Codable, Sendable {
    /// Brand new URL, never processed before
    case new = "new"
    /// Existing source with content changes detected
    case updated = "updated"
}

/// Fresh content item for the `fresh_content` collection
/// Only NEW or UPDATED content is written here (not stale/unchanged)
/// Used for real-time content feeds and efficient consumption by client apps
public struct FreshContentItem: Codable, Identifiable, Sendable {
    /// Document ID (SHA-1 hash of URL)
    public var id: String { url.sha1Hash() }

    /// Source URL
    public let url: String

    /// Article/page title
    public let sourceTitle: String

    /// Cleaned text content (truncated to 10k chars for consumption)
    public let cleanedText: String

    /// Summary/description
    public let summary: String?

    /// Author if extracted
    public let author: String?

    /// Publish date if extracted
    public let publishDate: Date?

    /// Extracted entities (parsed array, not JSON string)
    public let entities: [IntelligenceEntity]

    /// Classification topics
    public let topics: [String]

    /// Sentiment label (positive, negative, neutral)
    public let sentimentLabel: String?

    /// Sentiment score (-1.0 to 1.0)
    public let sentimentScore: Double?

    /// Utah locations mentioned
    public let utahLocations: [String]

    /// Utah relevance score (0.0 to 1.0)
    public let relevanceScore: Double

    /// When this content was processed
    public let processingTimestamp: Date

    /// Content status: new or updated
    public let contentStatus: ContentStatus

    /// SHA-256 hash of cleanedText for change detection
    public let contentHash: String

    /// Reference to the full processed_items_v2 document
    public let sourceDocumentId: String

    /// Processing mode that created this item
    public let processingMode: String

    /// Expiration timestamp for TTL cleanup (7 days from processing)
    public let expiresAt: Date

    // MARK: - Entity Linking (Phase 2)

    /// IDs of matched Person documents from `people` collection
    public let linkedPeopleIds: [String]

    /// IDs of matched Organization documents from `organizations` collection
    public let linkedOrganizationIds: [String]

    /// IDs of matched Location documents (if available)
    public let linkedLocationIds: [String]

    /// Average confidence score across all entity matches (0.0 - 1.0)
    public let entityMatchConfidence: Double

    /// Creates a FreshContentItem from a FinalDataPayloadV2
    /// - Parameters:
    ///   - payload: The processed pipeline payload
    ///   - sourceDocumentId: Reference to processed_items_v2 document
    ///   - contentHash: SHA-256 hash for change detection
    ///   - contentStatus: Whether content is new or updated
    ///   - processingMode: Processing mode that created this item
    ///   - linkedPeopleIds: IDs of matched people (from entity matching)
    ///   - linkedOrganizationIds: IDs of matched organizations (from entity matching)
    ///   - linkedLocationIds: IDs of matched locations (from entity matching)
    ///   - entityMatchConfidence: Average entity match confidence
    public init(
        from payload: FinalDataPayloadV2,
        sourceDocumentId: String,
        contentHash: String,
        contentStatus: ContentStatus,
        processingMode: String,
        linkedPeopleIds: [String] = [],
        linkedOrganizationIds: [String] = [],
        linkedLocationIds: [String] = [],
        entityMatchConfidence: Double = 0.0
    ) {
        self.url = payload.url
        self.sourceTitle = payload.sourceTitle
        // Truncate cleanedText to 10k chars for efficient consumption
        self.cleanedText = String(payload.cleanedText.prefix(10_000))
        self.summary = payload.summary
        self.author = payload.author
        self.publishDate = payload.publishDate

        // Parse entities from JSON string
        if let jsonData = payload.entitiesJson.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([IntelligenceEntity].self, from: jsonData) {
            self.entities = decoded
        } else {
            self.entities = []
        }

        self.topics = payload.topics
        self.sentimentLabel = payload.sentimentLabel.rawValue
        self.sentimentScore = payload.sentimentScore
        self.utahLocations = payload.utahLocations
        self.relevanceScore = payload.relevanceScore
        self.processingTimestamp = payload.processingTimestamp
        self.contentStatus = contentStatus
        self.contentHash = contentHash
        self.sourceDocumentId = sourceDocumentId
        self.processingMode = processingMode

        // Set expiration to 7 days from now
        self.expiresAt = Date().addingTimeInterval(7 * 24 * 60 * 60)

        // Entity linking
        self.linkedPeopleIds = linkedPeopleIds
        self.linkedOrganizationIds = linkedOrganizationIds
        self.linkedLocationIds = linkedLocationIds
        self.entityMatchConfidence = entityMatchConfidence
    }

    /// Direct initializer for all fields
    public init(
        url: String,
        sourceTitle: String,
        cleanedText: String,
        summary: String?,
        author: String?,
        publishDate: Date?,
        entities: [IntelligenceEntity],
        topics: [String],
        sentimentLabel: String?,
        sentimentScore: Double?,
        utahLocations: [String],
        relevanceScore: Double,
        processingTimestamp: Date,
        contentStatus: ContentStatus,
        contentHash: String,
        sourceDocumentId: String,
        processingMode: String,
        expiresAt: Date,
        linkedPeopleIds: [String] = [],
        linkedOrganizationIds: [String] = [],
        linkedLocationIds: [String] = [],
        entityMatchConfidence: Double = 0.0
    ) {
        self.url = url
        self.sourceTitle = sourceTitle
        self.cleanedText = cleanedText
        self.summary = summary
        self.author = author
        self.publishDate = publishDate
        self.entities = entities
        self.topics = topics
        self.sentimentLabel = sentimentLabel
        self.sentimentScore = sentimentScore
        self.utahLocations = utahLocations
        self.relevanceScore = relevanceScore
        self.processingTimestamp = processingTimestamp
        self.contentStatus = contentStatus
        self.contentHash = contentHash
        self.sourceDocumentId = sourceDocumentId
        self.processingMode = processingMode
        self.expiresAt = expiresAt
        self.linkedPeopleIds = linkedPeopleIds
        self.linkedOrganizationIds = linkedOrganizationIds
        self.linkedLocationIds = linkedLocationIds
        self.entityMatchConfidence = entityMatchConfidence
    }
}
