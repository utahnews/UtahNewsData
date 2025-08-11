//
//  AgentCommunicationProtocols.swift
//  UtahNewsData
//
//  Created for V2 Agent Communication Layer
//  Defines base protocols and communication patterns for agent handoffs
//

import Foundation

// MARK: - Core Agent Communication Protocols

/// Base protocol for all V2 agent inputs
/// Ensures consistent input structure across the pipeline
public protocol V2AgentInput: V2StrictModel {
    /// Unique identifier for this input instance
    var inputId: String { get }
    
    /// Timestamp when this input was created
    var createdAt: Date { get }
    
    /// Optional metadata for pipeline tracking
    var pipelineMetadata: [String: String]? { get }
}

/// Base protocol for all V2 agent outputs
/// Provides consistent output structure and validation
public protocol V2AgentOutput: V2StrictModel {
    /// Status of agent execution
    var executionStatus: V2AgentExecutionStatus { get }
    
    /// Processing time in milliseconds
    var processingTimeMs: Int { get }
    
    /// Any errors encountered during processing
    var errors: [V2AgentError]? { get }
    
    /// Metadata about the agent execution
    var executionMetadata: V2AgentExecutionMetadata? { get }
}

// MARK: - Agent Execution Status

/// Status of agent execution in the V2 pipeline
public enum V2AgentExecutionStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    case failed = "failed"
    case skipped = "skipped"
    case retrying = "retrying"
}

// MARK: - Agent Error Handling

/// Structured error information for agent failures
public struct V2AgentError: Codable, Sendable {
    public let errorType: V2AgentErrorType
    public let message: String
    public let details: [String: String]?
    public let recoverable: Bool
    public let retryCount: Int
    public let timestamp: String
    
    public init(
        errorType: V2AgentErrorType,
        message: String,
        details: [String: String]? = nil,
        recoverable: Bool = false,
        retryCount: Int = 0,
        timestamp: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.errorType = errorType
        self.message = message
        self.details = details
        self.recoverable = recoverable
        self.retryCount = retryCount
        self.timestamp = timestamp
    }
    
    private enum CodingKeys: String, CodingKey {
        case errorType = "error_type"
        case message
        case details
        case recoverable
        case retryCount = "retry_count"
        case timestamp
    }
}

/// Categories of errors that can occur in agent processing
public enum V2AgentErrorType: String, Codable, CaseIterable, Sendable {
    // Network and connectivity errors
    case networkError = "network_error"
    case timeoutError = "timeout_error"
    case connectionError = "connection_error"
    
    // Data and parsing errors
    case invalidInput = "invalid_input"
    case parsingError = "parsing_error"
    case validationError = "validation_error"
    
    // Processing errors
    case processingError = "processing_error"
    case insufficientData = "insufficient_data"
    case contentBlocked = "content_blocked"
    
    // System and resource errors
    case resourceUnavailable = "resource_unavailable"
    case quotaExceeded = "quota_exceeded"
    case systemError = "system_error"
    
    // Agent-specific errors
    case agentConfigurationError = "agent_configuration_error"
    case toolExecutionError = "tool_execution_error"
    case handoffError = "handoff_error"
}

// MARK: - Agent Execution Metadata

/// Detailed metadata about agent execution for monitoring and debugging
public struct V2AgentExecutionMetadata: Codable, Sendable {
    public let agentId: String
    public let agentVersion: String
    public let startTime: String
    public let endTime: String?
    public let toolsUsed: [String]
    public let tokenUsage: V2AgentTokenUsage?
    public let cost: V2AgentCost?
    public let performanceMetrics: V2AgentPerformanceMetrics?
    public let environment: [String: String]?
    
    public init(
        agentId: String,
        agentVersion: String,
        startTime: String,
        endTime: String? = nil,
        toolsUsed: [String] = [],
        tokenUsage: V2AgentTokenUsage? = nil,
        cost: V2AgentCost? = nil,
        performanceMetrics: V2AgentPerformanceMetrics? = nil,
        environment: [String: String]? = nil
    ) {
        self.agentId = agentId
        self.agentVersion = agentVersion
        self.startTime = startTime
        self.endTime = endTime
        self.toolsUsed = toolsUsed
        self.tokenUsage = tokenUsage
        self.cost = cost
        self.performanceMetrics = performanceMetrics
        self.environment = environment
    }
    
    private enum CodingKeys: String, CodingKey {
        case agentId = "agent_id"
        case agentVersion = "agent_version"
        case startTime = "start_time"
        case endTime = "end_time"
        case toolsUsed = "tools_used"
        case tokenUsage = "token_usage"
        case cost
        case performanceMetrics = "performance_metrics"
        case environment
    }
}

/// Token usage tracking per agent
public struct V2AgentTokenUsage: Codable, Sendable {
    public let orchestrationTokens: Int
    public let localLlmTokens: Int
    public let totalTokens: Int
    public let tokenBreakdown: [String: Int]?
    
    public init(
        orchestrationTokens: Int,
        localLlmTokens: Int,
        totalTokens: Int,
        tokenBreakdown: [String: Int]? = nil
    ) {
        self.orchestrationTokens = orchestrationTokens
        self.localLlmTokens = localLlmTokens
        self.totalTokens = totalTokens
        self.tokenBreakdown = tokenBreakdown
    }
    
    private enum CodingKeys: String, CodingKey {
        case orchestrationTokens = "orchestration_tokens"
        case localLlmTokens = "local_llm_tokens"
        case totalTokens = "total_tokens"
        case tokenBreakdown = "token_breakdown"
    }
}

/// Cost tracking per agent
public struct V2AgentCost: Codable, Sendable {
    public let orchestrationCostUsd: Double
    public let localLlmCostUsd: Double
    public let totalCostUsd: Double
    public let v1EstimatedCostUsd: Double?
    public let savingsPercentage: Double?
    
    public init(
        orchestrationCostUsd: Double,
        localLlmCostUsd: Double,
        totalCostUsd: Double,
        v1EstimatedCostUsd: Double? = nil,
        savingsPercentage: Double? = nil
    ) {
        self.orchestrationCostUsd = orchestrationCostUsd
        self.localLlmCostUsd = localLlmCostUsd
        self.totalCostUsd = totalCostUsd
        self.v1EstimatedCostUsd = v1EstimatedCostUsd
        self.savingsPercentage = savingsPercentage
    }
    
    private enum CodingKeys: String, CodingKey {
        case orchestrationCostUsd = "orchestration_cost_usd"
        case localLlmCostUsd = "local_llm_cost_usd"
        case totalCostUsd = "total_cost_usd"
        case v1EstimatedCostUsd = "v1_estimated_cost_usd"
        case savingsPercentage = "savings_percentage"
    }
}

/// Performance metrics per agent
public struct V2AgentPerformanceMetrics: Codable, Sendable {
    public let cpuUsagePercent: Double?
    public let memoryUsageMb: Double?
    public let networkLatencyMs: Double?
    public let dataQualityScore: Double?
    public let throughputItemsPerSecond: Double?
    
    public init(
        cpuUsagePercent: Double? = nil,
        memoryUsageMb: Double? = nil,
        networkLatencyMs: Double? = nil,
        dataQualityScore: Double? = nil,
        throughputItemsPerSecond: Double? = nil
    ) {
        self.cpuUsagePercent = cpuUsagePercent
        self.memoryUsageMb = memoryUsageMb
        self.networkLatencyMs = networkLatencyMs
        self.dataQualityScore = dataQualityScore
        self.throughputItemsPerSecond = throughputItemsPerSecond
    }
    
    private enum CodingKeys: String, CodingKey {
        case cpuUsagePercent = "cpu_usage_percent"
        case memoryUsageMb = "memory_usage_mb"
        case networkLatencyMs = "network_latency_ms"
        case dataQualityScore = "data_quality_score"
        case throughputItemsPerSecond = "throughput_items_per_second"
    }
}

// MARK: - Agent Handoff Protocol

/// Protocol for managing agent-to-agent handoffs in the V2 pipeline
public protocol V2AgentHandoffManager {
    /// Validate that input from previous agent is compatible
    func validateHandoff<T: V2AgentInput>(from previousOutput: any V2AgentOutput, to nextInput: T) -> V2HandoffValidationResult
    
    /// Transform output from one agent to input for the next
    func transformForHandoff<T: V2AgentOutput, U: V2AgentInput>(output: T) -> U?
    
    /// Record handoff metadata for monitoring
    func recordHandoff(from: String, to: String, metadata: [String: Any])
}

/// Result of validating an agent handoff
public struct V2HandoffValidationResult: Codable, Sendable {
    public let isValid: Bool
    public let errors: [String]
    public let warnings: [String]
    public let recommendations: [String]
    
    public init(isValid: Bool, errors: [String] = [], warnings: [String] = [], recommendations: [String] = []) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
        self.recommendations = recommendations
    }
}

// MARK: - Pipeline Execution Context

/// Context shared across all agents in a V2 pipeline execution
public struct V2PipelineExecutionContext: Codable, Sendable {
    public let pipelineId: String
    public let executionId: String
    public let sourceUrl: String
    public let startTime: String
    public var currentAgent: String
    public var agentsCompleted: [String]
    public var agentsFailed: [String]
    public var totalTokensUsed: Int
    public var totalCostUsd: Double
    public var metadata: [String: String]
    
    public init(
        pipelineId: String,
        executionId: String,
        sourceUrl: String,
        startTime: String,
        currentAgent: String = "",
        agentsCompleted: [String] = [],
        agentsFailed: [String] = [],
        totalTokensUsed: Int = 0,
        totalCostUsd: Double = 0.0,
        metadata: [String: String] = [:]
    ) {
        self.pipelineId = pipelineId
        self.executionId = executionId
        self.sourceUrl = sourceUrl
        self.startTime = startTime
        self.currentAgent = currentAgent
        self.agentsCompleted = agentsCompleted
        self.agentsFailed = agentsFailed
        self.totalTokensUsed = totalTokensUsed
        self.totalCostUsd = totalCostUsd
        self.metadata = metadata
    }
    
    private enum CodingKeys: String, CodingKey {
        case pipelineId = "pipeline_id"
        case executionId = "execution_id"
        case sourceUrl = "source_url"
        case startTime = "start_time"
        case currentAgent = "current_agent"
        case agentsCompleted = "agents_completed"
        case agentsFailed = "agents_failed"
        case totalTokensUsed = "total_tokens_used"
        case totalCostUsd = "total_cost_usd"
        case metadata
    }
}

// MARK: - Agent Communication Events

/// Events that can be emitted during agent communication for monitoring
public enum V2AgentCommunicationEvent: Codable, Sendable {
    case agentStarted(agentId: String, timestamp: String)
    case agentCompleted(agentId: String, duration: TimeInterval, timestamp: String)
    case agentFailed(agentId: String, error: V2AgentError, timestamp: String)
    case handoffInitiated(from: String, to: String, timestamp: String)
    case handoffCompleted(from: String, to: String, timestamp: String)
    case pipelineCompleted(pipelineId: String, totalDuration: TimeInterval, timestamp: String)
    case pipelineFailed(pipelineId: String, error: V2AgentError, timestamp: String)
    
    public var eventType: String {
        switch self {
        case .agentStarted: return "agent_started"
        case .agentCompleted: return "agent_completed"
        case .agentFailed: return "agent_failed"
        case .handoffInitiated: return "handoff_initiated"
        case .handoffCompleted: return "handoff_completed"
        case .pipelineCompleted: return "pipeline_completed"
        case .pipelineFailed: return "pipeline_failed"
        }
    }
    
    public var timestamp: String {
        switch self {
        case .agentStarted(_, let timestamp): return timestamp
        case .agentCompleted(_, _, let timestamp): return timestamp
        case .agentFailed(_, _, let timestamp): return timestamp
        case .handoffInitiated(_, _, let timestamp): return timestamp
        case .handoffCompleted(_, _, let timestamp): return timestamp
        case .pipelineCompleted(_, _, let timestamp): return timestamp
        case .pipelineFailed(_, _, let timestamp): return timestamp
        }
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

// MARK: - Default Implementations

extension V2AgentInput {
    public var inputId: String {
        return UUID().uuidString
    }
    
    public var createdAt: Date {
        return Date()
    }
    
    public var pipelineMetadata: [String: String]? {
        return nil
    }
}

extension V2AgentOutput {
    public var errors: [V2AgentError]? {
        return nil
    }
    
    public var executionMetadata: V2AgentExecutionMetadata? {
        return nil
    }
}