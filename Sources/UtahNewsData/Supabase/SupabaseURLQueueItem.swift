//
//  SupabaseURLQueueItem.swift
//  UtahNewsData
//
//  Typed model for the `url_queue` Supabase table.
//  Matches the schema in SUPABASE_SCHEMA.sql.
//
//  Previously defined independently in V2PipelineTester and URLCapture.
//

import Foundation

// MARK: - URL Queue Item (Read Model)

/// A row from the `url_queue` table in Supabase.
///
/// This is the primary processing queue for the V2 pipeline.
/// Each row represents a URL to be processed. The `id` is a SHA-1 hash of the URL.
public struct SupabaseURLQueueItem: Codable, Sendable, Identifiable {

    // MARK: - Core Fields

    /// SHA-1 hash of the URL (primary key)
    public let id: String

    /// The URL to process
    public let url: String

    /// Queue status: pending, processing, completed, failed
    public let status: String

    /// When the item was added to the queue
    public let createdAt: String?

    /// Number of processing attempts
    public let attempts: Int

    /// Where this URL was discovered from (parent URL, RSS feed, etc.)
    public let discoveredFrom: String?

    // MARK: - Processing Fields

    /// When processing last started
    public let startedAt: String?

    /// When processing finished
    public let finishedAt: String?

    /// When the last attempt was made
    public let lastAttempt: String?

    /// Last activity timestamp (heartbeat)
    public let lastActivity: String?

    /// UUID of the pipeline instance that claimed this URL
    public let claimedBy: String?

    /// Lock expiry for multi-instance coordination (5-min timeout)
    public let lockExpiry: String?

    /// Worker instance identifier
    public let workerInstanceId: String?

    /// Current processing agent name
    public let currentAgent: String?

    /// Current pipeline stage
    public let pipelineStage: String?

    /// Pipeline version that processed this URL
    public let pipelineVersion: String?

    /// Processing mode: first_time, refresh, list_item
    public let processingMode: String?

    // MARK: - Completion Metadata

    /// Human-readable completion message
    public let message: String?

    /// Processing duration in seconds
    public let durationSec: Double?

    // MARK: - Success Metrics

    /// Number of entities extracted
    public let entitiesCount: Int?

    /// Number of topics identified
    public let topicsCount: Int?

    /// Whether the content is Utah-relevant
    public let utahRelevant: Bool?

    /// Utah relevance score (0.0-1.0)
    public let relevanceScore: Double?

    /// Number of characters extracted
    public let extractedChars: Int?

    /// Number of locations identified
    public let locationsCount: Int?

    /// Sentiment label: positive, negative, neutral
    public let sentimentLabel: String?

    /// Sentiment score (-1.0 to 1.0)
    public let sentimentScore: Double?

    /// Whether content is relevant (general)
    public let isRelevant: Bool?

    // MARK: - Error Fields

    /// Error code if processing failed
    public let errorCode: String?

    /// Error category for classification
    public let errorCategory: String?

    /// Human-readable error message
    public let errorMessage: String?

    /// Reason for skipping this URL
    public let skipReason: String?

    // MARK: - Discovery Metadata

    /// Page title from extraction
    public let title: String?

    /// Content snippet
    public let snippet: String?

    /// Discovery source identifier
    public let source: String?

    /// How the URL was discovered
    public let discoveryType: String?

    /// City associated with this URL
    public let cityName: String?

    /// Source document ID
    public let sourceId: String?

    /// Source name for display
    public let sourceName: String?

    /// Content category
    public let category: String?

    /// Content sub-category
    public let subCategory: String?

    // MARK: - Context (JSONB)

    /// User submission metadata
    public let submissionContext: SupabaseAnyCodable?

    /// List extraction metadata
    public let extractionContext: SupabaseAnyCodable?

    /// Scheduled refresh metadata
    public let refreshContext: SupabaseAnyCodable?

    /// Migration metadata
    public let migrationContext: SupabaseAnyCodable?

    // MARK: - Additional Fields

    /// Firestore source document path (for reclassification)
    public let sourceDocPath: String?

    /// Whether this URL requires a powerful device for processing
    public let requiresPowerfulDevice: Bool?

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id, url, status, attempts, message, title, snippet, source, category
        case createdAt = "created_at"
        case discoveredFrom = "discovered_from"
        case startedAt = "started_at"
        case finishedAt = "finished_at"
        case lastAttempt = "last_attempt"
        case lastActivity = "last_activity"
        case claimedBy = "claimed_by"
        case lockExpiry = "lock_expiry"
        case workerInstanceId = "worker_instance_id"
        case currentAgent = "current_agent"
        case pipelineStage = "pipeline_stage"
        case pipelineVersion = "pipeline_version"
        case processingMode = "processing_mode"
        case durationSec = "duration_sec"
        case entitiesCount = "entities_count"
        case topicsCount = "topics_count"
        case utahRelevant = "utah_relevant"
        case relevanceScore = "relevance_score"
        case extractedChars = "extracted_chars"
        case locationsCount = "locations_count"
        case sentimentLabel = "sentiment_label"
        case sentimentScore = "sentiment_score"
        case isRelevant = "is_relevant"
        case errorCode = "error_code"
        case errorCategory = "error_category"
        case errorMessage = "error_message"
        case skipReason = "skip_reason"
        case discoveryType = "discovery_type"
        case cityName = "city_name"
        case sourceId = "source_id"
        case sourceName = "source_name"
        case subCategory = "sub_category"
        case submissionContext = "submission_context"
        case extractionContext = "extraction_context"
        case refreshContext = "refresh_context"
        case migrationContext = "migration_context"
        case sourceDocPath = "source_doc_path"
        case requiresPowerfulDevice = "requires_powerful_device"
    }
}

// MARK: - Computed Properties

extension SupabaseURLQueueItem {

    /// Domain extracted from the URL
    public var domain: String {
        guard let urlObj = URL(string: url), let host = urlObj.host else {
            return url
        }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}

// MARK: - URL Queue Insert Model

/// Write model for inserting new URLs into the queue.
///
/// Only includes fields needed at insertion time.
/// The database provides defaults for other columns.
public struct SupabaseURLQueueInsert: Codable, Sendable {
    public let id: String
    public let url: String
    public let status: String
    public let discoveredFrom: String?
    public let processingMode: String?
    public let submissionContext: [String: String]?
    public let cityName: String?
    public let sourceId: String?
    public let sourceName: String?
    public let category: String?
    public let title: String?

    public init(
        id: String,
        url: String,
        status: String = "pending",
        discoveredFrom: String? = nil,
        processingMode: String? = nil,
        submissionContext: [String: String]? = nil,
        cityName: String? = nil,
        sourceId: String? = nil,
        sourceName: String? = nil,
        category: String? = nil,
        title: String? = nil
    ) {
        self.id = id
        self.url = url
        self.status = status
        self.discoveredFrom = discoveredFrom
        self.processingMode = processingMode
        self.submissionContext = submissionContext
        self.cityName = cityName
        self.sourceId = sourceId
        self.sourceName = sourceName
        self.category = category
        self.title = title
    }

    enum CodingKeys: String, CodingKey {
        case id, url, status, category, title
        case discoveredFrom = "discovered_from"
        case processingMode = "processing_mode"
        case submissionContext = "submission_context"
        case cityName = "city_name"
        case sourceId = "source_id"
        case sourceName = "source_name"
    }
}
