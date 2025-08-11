//
//  V2MetricsIntegration.swift
//  UtahNewsData
//
//  Created for V2 Pipeline Metrics and Real-Time Monitoring
//  Aligns with iOS UtahNewsAgents app V2MetricsModels.swift
//

import Foundation

// MARK: - V2 Metrics Summary

/// Comprehensive overview metrics for V2 pipeline performance
/// Matches iOS V2MetricsSummary structure
public struct V2MetricsSummary: Codable, Sendable, JSONSchemaProvider {
    public let period: String
    public let totalPipelines: Int
    public let successfulPipelines: Int
    public let failedPipelines: Int
    public let successRate: Double
    public let averageProcessingTimeMs: Double
    public let tokenReductionVsV1: Double
    public let costSavingsVsV1: Double
    public let projectedMonthlySavings: Double
    public let hybridEfficiencyRatio: Double
    public let dataQualityScore: Double
    public let timestamp: String
    
    public init(
        period: String,
        totalPipelines: Int,
        successfulPipelines: Int,
        failedPipelines: Int,
        successRate: Double,
        averageProcessingTimeMs: Double,
        tokenReductionVsV1: Double,
        costSavingsVsV1: Double,
        projectedMonthlySavings: Double,
        hybridEfficiencyRatio: Double,
        dataQualityScore: Double,
        timestamp: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.period = period
        self.totalPipelines = totalPipelines
        self.successfulPipelines = successfulPipelines
        self.failedPipelines = failedPipelines
        self.successRate = successRate
        self.averageProcessingTimeMs = averageProcessingTimeMs
        self.tokenReductionVsV1 = tokenReductionVsV1
        self.costSavingsVsV1 = costSavingsVsV1
        self.projectedMonthlySavings = projectedMonthlySavings
        self.hybridEfficiencyRatio = hybridEfficiencyRatio
        self.dataQualityScore = dataQualityScore
        self.timestamp = timestamp
    }
    
    private enum CodingKeys: String, CodingKey {
        case period
        case totalPipelines = "total_pipelines"
        case successfulPipelines = "successful_pipelines"
        case failedPipelines = "failed_pipelines"
        case successRate = "success_rate"
        case averageProcessingTimeMs = "average_processing_time_ms"
        case tokenReductionVsV1 = "token_reduction_vs_v1"
        case costSavingsVsV1 = "cost_savings_vs_v1"
        case projectedMonthlySavings = "projected_monthly_savings"
        case hybridEfficiencyRatio = "hybrid_efficiency_ratio"
        case dataQualityScore = "data_quality_score"
        case timestamp
    }
    
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "period": {"type": "string"},
                "total_pipelines": {"type": "integer"},
                "successful_pipelines": {"type": "integer"},
                "failed_pipelines": {"type": "integer"},
                "success_rate": {"type": "number"},
                "average_processing_time_ms": {"type": "number"},
                "token_reduction_vs_v1": {"type": "number"},
                "cost_savings_vs_v1": {"type": "number"},
                "projected_monthly_savings": {"type": "number"},
                "hybrid_efficiency_ratio": {"type": "number"},
                "data_quality_score": {"type": "number"},
                "timestamp": {"type": "string"}
            },
            "required": ["period", "total_pipelines", "successful_pipelines", "failed_pipelines", "success_rate"],
            "additionalProperties": false
        }
        """
    }
}

// MARK: - V2 Token Usage Detailed

/// Detailed token usage breakdown for V2 hybrid architecture
public struct V2TokenUsage: Codable, Sendable, JSONSchemaProvider {
    public let timeWindowHours: Int
    public let openaiTotalTokens: Int
    public let localLlmTotalTokens: Int
    public let grandTotalTokens: Int
    public let tokenDistribution: V2TokenDistribution
    public let tokensByAgent: [String: V2AgentTokenBreakdown]
    public let historicalComparison: V2TokenHistoricalComparison?
    public let timestamp: String
    
    public init(
        timeWindowHours: Int,
        openaiTotalTokens: Int,
        localLlmTotalTokens: Int,
        grandTotalTokens: Int,
        tokenDistribution: V2TokenDistribution,
        tokensByAgent: [String: V2AgentTokenBreakdown],
        historicalComparison: V2TokenHistoricalComparison? = nil,
        timestamp: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.timeWindowHours = timeWindowHours
        self.openaiTotalTokens = openaiTotalTokens
        self.localLlmTotalTokens = localLlmTotalTokens
        self.grandTotalTokens = grandTotalTokens
        self.tokenDistribution = tokenDistribution
        self.tokensByAgent = tokensByAgent
        self.historicalComparison = historicalComparison
        self.timestamp = timestamp
    }
    
    private enum CodingKeys: String, CodingKey {
        case timeWindowHours = "time_window_hours"
        case openaiTotalTokens = "openai_total_tokens"
        case localLlmTotalTokens = "local_llm_total_tokens"
        case grandTotalTokens = "grand_total_tokens"
        case tokenDistribution = "token_distribution"
        case tokensByAgent = "tokens_by_agent"
        case historicalComparison = "historical_comparison"
        case timestamp
    }
    
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "time_window_hours": {"type": "integer"},
                "openai_total_tokens": {"type": "integer"},
                "local_llm_total_tokens": {"type": "integer"},
                "grand_total_tokens": {"type": "integer"},
                "token_distribution": {"$ref": "#/definitions/V2TokenDistribution"},
                "tokens_by_agent": {"type": "object", "additionalProperties": {"$ref": "#/definitions/V2AgentTokenBreakdown"}},
                "historical_comparison": {"$ref": "#/definitions/V2TokenHistoricalComparison"},
                "timestamp": {"type": "string"}
            },
            "required": ["time_window_hours", "openai_total_tokens", "local_llm_total_tokens", "grand_total_tokens", "token_distribution"],
            "additionalProperties": false
        }
        """
    }
}

/// Token distribution percentages
public struct V2TokenDistribution: Codable, Sendable {
    public let openaiPercentage: Double
    public let localLlmPercentage: Double
    public let orchestrationPercentage: Double
    public let processingPercentage: Double
    
    public init(
        openaiPercentage: Double,
        localLlmPercentage: Double,
        orchestrationPercentage: Double,
        processingPercentage: Double
    ) {
        self.openaiPercentage = openaiPercentage
        self.localLlmPercentage = localLlmPercentage
        self.orchestrationPercentage = orchestrationPercentage
        self.processingPercentage = processingPercentage
    }
    
    private enum CodingKeys: String, CodingKey {
        case openaiPercentage = "openai_percentage"
        case localLlmPercentage = "local_llm_percentage"
        case orchestrationPercentage = "orchestration_percentage"
        case processingPercentage = "processing_percentage"
    }
}

/// Token breakdown per agent
public struct V2AgentTokenBreakdown: Codable, Sendable {
    public let agentId: String
    public let orchestrationTokens: Int
    public let localLlmTokens: Int
    public let totalTokens: Int
    public let averageTokensPerExecution: Double
    public let executionCount: Int
    
    public init(
        agentId: String,
        orchestrationTokens: Int,
        localLlmTokens: Int,
        totalTokens: Int,
        averageTokensPerExecution: Double,
        executionCount: Int
    ) {
        self.agentId = agentId
        self.orchestrationTokens = orchestrationTokens
        self.localLlmTokens = localLlmTokens
        self.totalTokens = totalTokens
        self.averageTokensPerExecution = averageTokensPerExecution
        self.executionCount = executionCount
    }
    
    private enum CodingKeys: String, CodingKey {
        case agentId = "agent_id"
        case orchestrationTokens = "orchestration_tokens"
        case localLlmTokens = "local_llm_tokens"
        case totalTokens = "total_tokens"
        case averageTokensPerExecution = "average_tokens_per_execution"
        case executionCount = "execution_count"
    }
}

/// Historical token usage comparison
public struct V2TokenHistoricalComparison: Codable, Sendable {
    public let previousPeriodTokens: Int
    public let currentPeriodTokens: Int
    public let changePercentage: Double
    public let trend: String // "increasing", "decreasing", "stable"
    
    public init(
        previousPeriodTokens: Int,
        currentPeriodTokens: Int,
        changePercentage: Double,
        trend: String
    ) {
        self.previousPeriodTokens = previousPeriodTokens
        self.currentPeriodTokens = currentPeriodTokens
        self.changePercentage = changePercentage
        self.trend = trend
    }
    
    private enum CodingKeys: String, CodingKey {
        case previousPeriodTokens = "previous_period_tokens"
        case currentPeriodTokens = "current_period_tokens"
        case changePercentage = "change_percentage"
        case trend
    }
}

// MARK: - V2 Cost Analysis

/// Comprehensive cost analysis for V2 pipeline operations
public struct V2CostAnalysis: Codable, Sendable, JSONSchemaProvider {
    public let period: String
    public let v2TotalCostUsd: Double
    public let openaiCostUsd: Double
    public let localLlmCostUsd: Double
    public let v1EstimatedCostUsd: Double
    public let absoluteSavingsUsd: Double
    public let percentageSavings: Double
    public let projectedMonthlySavings: Double
    public let projectedYearlySavings: Double
    public let costPerPipeline: V2CostPerPipeline
    public let costBreakdownByAgent: [String: Double]
    public let timestamp: String
    
    public init(
        period: String,
        v2TotalCostUsd: Double,
        openaiCostUsd: Double,
        localLlmCostUsd: Double,
        v1EstimatedCostUsd: Double,
        absoluteSavingsUsd: Double,
        percentageSavings: Double,
        projectedMonthlySavings: Double,
        projectedYearlySavings: Double,
        costPerPipeline: V2CostPerPipeline,
        costBreakdownByAgent: [String: Double],
        timestamp: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.period = period
        self.v2TotalCostUsd = v2TotalCostUsd
        self.openaiCostUsd = openaiCostUsd
        self.localLlmCostUsd = localLlmCostUsd
        self.v1EstimatedCostUsd = v1EstimatedCostUsd
        self.absoluteSavingsUsd = absoluteSavingsUsd
        self.percentageSavings = percentageSavings
        self.projectedMonthlySavings = projectedMonthlySavings
        self.projectedYearlySavings = projectedYearlySavings
        self.costPerPipeline = costPerPipeline
        self.costBreakdownByAgent = costBreakdownByAgent
        self.timestamp = timestamp
    }
    
    private enum CodingKeys: String, CodingKey {
        case period
        case v2TotalCostUsd = "v2_total_cost_usd"
        case openaiCostUsd = "openai_cost_usd"
        case localLlmCostUsd = "local_llm_cost_usd"
        case v1EstimatedCostUsd = "v1_estimated_cost_usd"
        case absoluteSavingsUsd = "absolute_savings_usd"
        case percentageSavings = "percentage_savings"
        case projectedMonthlySavings = "projected_monthly_savings"
        case projectedYearlySavings = "projected_yearly_savings"
        case costPerPipeline = "cost_per_pipeline"
        case costBreakdownByAgent = "cost_breakdown_by_agent"
        case timestamp
    }
    
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "period": {"type": "string"},
                "v2_total_cost_usd": {"type": "number"},
                "openai_cost_usd": {"type": "number"},
                "local_llm_cost_usd": {"type": "number"},
                "v1_estimated_cost_usd": {"type": "number"},
                "absolute_savings_usd": {"type": "number"},
                "percentage_savings": {"type": "number"},
                "projected_monthly_savings": {"type": "number"},
                "projected_yearly_savings": {"type": "number"},
                "cost_per_pipeline": {"$ref": "#/definitions/V2CostPerPipeline"},
                "cost_breakdown_by_agent": {"type": "object", "additionalProperties": {"type": "number"}},
                "timestamp": {"type": "string"}
            },
            "required": ["period", "v2_total_cost_usd", "openai_cost_usd", "local_llm_cost_usd"],
            "additionalProperties": false
        }
        """
    }
}

/// Cost breakdown per pipeline execution
public struct V2CostPerPipeline: Codable, Sendable {
    public let averageV2CostUsd: Double
    public let averageV1CostUsd: Double
    public let medianV2CostUsd: Double
    public let maxV2CostUsd: Double
    public let minV2CostUsd: Double
    public let costDistribution: [V2CostBucket]
    
    public init(
        averageV2CostUsd: Double,
        averageV1CostUsd: Double,
        medianV2CostUsd: Double,
        maxV2CostUsd: Double,
        minV2CostUsd: Double,
        costDistribution: [V2CostBucket]
    ) {
        self.averageV2CostUsd = averageV2CostUsd
        self.averageV1CostUsd = averageV1CostUsd
        self.medianV2CostUsd = medianV2CostUsd
        self.maxV2CostUsd = maxV2CostUsd
        self.minV2CostUsd = minV2CostUsd
        self.costDistribution = costDistribution
    }
    
    private enum CodingKeys: String, CodingKey {
        case averageV2CostUsd = "average_v2_cost_usd"
        case averageV1CostUsd = "average_v1_cost_usd"
        case medianV2CostUsd = "median_v2_cost_usd"
        case maxV2CostUsd = "max_v2_cost_usd"
        case minV2CostUsd = "min_v2_cost_usd"
        case costDistribution = "cost_distribution"
    }
}

/// Cost distribution bucket for histogram analysis
public struct V2CostBucket: Codable, Sendable {
    public let rangeMin: Double
    public let rangeMax: Double
    public let count: Int
    public let percentage: Double
    
    public init(rangeMin: Double, rangeMax: Double, count: Int, percentage: Double) {
        self.rangeMin = rangeMin
        self.rangeMax = rangeMax
        self.count = count
        self.percentage = percentage
    }
    
    private enum CodingKeys: String, CodingKey {
        case rangeMin = "range_min"
        case rangeMax = "range_max"
        case count
        case percentage
    }
}

// MARK: - Real-Time V2 Metrics

/// Real-time metrics for active V2 pipeline monitoring
public struct RealtimeV2Metrics: Codable, Sendable, JSONSchemaProvider {
    public let activePipelines: Int
    public let pipelines: [ActivePipelineMetrics]
    public let realtimeStats: RealtimeStatistics
    public let systemHealth: V2SystemHealth
    public let alerts: [V2MetricsAlert]
    public let timestamp: String
    
    public init(
        activePipelines: Int,
        pipelines: [ActivePipelineMetrics],
        realtimeStats: RealtimeStatistics,
        systemHealth: V2SystemHealth,
        alerts: [V2MetricsAlert] = [],
        timestamp: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.activePipelines = activePipelines
        self.pipelines = pipelines
        self.realtimeStats = realtimeStats
        self.systemHealth = systemHealth
        self.alerts = alerts
        self.timestamp = timestamp
    }
    
    private enum CodingKeys: String, CodingKey {
        case activePipelines = "active_pipelines"
        case pipelines
        case realtimeStats = "realtime_stats"
        case systemHealth = "system_health"
        case alerts
        case timestamp
    }
    
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "active_pipelines": {"type": "integer"},
                "pipelines": {"type": "array", "items": {"$ref": "#/definitions/ActivePipelineMetrics"}},
                "realtime_stats": {"$ref": "#/definitions/RealtimeStatistics"},
                "system_health": {"$ref": "#/definitions/V2SystemHealth"},
                "alerts": {"type": "array", "items": {"$ref": "#/definitions/V2MetricsAlert"}},
                "timestamp": {"type": "string"}
            },
            "required": ["active_pipelines", "pipelines", "realtime_stats", "system_health"],
            "additionalProperties": false
        }
        """
    }
}

/// Metrics for individual active pipeline
public struct ActivePipelineMetrics: Codable, Sendable, Identifiable {
    public let id: String
    public let url: String
    public let currentAgent: String?
    public let startTime: String
    public let elapsedTimeMs: Int
    public let openaiTokens: Int
    public let localLlmTokens: Int
    public let currentCostUsd: Double
    public let status: String
    public let progress: Double // 0.0 to 1.0
    
    public init(
        id: String,
        url: String,
        currentAgent: String? = nil,
        startTime: String,
        elapsedTimeMs: Int,
        openaiTokens: Int,
        localLlmTokens: Int,
        currentCostUsd: Double,
        status: String,
        progress: Double
    ) {
        self.id = id
        self.url = url
        self.currentAgent = currentAgent
        self.startTime = startTime
        self.elapsedTimeMs = elapsedTimeMs
        self.openaiTokens = openaiTokens
        self.localLlmTokens = localLlmTokens
        self.currentCostUsd = currentCostUsd
        self.status = status
        self.progress = progress
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case url
        case currentAgent = "current_agent"
        case startTime = "start_time"
        case elapsedTimeMs = "elapsed_time_ms"
        case openaiTokens = "openai_tokens"
        case localLlmTokens = "local_llm_tokens"
        case currentCostUsd = "current_cost_usd"
        case status
        case progress
    }
}

/// Real-time statistics aggregation
public struct RealtimeStatistics: Codable, Sendable {
    public let pipelinesPerMinute: Double
    public let avgProcessingTimeMs: Double
    public let avgCostPerPipeline: Double
    public let avgTokensPerPipeline: Double
    public let successRate: Double
    public let queueDepth: Int
    
    public init(
        pipelinesPerMinute: Double,
        avgProcessingTimeMs: Double,
        avgCostPerPipeline: Double,
        avgTokensPerPipeline: Double,
        successRate: Double,
        queueDepth: Int
    ) {
        self.pipelinesPerMinute = pipelinesPerMinute
        self.avgProcessingTimeMs = avgProcessingTimeMs
        self.avgCostPerPipeline = avgCostPerPipeline
        self.avgTokensPerPipeline = avgTokensPerPipeline
        self.successRate = successRate
        self.queueDepth = queueDepth
    }
    
    private enum CodingKeys: String, CodingKey {
        case pipelinesPerMinute = "pipelines_per_minute"
        case avgProcessingTimeMs = "avg_processing_time_ms"
        case avgCostPerPipeline = "avg_cost_per_pipeline"
        case avgTokensPerPipeline = "avg_tokens_per_pipeline"
        case successRate = "success_rate"
        case queueDepth = "queue_depth"
    }
}

/// System health metrics for V2 pipeline infrastructure
public struct V2SystemHealth: Codable, Sendable {
    public let openaiApiStatus: String
    public let localLlmStatus: String
    public let firestoreStatus: String
    public let pipelineRunnerStatus: String
    public let cpuUsagePercent: Double
    public let memoryUsagePercent: Double
    public let diskUsagePercent: Double
    public let networkLatencyMs: Double
    
    public init(
        openaiApiStatus: String,
        localLlmStatus: String,
        firestoreStatus: String,
        pipelineRunnerStatus: String,
        cpuUsagePercent: Double,
        memoryUsagePercent: Double,
        diskUsagePercent: Double,
        networkLatencyMs: Double
    ) {
        self.openaiApiStatus = openaiApiStatus
        self.localLlmStatus = localLlmStatus
        self.firestoreStatus = firestoreStatus
        self.pipelineRunnerStatus = pipelineRunnerStatus
        self.cpuUsagePercent = cpuUsagePercent
        self.memoryUsagePercent = memoryUsagePercent
        self.diskUsagePercent = diskUsagePercent
        self.networkLatencyMs = networkLatencyMs
    }
    
    private enum CodingKeys: String, CodingKey {
        case openaiApiStatus = "openai_api_status"
        case localLlmStatus = "local_llm_status"
        case firestoreStatus = "firestore_status"
        case pipelineRunnerStatus = "pipeline_runner_status"
        case cpuUsagePercent = "cpu_usage_percent"
        case memoryUsagePercent = "memory_usage_percent"
        case diskUsagePercent = "disk_usage_percent"
        case networkLatencyMs = "network_latency_ms"
    }
}

/// Alert for metrics anomalies or issues
public struct V2MetricsAlert: Codable, Sendable, Identifiable {
    public let id: String
    public let alertType: String
    public let severity: String // "low", "medium", "high", "critical"
    public let message: String
    public let details: [String: String]?
    public let timestamp: String
    public let resolved: Bool
    
    public init(
        id: String = UUID().uuidString,
        alertType: String,
        severity: String,
        message: String,
        details: [String: String]? = nil,
        timestamp: String = ISO8601DateFormatter().string(from: Date()),
        resolved: Bool = false
    ) {
        self.id = id
        self.alertType = alertType
        self.severity = severity
        self.message = message
        self.details = details
        self.timestamp = timestamp
        self.resolved = resolved
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case alertType = "alert_type"
        case severity
        case message
        case details
        case timestamp
        case resolved
    }
}

// MARK: - V1 vs V2 Comparison

/// Comparison data between V1 and V2 pipeline performance
public struct V2ComparisonData: Codable, Sendable, JSONSchemaProvider {
    public let comparisonPeriodHours: Int
    public let v1Metrics: V1PipelineMetrics
    public let v2Metrics: V2PipelineMetrics
    public let improvements: V2ImprovementMetrics
    public let timestamp: String
    
    public init(
        comparisonPeriodHours: Int,
        v1Metrics: V1PipelineMetrics,
        v2Metrics: V2PipelineMetrics,
        improvements: V2ImprovementMetrics,
        timestamp: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.comparisonPeriodHours = comparisonPeriodHours
        self.v1Metrics = v1Metrics
        self.v2Metrics = v2Metrics
        self.improvements = improvements
        self.timestamp = timestamp
    }
    
    private enum CodingKeys: String, CodingKey {
        case comparisonPeriodHours = "comparison_period_hours"
        case v1Metrics = "v1_metrics"
        case v2Metrics = "v2_metrics"
        case improvements
        case timestamp
    }
    
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "comparison_period_hours": {"type": "integer"},
                "v1_metrics": {"$ref": "#/definitions/V1PipelineMetrics"},
                "v2_metrics": {"$ref": "#/definitions/V2PipelineMetrics"},
                "improvements": {"$ref": "#/definitions/V2ImprovementMetrics"},
                "timestamp": {"type": "string"}
            },
            "required": ["comparison_period_hours", "v1_metrics", "v2_metrics", "improvements"],
            "additionalProperties": false
        }
        """
    }
}

/// V1 pipeline metrics for comparison
public struct V1PipelineMetrics: Codable, Sendable {
    public let totalTokens: Int
    public let totalCostUsd: Double
    public let averageProcessingTimeMs: Double
    public let successRate: Double
    public let pipelinesExecuted: Int
    
    public init(
        totalTokens: Int,
        totalCostUsd: Double,
        averageProcessingTimeMs: Double,
        successRate: Double,
        pipelinesExecuted: Int
    ) {
        self.totalTokens = totalTokens
        self.totalCostUsd = totalCostUsd
        self.averageProcessingTimeMs = averageProcessingTimeMs
        self.successRate = successRate
        self.pipelinesExecuted = pipelinesExecuted
    }
    
    private enum CodingKeys: String, CodingKey {
        case totalTokens = "total_tokens"
        case totalCostUsd = "total_cost_usd"
        case averageProcessingTimeMs = "average_processing_time_ms"
        case successRate = "success_rate"
        case pipelinesExecuted = "pipelines_executed"
    }
}

/// V2 pipeline metrics for comparison
public struct V2PipelineMetrics: Codable, Sendable {
    public let totalTokens: Int
    public let openaiTokens: Int
    public let localLlmTokens: Int
    public let totalCostUsd: Double
    public let averageProcessingTimeMs: Double
    public let successRate: Double
    public let pipelinesExecuted: Int
    public let hybridEfficiency: Double
    
    public init(
        totalTokens: Int,
        openaiTokens: Int,
        localLlmTokens: Int,
        totalCostUsd: Double,
        averageProcessingTimeMs: Double,
        successRate: Double,
        pipelinesExecuted: Int,
        hybridEfficiency: Double
    ) {
        self.totalTokens = totalTokens
        self.openaiTokens = openaiTokens
        self.localLlmTokens = localLlmTokens
        self.totalCostUsd = totalCostUsd
        self.averageProcessingTimeMs = averageProcessingTimeMs
        self.successRate = successRate
        self.pipelinesExecuted = pipelinesExecuted
        self.hybridEfficiency = hybridEfficiency
    }
    
    private enum CodingKeys: String, CodingKey {
        case totalTokens = "total_tokens"
        case openaiTokens = "openai_tokens"
        case localLlmTokens = "local_llm_tokens"
        case totalCostUsd = "total_cost_usd"
        case averageProcessingTimeMs = "average_processing_time_ms"
        case successRate = "success_rate"
        case pipelinesExecuted = "pipelines_executed"
        case hybridEfficiency = "hybrid_efficiency"
    }
}

/// Improvement metrics comparing V2 to V1
public struct V2ImprovementMetrics: Codable, Sendable {
    public let tokenReductionPercentage: Double
    public let costSavingsPercentage: Double
    public let speedImprovementPercentage: Double
    public let qualityImprovementPercentage: Double
    public let reliabilityImprovementPercentage: Double
    public let carbonFootprintReductionPercentage: Double
    
    public init(
        tokenReductionPercentage: Double,
        costSavingsPercentage: Double,
        speedImprovementPercentage: Double,
        qualityImprovementPercentage: Double,
        reliabilityImprovementPercentage: Double,
        carbonFootprintReductionPercentage: Double
    ) {
        self.tokenReductionPercentage = tokenReductionPercentage
        self.costSavingsPercentage = costSavingsPercentage
        self.speedImprovementPercentage = speedImprovementPercentage
        self.qualityImprovementPercentage = qualityImprovementPercentage
        self.reliabilityImprovementPercentage = reliabilityImprovementPercentage
        self.carbonFootprintReductionPercentage = carbonFootprintReductionPercentage
    }
    
    private enum CodingKeys: String, CodingKey {
        case tokenReductionPercentage = "token_reduction_percentage"
        case costSavingsPercentage = "cost_savings_percentage"
        case speedImprovementPercentage = "speed_improvement_percentage"
        case qualityImprovementPercentage = "quality_improvement_percentage"
        case reliabilityImprovementPercentage = "reliability_improvement_percentage"
        case carbonFootprintReductionPercentage = "carbon_footprint_reduction_percentage"
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