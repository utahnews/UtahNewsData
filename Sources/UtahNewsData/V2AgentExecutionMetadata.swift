//
//  V2AgentExecutionMetadata.swift
//  UtahNewsData
//
//  Created for V2 Agent Execution Tracking and Metadata
//  Provides detailed execution context and handoff management
//

import Foundation

// MARK: - Pipeline Execution Metadata

/// Comprehensive metadata for V2 pipeline execution tracking
/// Mirrors Python PipelineExecutionMetadata from app/models/metadata_models.py
public struct V2PipelineExecutionMetadata: Codable, Sendable, JSONSchemaProvider {
    public let pipelineId: String
    public let executionId: String
    public let contentId: String?
    public let sourceUrl: String
    public let pipelineVersion: String
    public let startTime: String
    public var endTime: String?
    public var currentAgent: String
    public var agentsCompleted: [String]
    public var agentsFailed: [String]
    public var processingTimeMs: Int?
    public var hasErrors: Bool
    public var errorMessages: [String]
    public var executionContext: [String: String]
    public var checkpoints: [V2ExecutionCheckpoint]
    
    public init(
        pipelineId: String,
        executionId: String = UUID().uuidString,
        contentId: String? = nil,
        sourceUrl: String,
        pipelineVersion: String = "v2",
        startTime: String = ISO8601DateFormatter().string(from: Date()),
        endTime: String? = nil,
        currentAgent: String = "",
        agentsCompleted: [String] = [],
        agentsFailed: [String] = [],
        processingTimeMs: Int? = nil,
        hasErrors: Bool = false,
        errorMessages: [String] = [],
        executionContext: [String: String] = [:],
        checkpoints: [V2ExecutionCheckpoint] = []
    ) {
        self.pipelineId = pipelineId
        self.executionId = executionId
        self.contentId = contentId
        self.sourceUrl = sourceUrl
        self.pipelineVersion = pipelineVersion
        self.startTime = startTime
        self.endTime = endTime
        self.currentAgent = currentAgent
        self.agentsCompleted = agentsCompleted
        self.agentsFailed = agentsFailed
        self.processingTimeMs = processingTimeMs
        self.hasErrors = hasErrors
        self.errorMessages = errorMessages
        self.executionContext = executionContext
        self.checkpoints = checkpoints
    }
    
    private enum CodingKeys: String, CodingKey {
        case pipelineId = "pipeline_id"
        case executionId = "execution_id"
        case contentId = "content_id"
        case sourceUrl = "source_url"
        case pipelineVersion = "pipeline_version"
        case startTime = "start_time"
        case endTime = "end_time"
        case currentAgent = "current_agent"
        case agentsCompleted = "agents_completed"
        case agentsFailed = "agents_failed"
        case processingTimeMs = "processing_time_ms"
        case hasErrors = "has_errors"
        case errorMessages = "error_messages"
        case executionContext = "execution_context"
        case checkpoints
    }
    
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "pipeline_id": {"type": "string"},
                "execution_id": {"type": "string"},
                "content_id": {"type": ["string", "null"]},
                "source_url": {"type": "string"},
                "pipeline_version": {"type": "string"},
                "start_time": {"type": "string"},
                "end_time": {"type": ["string", "null"]},
                "current_agent": {"type": "string"},
                "agents_completed": {"type": "array", "items": {"type": "string"}},
                "agents_failed": {"type": "array", "items": {"type": "string"}},
                "processing_time_ms": {"type": ["integer", "null"]},
                "has_errors": {"type": "boolean"},
                "error_messages": {"type": "array", "items": {"type": "string"}},
                "execution_context": {"type": "object", "additionalProperties": {"type": "string"}},
                "checkpoints": {"type": "array", "items": {"$ref": "#/definitions/V2ExecutionCheckpoint"}}
            },
            "required": ["pipeline_id", "execution_id", "source_url", "pipeline_version", "start_time"],
            "additionalProperties": false
        }
        """
    }
}

/// Execution checkpoint for tracking progress through the pipeline
public struct V2ExecutionCheckpoint: Codable, Sendable, Identifiable {
    public let id: String
    public let agentId: String
    public let agentName: String
    public let checkpoint: String
    public let timestamp: String
    public let status: V2CheckpointStatus
    public let metadata: [String: String]?
    public let duration: TimeInterval?
    public let memorySnapshot: V2MemorySnapshot?
    
    public init(
        id: String = UUID().uuidString,
        agentId: String,
        agentName: String,
        checkpoint: String,
        timestamp: String = ISO8601DateFormatter().string(from: Date()),
        status: V2CheckpointStatus,
        metadata: [String: String]? = nil,
        duration: TimeInterval? = nil,
        memorySnapshot: V2MemorySnapshot? = nil
    ) {
        self.id = id
        self.agentId = agentId
        self.agentName = agentName
        self.checkpoint = checkpoint
        self.timestamp = timestamp
        self.status = status
        self.metadata = metadata
        self.duration = duration
        self.memorySnapshot = memorySnapshot
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case agentId = "agent_id"
        case agentName = "agent_name"
        case checkpoint
        case timestamp
        case status
        case metadata
        case duration
        case memorySnapshot = "memory_snapshot"
    }
}

/// Status of an execution checkpoint
public enum V2CheckpointStatus: String, Codable, CaseIterable, Sendable {
    case started = "started"
    case inProgress = "in_progress"
    case completed = "completed"
    case failed = "failed"
    case skipped = "skipped"
    case retrying = "retrying"
}

/// Memory usage snapshot at checkpoint
public struct V2MemorySnapshot: Codable, Sendable {
    public let usedMemoryMb: Double
    public let availableMemoryMb: Double
    public let memoryPressure: String
    public let gcCount: Int?
    
    public init(
        usedMemoryMb: Double,
        availableMemoryMb: Double,
        memoryPressure: String,
        gcCount: Int? = nil
    ) {
        self.usedMemoryMb = usedMemoryMb
        self.availableMemoryMb = availableMemoryMb
        self.memoryPressure = memoryPressure
        self.gcCount = gcCount
    }
    
    private enum CodingKeys: String, CodingKey {
        case usedMemoryMb = "used_memory_mb"
        case availableMemoryMb = "available_memory_mb"
        case memoryPressure = "memory_pressure"
        case gcCount = "gc_count"
    }
}

// MARK: - Agent Handoff Tracking

/// Detailed tracking of agent-to-agent handoffs in the V2 pipeline
public struct V2AgentHandoffRecord: Codable, Sendable, Identifiable {
    public let id: String
    public let pipelineId: String
    public let fromAgent: String
    public let toAgent: String
    public let handoffType: V2HandoffType
    public let timestamp: String
    public let dataSize: Int?
    public let transformationApplied: String?
    public let validationResults: V2HandoffValidationRecord?
    public let performance: V2HandoffPerformance?
    public let metadata: [String: String]?
    
    public init(
        id: String = UUID().uuidString,
        pipelineId: String,
        fromAgent: String,
        toAgent: String,
        handoffType: V2HandoffType,
        timestamp: String = ISO8601DateFormatter().string(from: Date()),
        dataSize: Int? = nil,
        transformationApplied: String? = nil,
        validationResults: V2HandoffValidationRecord? = nil,
        performance: V2HandoffPerformance? = nil,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.pipelineId = pipelineId
        self.fromAgent = fromAgent
        self.toAgent = toAgent
        self.handoffType = handoffType
        self.timestamp = timestamp
        self.dataSize = dataSize
        self.transformationApplied = transformationApplied
        self.validationResults = validationResults
        self.performance = performance
        self.metadata = metadata
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case pipelineId = "pipeline_id"
        case fromAgent = "from_agent"
        case toAgent = "to_agent"
        case handoffType = "handoff_type"
        case timestamp
        case dataSize = "data_size"
        case transformationApplied = "transformation_applied"
        case validationResults = "validation_results"
        case performance
        case metadata
    }
}

/// Type of handoff between agents
public enum V2HandoffType: String, Codable, CaseIterable, Sendable {
    case directPass = "direct_pass"
    case dataTransformation = "data_transformation"
    case conditionalBranch = "conditional_branch"
    case errorRecovery = "error_recovery"
    case skipAgent = "skip_agent"
    case retryAgent = "retry_agent"
}

/// Validation record for handoff data
public struct V2HandoffValidationRecord: Codable, Sendable {
    public let isValid: Bool
    public let validationScore: Double
    public let dataQualityMetrics: V2DataQualityMetrics?
    public let schemaCompliance: Bool
    public let warnings: [String]
    public let errors: [String]
    
    public init(
        isValid: Bool,
        validationScore: Double,
        dataQualityMetrics: V2DataQualityMetrics? = nil,
        schemaCompliance: Bool,
        warnings: [String] = [],
        errors: [String] = []
    ) {
        self.isValid = isValid
        self.validationScore = validationScore
        self.dataQualityMetrics = dataQualityMetrics
        self.schemaCompliance = schemaCompliance
        self.warnings = warnings
        self.errors = errors
    }
    
    private enum CodingKeys: String, CodingKey {
        case isValid = "is_valid"
        case validationScore = "validation_score"
        case dataQualityMetrics = "data_quality_metrics"
        case schemaCompliance = "schema_compliance"
        case warnings
        case errors
    }
}

/// Data quality metrics for validation
public struct V2DataQualityMetrics: Codable, Sendable {
    public let completeness: Double // 0.0 to 1.0
    public let accuracy: Double // 0.0 to 1.0
    public let consistency: Double // 0.0 to 1.0
    public let timeliness: Double // 0.0 to 1.0
    public let relevance: Double // 0.0 to 1.0
    public let overallScore: Double // 0.0 to 1.0
    
    public init(
        completeness: Double,
        accuracy: Double,
        consistency: Double,
        timeliness: Double,
        relevance: Double,
        overallScore: Double
    ) {
        self.completeness = completeness
        self.accuracy = accuracy
        self.consistency = consistency
        self.timeliness = timeliness
        self.relevance = relevance
        self.overallScore = overallScore
    }
    
    private enum CodingKeys: String, CodingKey {
        case completeness
        case accuracy
        case consistency
        case timeliness
        case relevance
        case overallScore = "overall_score"
    }
}

/// Performance metrics for handoffs
public struct V2HandoffPerformance: Codable, Sendable {
    public let serializationTimeMs: Double
    public let deserializationTimeMs: Double
    public let validationTimeMs: Double
    public let transformationTimeMs: Double?
    public let totalHandoffTimeMs: Double
    public let memoryUsageMb: Double
    
    public init(
        serializationTimeMs: Double,
        deserializationTimeMs: Double,
        validationTimeMs: Double,
        transformationTimeMs: Double? = nil,
        totalHandoffTimeMs: Double,
        memoryUsageMb: Double
    ) {
        self.serializationTimeMs = serializationTimeMs
        self.deserializationTimeMs = deserializationTimeMs
        self.validationTimeMs = validationTimeMs
        self.transformationTimeMs = transformationTimeMs
        self.totalHandoffTimeMs = totalHandoffTimeMs
        self.memoryUsageMb = memoryUsageMb
    }
    
    private enum CodingKeys: String, CodingKey {
        case serializationTimeMs = "serialization_time_ms"
        case deserializationTimeMs = "deserialization_time_ms"
        case validationTimeMs = "validation_time_ms"
        case transformationTimeMs = "transformation_time_ms"
        case totalHandoffTimeMs = "total_handoff_time_ms"
        case memoryUsageMb = "memory_usage_mb"
    }
}

// MARK: - Agent Performance Tracking

/// Detailed performance tracking for individual agents
public struct V2AgentPerformanceRecord: Codable, Sendable, Identifiable, JSONSchemaProvider {
    public let id: String
    public let pipelineId: String
    public let agentId: String
    public let agentName: String
    public let agentVersion: String
    public let executionStartTime: String
    public let executionEndTime: String
    public let executionDurationMs: Int
    public let tokenUsage: V2AgentTokenUsage
    public let cost: V2AgentCost
    public let resourceUsage: V2AgentResourceUsage
    public let qualityMetrics: V2AgentQualityMetrics?
    public let toolsInvoked: [V2ToolInvocationRecord]
    public let errors: [V2AgentError]
    
    public init(
        id: String = UUID().uuidString,
        pipelineId: String,
        agentId: String,
        agentName: String,
        agentVersion: String,
        executionStartTime: String,
        executionEndTime: String,
        executionDurationMs: Int,
        tokenUsage: V2AgentTokenUsage,
        cost: V2AgentCost,
        resourceUsage: V2AgentResourceUsage,
        qualityMetrics: V2AgentQualityMetrics? = nil,
        toolsInvoked: [V2ToolInvocationRecord] = [],
        errors: [V2AgentError] = []
    ) {
        self.id = id
        self.pipelineId = pipelineId
        self.agentId = agentId
        self.agentName = agentName
        self.agentVersion = agentVersion
        self.executionStartTime = executionStartTime
        self.executionEndTime = executionEndTime
        self.executionDurationMs = executionDurationMs
        self.tokenUsage = tokenUsage
        self.cost = cost
        self.resourceUsage = resourceUsage
        self.qualityMetrics = qualityMetrics
        self.toolsInvoked = toolsInvoked
        self.errors = errors
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case pipelineId = "pipeline_id"
        case agentId = "agent_id"
        case agentName = "agent_name"
        case agentVersion = "agent_version"
        case executionStartTime = "execution_start_time"
        case executionEndTime = "execution_end_time"
        case executionDurationMs = "execution_duration_ms"
        case tokenUsage = "token_usage"
        case cost
        case resourceUsage = "resource_usage"
        case qualityMetrics = "quality_metrics"
        case toolsInvoked = "tools_invoked"
        case errors
    }
    
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "id": {"type": "string"},
                "pipeline_id": {"type": "string"},
                "agent_id": {"type": "string"},
                "agent_name": {"type": "string"},
                "agent_version": {"type": "string"},
                "execution_start_time": {"type": "string"},
                "execution_end_time": {"type": "string"},
                "execution_duration_ms": {"type": "integer"},
                "token_usage": {"$ref": "#/definitions/V2AgentTokenUsage"},
                "cost": {"$ref": "#/definitions/V2AgentCost"},
                "resource_usage": {"$ref": "#/definitions/V2AgentResourceUsage"},
                "quality_metrics": {"$ref": "#/definitions/V2AgentQualityMetrics"},
                "tools_invoked": {"type": "array", "items": {"$ref": "#/definitions/V2ToolInvocationRecord"}},
                "errors": {"type": "array", "items": {"$ref": "#/definitions/V2AgentError"}}
            },
            "required": ["id", "pipeline_id", "agent_id", "agent_name", "execution_start_time", "execution_end_time", "execution_duration_ms"],
            "additionalProperties": false
        }
        """
    }
}

/// Resource usage tracking for agents
public struct V2AgentResourceUsage: Codable, Sendable {
    public let peakMemoryUsageMb: Double
    public let averageMemoryUsageMb: Double
    public let cpuTimeMs: Double
    public let cpuUtilizationPercent: Double
    public let networkBytesIn: Int
    public let networkBytesOut: Int
    public let diskReadsBytes: Int?
    public let diskWritesBytes: Int?
    
    public init(
        peakMemoryUsageMb: Double,
        averageMemoryUsageMb: Double,
        cpuTimeMs: Double,
        cpuUtilizationPercent: Double,
        networkBytesIn: Int,
        networkBytesOut: Int,
        diskReadsBytes: Int? = nil,
        diskWritesBytes: Int? = nil
    ) {
        self.peakMemoryUsageMb = peakMemoryUsageMb
        self.averageMemoryUsageMb = averageMemoryUsageMb
        self.cpuTimeMs = cpuTimeMs
        self.cpuUtilizationPercent = cpuUtilizationPercent
        self.networkBytesIn = networkBytesIn
        self.networkBytesOut = networkBytesOut
        self.diskReadsBytes = diskReadsBytes
        self.diskWritesBytes = diskWritesBytes
    }
    
    private enum CodingKeys: String, CodingKey {
        case peakMemoryUsageMb = "peak_memory_usage_mb"
        case averageMemoryUsageMb = "average_memory_usage_mb"
        case cpuTimeMs = "cpu_time_ms"
        case cpuUtilizationPercent = "cpu_utilization_percent"
        case networkBytesIn = "network_bytes_in"
        case networkBytesOut = "network_bytes_out"
        case diskReadsBytes = "disk_reads_bytes"
        case diskWritesBytes = "disk_writes_bytes"
    }
}

/// Quality metrics for agent output
public struct V2AgentQualityMetrics: Codable, Sendable {
    public let outputCompleteness: Double
    public let outputAccuracy: Double
    public let outputRelevance: Double
    public let outputConsistency: Double
    public let processingEfficiency: Double
    public let errorRate: Double
    public let overallQualityScore: Double
    
    public init(
        outputCompleteness: Double,
        outputAccuracy: Double,
        outputRelevance: Double,
        outputConsistency: Double,
        processingEfficiency: Double,
        errorRate: Double,
        overallQualityScore: Double
    ) {
        self.outputCompleteness = outputCompleteness
        self.outputAccuracy = outputAccuracy
        self.outputRelevance = outputRelevance
        self.outputConsistency = outputConsistency
        self.processingEfficiency = processingEfficiency
        self.errorRate = errorRate
        self.overallQualityScore = overallQualityScore
    }
    
    private enum CodingKeys: String, CodingKey {
        case outputCompleteness = "output_completeness"
        case outputAccuracy = "output_accuracy"
        case outputRelevance = "output_relevance"
        case outputConsistency = "output_consistency"
        case processingEfficiency = "processing_efficiency"
        case errorRate = "error_rate"
        case overallQualityScore = "overall_quality_score"
    }
}

/// Tool invocation record for tracking agent tool usage
public struct V2ToolInvocationRecord: Codable, Sendable, Identifiable {
    public let id: String
    public let toolName: String
    public let invocationTime: String
    public let executionDurationMs: Int
    public let inputSize: Int?
    public let outputSize: Int?
    public let success: Bool
    public let errorMessage: String?
    public let tokenUsage: Int?
    public let cost: Double?
    
    public init(
        id: String = UUID().uuidString,
        toolName: String,
        invocationTime: String = ISO8601DateFormatter().string(from: Date()),
        executionDurationMs: Int,
        inputSize: Int? = nil,
        outputSize: Int? = nil,
        success: Bool,
        errorMessage: String? = nil,
        tokenUsage: Int? = nil,
        cost: Double? = nil
    ) {
        self.id = id
        self.toolName = toolName
        self.invocationTime = invocationTime
        self.executionDurationMs = executionDurationMs
        self.inputSize = inputSize
        self.outputSize = outputSize
        self.success = success
        self.errorMessage = errorMessage
        self.tokenUsage = tokenUsage
        self.cost = cost
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case toolName = "tool_name"
        case invocationTime = "invocation_time"
        case executionDurationMs = "execution_duration_ms"
        case inputSize = "input_size"
        case outputSize = "output_size"
        case success
        case errorMessage = "error_message"
        case tokenUsage = "token_usage"
        case cost
    }
}

// MARK: - Content Reference Tracking

/// Reference to content stored in the metadata service
/// Mirrors Python ContentReference from app/models/metadata_models.py
public struct V2ContentReference: Codable, Sendable, JSONSchemaProvider {
    public let contentId: String
    public let url: String
    public let contentType: String?
    public let storageLocation: String?
    public let storedAt: String
    public let expiresAt: String?
    public let metadata: [String: String]?
    public let checksum: String?
    public let sizeBytes: Int?
    
    public init(
        contentId: String,
        url: String,
        contentType: String? = nil,
        storageLocation: String? = nil,
        storedAt: String = ISO8601DateFormatter().string(from: Date()),
        expiresAt: String? = nil,
        metadata: [String: String]? = nil,
        checksum: String? = nil,
        sizeBytes: Int? = nil
    ) {
        self.contentId = contentId
        self.url = url
        self.contentType = contentType
        self.storageLocation = storageLocation
        self.storedAt = storedAt
        self.expiresAt = expiresAt
        self.metadata = metadata
        self.checksum = checksum
        self.sizeBytes = sizeBytes
    }
    
    private enum CodingKeys: String, CodingKey {
        case contentId = "content_id"
        case url
        case contentType = "content_type"
        case storageLocation = "storage_location"
        case storedAt = "stored_at"
        case expiresAt = "expires_at"
        case metadata
        case checksum
        case sizeBytes = "size_bytes"
    }
    
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "content_id": {"type": "string"},
                "url": {"type": "string"},
                "content_type": {"type": ["string", "null"]},
                "storage_location": {"type": ["string", "null"]},
                "stored_at": {"type": "string"},
                "expires_at": {"type": ["string", "null"]},
                "metadata": {"type": ["object", "null"], "additionalProperties": {"type": "string"}},
                "checksum": {"type": ["string", "null"]},
                "size_bytes": {"type": ["integer", "null"]}
            },
            "required": ["content_id", "url", "stored_at"],
            "additionalProperties": false
        }
        """
    }
}

// MARK: - Utility Extensions

private extension Date {
    func toISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}

// MARK: - Extension for Pipeline Metadata

extension V2PipelineExecutionMetadata {
    /// Add a checkpoint to the execution metadata
    public mutating func addCheckpoint(
        agentId: String,
        agentName: String,
        checkpoint: String,
        status: V2CheckpointStatus,
        metadata: [String: String]? = nil,
        duration: TimeInterval? = nil,
        memorySnapshot: V2MemorySnapshot? = nil
    ) {
        let checkpointRecord = V2ExecutionCheckpoint(
            agentId: agentId,
            agentName: agentName,
            checkpoint: checkpoint,
            status: status,
            metadata: metadata,
            duration: duration,
            memorySnapshot: memorySnapshot
        )
        self.checkpoints.append(checkpointRecord)
    }
    
    /// Mark an agent as completed
    public mutating func completeAgent(_ agentId: String) {
        if !agentsCompleted.contains(agentId) {
            agentsCompleted.append(agentId)
        }
    }
    
    /// Mark an agent as failed
    public mutating func failAgent(_ agentId: String, error: String) {
        if !agentsFailed.contains(agentId) {
            agentsFailed.append(agentId)
        }
        hasErrors = true
        errorMessages.append(error)
    }
    
    /// Get execution progress as percentage
    public var progressPercentage: Double {
        let totalAgents = 10 // Agents 0-9 (skipping 4)
        return Double(agentsCompleted.count) / Double(totalAgents)
    }
}