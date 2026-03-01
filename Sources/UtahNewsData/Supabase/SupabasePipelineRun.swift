//
//  SupabasePipelineRun.swift
//  UtahNewsData
//
//  Pipeline execution audit trail with AI cost tracking.
//  Maps to the `pipeline.pipeline_runs` table.
//

import Foundation

// MARK: - Read Model

/// A single pipeline execution record for observability and cost tracking.
nonisolated public struct SupabasePipelineRun: Codable, Sendable, Identifiable {
    public let id: String
    public var articleId: String?
    public var url: String?
    public let stage: String
    public var status: String
    public let startedAt: Date
    public var completedAt: Date?
    public var durationMs: Int?
    public var aiProvider: String?
    public var aiModel: String?
    public var tokensUsed: Int?
    public var errorMessage: String?
    public var errorCode: String?
    public var metadata: [String: String]?
    public var instanceId: String?
    public let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, url, stage, status, metadata
        case articleId = "article_id"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case durationMs = "duration_ms"
        case aiProvider = "ai_provider"
        case aiModel = "ai_model"
        case tokensUsed = "tokens_used"
        case errorMessage = "error_message"
        case errorCode = "error_code"
        case instanceId = "instance_id"
        case createdAt = "created_at"
    }
}

// MARK: - Insert Model

/// Lightweight insert model for creating pipeline run records.
nonisolated public struct SupabasePipelineRunInsert: Codable, Sendable {
    public let stage: String
    public let status: String
    public var articleId: String?
    public var url: String?
    public var completedAt: Date?
    public var durationMs: Int?
    public var aiProvider: String?
    public var aiModel: String?
    public var tokensUsed: Int?
    public var errorMessage: String?
    public var errorCode: String?
    public var instanceId: String?

    public init(
        stage: String,
        status: String = "started",
        articleId: String? = nil,
        url: String? = nil,
        completedAt: Date? = nil,
        durationMs: Int? = nil,
        aiProvider: String? = nil,
        aiModel: String? = nil,
        tokensUsed: Int? = nil,
        errorMessage: String? = nil,
        errorCode: String? = nil,
        instanceId: String? = nil
    ) {
        self.stage = stage
        self.status = status
        self.articleId = articleId
        self.url = url
        self.completedAt = completedAt
        self.durationMs = durationMs
        self.aiProvider = aiProvider
        self.aiModel = aiModel
        self.tokensUsed = tokensUsed
        self.errorMessage = errorMessage
        self.errorCode = errorCode
        self.instanceId = instanceId
    }

    enum CodingKeys: String, CodingKey {
        case stage, status, url
        case articleId = "article_id"
        case completedAt = "completed_at"
        case durationMs = "duration_ms"
        case aiProvider = "ai_provider"
        case aiModel = "ai_model"
        case tokensUsed = "tokens_used"
        case errorMessage = "error_message"
        case errorCode = "error_code"
        case instanceId = "instance_id"
    }
}

// MARK: - Stage Constants

extension SupabasePipelineRunInsert {
    /// Well-known pipeline stage names
    nonisolated public enum Stage {
        public static let urlNormalization = "url_normalization"
        public static let contentExtraction = "content_extraction"
        public static let aiCategorization = "ai_categorization"
        public static let entityExtraction = "entity_extraction"
        public static let sentimentAnalysis = "sentiment_analysis"
        public static let geographicTagging = "geographic_tagging"
        public static let sourceCredibility = "source_credibility"
        public static let editorialScoring = "editorial_scoring"
        public static let corroboration = "corroboration"
        public static let articleGeneration = "article_generation"
    }

    /// Well-known status values
    nonisolated public enum Status {
        public static let started = "started"
        public static let completed = "completed"
        public static let failed = "failed"
        public static let skipped = "skipped"
    }
}
