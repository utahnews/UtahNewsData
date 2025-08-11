//
//  V2CoreModels.swift
//  UtahNewsDataModels
//
//  Essential V2 models for lightweight distribution across apps
//  Full V2 models are available in the main UtahNewsData module
//

import Foundation

// MARK: - V2 Enhanced Final Data Payload (Lightweight)

/// Lightweight version of V2FinalDataPayload for app distribution
/// For full V2 features, import UtahNewsData module
public struct V2FinalDataPayloadLite: Codable, Sendable, JSONSchemaProvider {
    // Core fields from V1 compatibility
    public let url: String
    public let processingTimestamp: String
    public let cleanedText: String?
    public let summary: String?
    public let topics: [String]?
    public let sentimentLabel: String?
    public let sentimentScore: Double?
    public let isRelevantToUtah: Bool?
    public let relevanceScore: Double?
    
    // Essential V2 metadata
    public let pipelineVersion: String
    public let pipelineId: String?
    public let processingMethod: String
    public let totalProcessingTimeMs: Int?
    public let tokenReductionPercentage: Double?
    public let costSavingsPercentage: Double?
    
    public init(
        url: String,
        processingTimestamp: String,
        cleanedText: String? = nil,
        summary: String? = nil,
        topics: [String]? = nil,
        sentimentLabel: String? = nil,
        sentimentScore: Double? = nil,
        isRelevantToUtah: Bool? = nil,
        relevanceScore: Double? = nil,
        pipelineVersion: String = "v2",
        pipelineId: String? = nil,
        processingMethod: String = "hybrid",
        totalProcessingTimeMs: Int? = nil,
        tokenReductionPercentage: Double? = nil,
        costSavingsPercentage: Double? = nil
    ) {
        self.url = url
        self.processingTimestamp = processingTimestamp
        self.cleanedText = cleanedText
        self.summary = summary
        self.topics = topics
        self.sentimentLabel = sentimentLabel
        self.sentimentScore = sentimentScore
        self.isRelevantToUtah = isRelevantToUtah
        self.relevanceScore = relevanceScore
        self.pipelineVersion = pipelineVersion
        self.pipelineId = pipelineId
        self.processingMethod = processingMethod
        self.totalProcessingTimeMs = totalProcessingTimeMs
        self.tokenReductionPercentage = tokenReductionPercentage
        self.costSavingsPercentage = costSavingsPercentage
    }
    
    private enum CodingKeys: String, CodingKey {
        case url
        case processingTimestamp = "processing_timestamp"
        case cleanedText = "cleaned_text"
        case summary
        case topics
        case sentimentLabel = "sentiment_label"
        case sentimentScore = "sentiment_score"
        case isRelevantToUtah = "is_relevant_to_utah"
        case relevanceScore = "relevance_score"
        case pipelineVersion = "pipeline_version"
        case pipelineId = "pipeline_id"
        case processingMethod = "processing_method"
        case totalProcessingTimeMs = "total_processing_time_ms"
        case tokenReductionPercentage = "token_reduction_percentage"
        case costSavingsPercentage = "cost_savings_percentage"
    }
    
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "url": {"type": "string"},
                "processing_timestamp": {"type": "string"},
                "cleaned_text": {"type": ["string", "null"]},
                "summary": {"type": ["string", "null"]},
                "topics": {"type": ["array", "null"], "items": {"type": "string"}},
                "sentiment_label": {"type": ["string", "null"]},
                "sentiment_score": {"type": ["number", "null"]},
                "is_relevant_to_utah": {"type": ["boolean", "null"]},
                "relevance_score": {"type": ["number", "null"]},
                "pipeline_version": {"type": "string"},
                "pipeline_id": {"type": ["string", "null"]},
                "processing_method": {"type": "string"},
                "total_processing_time_ms": {"type": ["integer", "null"]},
                "token_reduction_percentage": {"type": ["number", "null"]},
                "cost_savings_percentage": {"type": ["number", "null"]}
            },
            "required": ["url", "processing_timestamp", "pipeline_version", "processing_method"],
            "additionalProperties": false
        }
        """
    }
}

// MARK: - V2 Pipeline Status (Lightweight)

/// Lightweight pipeline execution status for app monitoring
public struct V2PipelineStatusLite: Codable, Sendable, JSONSchemaProvider {
    public let pipelineId: String
    public let url: String
    public let status: V2PipelineExecutionStatus
    public let currentAgent: String?
    public let progress: Double // 0.0 to 1.0
    public let startTime: String
    public let estimatedCompletionTime: String?
    public let tokensUsed: Int?
    public let costUsd: Double?
    public let errorMessage: String?
    
    public init(
        pipelineId: String,
        url: String,
        status: V2PipelineExecutionStatus,
        currentAgent: String? = nil,
        progress: Double = 0.0,
        startTime: String,
        estimatedCompletionTime: String? = nil,
        tokensUsed: Int? = nil,
        costUsd: Double? = nil,
        errorMessage: String? = nil
    ) {
        self.pipelineId = pipelineId
        self.url = url
        self.status = status
        self.currentAgent = currentAgent
        self.progress = progress
        self.startTime = startTime
        self.estimatedCompletionTime = estimatedCompletionTime
        self.tokensUsed = tokensUsed
        self.costUsd = costUsd
        self.errorMessage = errorMessage
    }
    
    private enum CodingKeys: String, CodingKey {
        case pipelineId = "pipeline_id"
        case url
        case status
        case currentAgent = "current_agent"
        case progress
        case startTime = "start_time"
        case estimatedCompletionTime = "estimated_completion_time"
        case tokensUsed = "tokens_used"
        case costUsd = "cost_usd"
        case errorMessage = "error_message"
    }
    
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "pipeline_id": {"type": "string"},
                "url": {"type": "string"},
                "status": {"type": "string", "enum": ["pending", "running", "completed", "failed", "cancelled"]},
                "current_agent": {"type": ["string", "null"]},
                "progress": {"type": "number", "minimum": 0.0, "maximum": 1.0},
                "start_time": {"type": "string"},
                "estimated_completion_time": {"type": ["string", "null"]},
                "tokens_used": {"type": ["integer", "null"]},
                "cost_usd": {"type": ["number", "null"]},
                "error_message": {"type": ["string", "null"]}
            },
            "required": ["pipeline_id", "url", "status", "progress", "start_time"],
            "additionalProperties": false
        }
        """
    }
}

/// Pipeline execution status enumeration
public enum V2PipelineExecutionStatus: String, Codable, CaseIterable, Sendable {
    case pending = "pending"
    case running = "running" 
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
}

// MARK: - V2 Metrics Summary (Lightweight)

/// Essential V2 metrics for app display
public struct V2MetricsSummaryLite: Codable, Sendable, JSONSchemaProvider {
    public let successRate: Double
    public let tokenReductionVsV1: Double
    public let costSavingsVsV1: Double
    public let averageProcessingTimeMs: Double
    public let hybridEfficiencyRatio: Double
    public let totalPipelinesProcessed: Int
    public let timestamp: String
    
    public init(
        successRate: Double,
        tokenReductionVsV1: Double,
        costSavingsVsV1: Double,
        averageProcessingTimeMs: Double,
        hybridEfficiencyRatio: Double,
        totalPipelinesProcessed: Int,
        timestamp: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.successRate = successRate
        self.tokenReductionVsV1 = tokenReductionVsV1
        self.costSavingsVsV1 = costSavingsVsV1
        self.averageProcessingTimeMs = averageProcessingTimeMs
        self.hybridEfficiencyRatio = hybridEfficiencyRatio
        self.totalPipelinesProcessed = totalPipelinesProcessed
        self.timestamp = timestamp
    }
    
    private enum CodingKeys: String, CodingKey {
        case successRate = "success_rate"
        case tokenReductionVsV1 = "token_reduction_vs_v1"
        case costSavingsVsV1 = "cost_savings_vs_v1"
        case averageProcessingTimeMs = "average_processing_time_ms"
        case hybridEfficiencyRatio = "hybrid_efficiency_ratio"
        case totalPipelinesProcessed = "total_pipelines_processed"
        case timestamp
    }
    
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "success_rate": {"type": "number"},
                "token_reduction_vs_v1": {"type": "number"},
                "cost_savings_vs_v1": {"type": "number"},
                "average_processing_time_ms": {"type": "number"},
                "hybrid_efficiency_ratio": {"type": "number"},
                "total_pipelines_processed": {"type": "integer"},
                "timestamp": {"type": "string"}
            },
            "required": ["success_rate", "token_reduction_vs_v1", "cost_savings_vs_v1", "average_processing_time_ms"],
            "additionalProperties": false
        }
        """
    }
}

// MARK: - V2 Agent Information (Lightweight)

/// Basic information about V2 agents for app display
public struct V2AgentInfoLite: Codable, Sendable, Identifiable, JSONSchemaProvider {
    public let id: String
    public let name: String
    public let description: String
    public let version: String
    public let status: V2AgentStatus
    public let capabilities: [String]
    public let averageTokenUsage: Int?
    public let averageProcessingTimeMs: Double?
    public let successRate: Double?
    public let lastUpdated: String
    
    public init(
        id: String,
        name: String,
        description: String,
        version: String,
        status: V2AgentStatus,
        capabilities: [String] = [],
        averageTokenUsage: Int? = nil,
        averageProcessingTimeMs: Double? = nil,
        successRate: Double? = nil,
        lastUpdated: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.version = version
        self.status = status
        self.capabilities = capabilities
        self.averageTokenUsage = averageTokenUsage
        self.averageProcessingTimeMs = averageProcessingTimeMs
        self.successRate = successRate
        self.lastUpdated = lastUpdated
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case version
        case status
        case capabilities
        case averageTokenUsage = "average_token_usage"
        case averageProcessingTimeMs = "average_processing_time_ms"
        case successRate = "success_rate"
        case lastUpdated = "last_updated"
    }
    
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "id": {"type": "string"},
                "name": {"type": "string"},
                "description": {"type": "string"},
                "version": {"type": "string"},
                "status": {"type": "string", "enum": ["active", "inactive", "maintenance", "error"]},
                "capabilities": {"type": "array", "items": {"type": "string"}},
                "average_token_usage": {"type": ["integer", "null"]},
                "average_processing_time_ms": {"type": ["number", "null"]},
                "success_rate": {"type": ["number", "null"]},
                "last_updated": {"type": "string"}
            },
            "required": ["id", "name", "description", "version", "status", "capabilities"],
            "additionalProperties": false
        }
        """
    }
}

/// Agent status enumeration
public enum V2AgentStatus: String, Codable, CaseIterable, Sendable {
    case active = "active"
    case inactive = "inactive"
    case maintenance = "maintenance"
    case error = "error"
}

// MARK: - Utility Extensions

// Date extensions removed - using ISO8601DateFormatter directly for better performance