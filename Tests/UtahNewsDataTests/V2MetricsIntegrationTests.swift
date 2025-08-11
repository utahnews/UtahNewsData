//
//  V2MetricsIntegrationTests.swift
//  UtahNewsDataTests
//
//  Unit tests for V2 Metrics Integration Models
//

import XCTest
@testable import UtahNewsData

final class V2MetricsIntegrationTests: XCTestCase {
    
    // MARK: - V2MetricsSummary Tests
    
    func testV2MetricsSummaryInitialization() {
        let summary = V2MetricsSummary(
            period: "daily",
            totalPipelines: 150,
            successfulPipelines: 142,
            failedPipelines: 8,
            successRate: 94.67,
            averageProcessingTimeMs: 4250.5,
            tokenReductionVsV1: 98.2,
            costSavingsVsV1: 97.8,
            projectedMonthlySavings: 2450.0,
            hybridEfficiencyRatio: 0.96,
            dataQualityScore: 0.89,
            timestamp: "2024-08-11T10:00:00.000Z"
        )
        
        XCTAssertEqual(summary.period, "daily")
        XCTAssertEqual(summary.totalPipelines, 150)
        XCTAssertEqual(summary.successfulPipelines, 142)
        XCTAssertEqual(summary.failedPipelines, 8)
        XCTAssertEqual(summary.successRate, 94.67, accuracy: 0.01)
        XCTAssertEqual(summary.averageProcessingTimeMs, 4250.5, accuracy: 0.1)
        XCTAssertEqual(summary.tokenReductionVsV1, 98.2, accuracy: 0.1)
        XCTAssertEqual(summary.costSavingsVsV1, 97.8, accuracy: 0.1)
        XCTAssertEqual(summary.projectedMonthlySavings, 2450.0, accuracy: 0.1)
        XCTAssertEqual(summary.hybridEfficiencyRatio, 0.96, accuracy: 0.01)
        XCTAssertEqual(summary.dataQualityScore, 0.89, accuracy: 0.01)
    }
    
    // MARK: - V2TokenUsage Tests
    
    func testV2TokenUsageInitialization() {
        let tokenDistribution = V2TokenDistribution(
            openaiPercentage: 2.1,
            localLlmPercentage: 97.9,
            orchestrationPercentage: 2.1,
            processingPercentage: 97.9
        )
        
        let agentBreakdown = V2AgentTokenBreakdown(
            agentId: "agent-1",
            orchestrationTokens: 150,
            localLlmTokens: 7500,
            totalTokens: 7650,
            averageTokensPerExecution: 765.0,
            executionCount: 10
        )
        
        let historicalComparison = V2TokenHistoricalComparison(
            previousPeriodTokens: 85000,
            currentPeriodTokens: 76500,
            changePercentage: -10.0,
            trend: "decreasing"
        )
        
        let tokenUsage = V2TokenUsage(
            timeWindowHours: 24,
            openaiTotalTokens: 2100,
            localLlmTotalTokens: 97900,
            grandTotalTokens: 100000,
            tokenDistribution: tokenDistribution,
            tokensByAgent: ["agent-1": agentBreakdown],
            historicalComparison: historicalComparison
        )
        
        XCTAssertEqual(tokenUsage.timeWindowHours, 24)
        XCTAssertEqual(tokenUsage.openaiTotalTokens, 2100)
        XCTAssertEqual(tokenUsage.localLlmTotalTokens, 97900)
        XCTAssertEqual(tokenUsage.grandTotalTokens, 100000)
        XCTAssertEqual(tokenUsage.tokenDistribution.openaiPercentage, 2.1, accuracy: 0.1)
        XCTAssertEqual(tokenUsage.tokensByAgent.count, 1)
        XCTAssertNotNil(tokenUsage.historicalComparison)
    }
    
    func testV2TokenDistributionPercentages() {
        let distribution = V2TokenDistribution(
            openaiPercentage: 1.8,
            localLlmPercentage: 98.2,
            orchestrationPercentage: 1.8,
            processingPercentage: 98.2
        )
        
        // Verify percentages add up correctly
        let totalPercentage = distribution.openaiPercentage + distribution.localLlmPercentage
        XCTAssertEqual(totalPercentage, 100.0, accuracy: 0.1)
    }
    
    // MARK: - V2CostAnalysis Tests
    
    func testV2CostAnalysisInitialization() {
        let costPerPipeline = V2CostPerPipeline(
            averageV2CostUsd: 0.025,
            averageV1CostUsd: 1.2,
            medianV2CostUsd: 0.022,
            maxV2CostUsd: 0.08,
            minV2CostUsd: 0.01,
            costDistribution: []
        )
        
        let costAnalysis = V2CostAnalysis(
            period: "daily",
            v2TotalCostUsd: 3.75,
            openaiCostUsd: 0.25,
            localLlmCostUsd: 3.5,
            v1EstimatedCostUsd: 180.0,
            absoluteSavingsUsd: 176.25,
            percentageSavings: 97.9,
            projectedMonthlySavings: 5287.5,
            projectedYearlySavings: 64350.0,
            costPerPipeline: costPerPipeline,
            costBreakdownByAgent: ["agent-1": 0.5, "agent-2": 0.8, "agent-3": 1.2]
        )
        
        XCTAssertEqual(costAnalysis.period, "daily")
        XCTAssertEqual(costAnalysis.v2TotalCostUsd, 3.75, accuracy: 0.01)
        XCTAssertEqual(costAnalysis.openaiCostUsd, 0.25, accuracy: 0.01)
        XCTAssertEqual(costAnalysis.localLlmCostUsd, 3.5, accuracy: 0.01)
        XCTAssertEqual(costAnalysis.v1EstimatedCostUsd, 180.0, accuracy: 0.01)
        XCTAssertEqual(costAnalysis.absoluteSavingsUsd, 176.25, accuracy: 0.01)
        XCTAssertEqual(costAnalysis.percentageSavings, 97.9, accuracy: 0.1)
        XCTAssertEqual(costAnalysis.projectedMonthlySavings, 5287.5, accuracy: 0.1)
        XCTAssertEqual(costAnalysis.projectedYearlySavings, 64350.0, accuracy: 0.1)
        XCTAssertEqual(costAnalysis.costBreakdownByAgent.count, 3)
    }
    
    func testV2CostBucketInitialization() {
        let bucket = V2CostBucket(
            rangeMin: 0.01,
            rangeMax: 0.05,
            count: 45,
            percentage: 30.0
        )
        
        XCTAssertEqual(bucket.rangeMin, 0.01, accuracy: 0.001)
        XCTAssertEqual(bucket.rangeMax, 0.05, accuracy: 0.001)
        XCTAssertEqual(bucket.count, 45)
        XCTAssertEqual(bucket.percentage, 30.0, accuracy: 0.1)
    }
    
    // MARK: - RealtimeV2Metrics Tests
    
    func testRealtimeV2MetricsInitialization() {
        let activePipeline = ActivePipelineMetrics(
            id: "pipeline-123",
            url: "https://example.com/news",
            currentAgent: "Agent3",
            startTime: "2024-08-11T10:00:00.000Z",
            elapsedTimeMs: 15000,
            openaiTokens: 150,
            localLlmTokens: 7350,
            currentCostUsd: 0.022,
            status: "processing",
            progress: 0.6
        )
        
        let realtimeStats = RealtimeStatistics(
            pipelinesPerMinute: 2.5,
            avgProcessingTimeMs: 4200.0,
            avgCostPerPipeline: 0.024,
            avgTokensPerPipeline: 7500.0,
            successRate: 95.2,
            queueDepth: 12
        )
        
        let systemHealth = V2SystemHealth(
            openaiApiStatus: "healthy",
            localLlmStatus: "healthy",
            firestoreStatus: "healthy",
            pipelineRunnerStatus: "running",
            cpuUsagePercent: 45.2,
            memoryUsagePercent: 62.8,
            diskUsagePercent: 23.1,
            networkLatencyMs: 125.5
        )
        
        let alert = V2MetricsAlert(
            alertType: "performance_degradation",
            severity: "medium",
            message: "Processing time increased by 15% in last hour"
        )
        
        let realtimeMetrics = RealtimeV2Metrics(
            activePipelines: 8,
            pipelines: [activePipeline],
            realtimeStats: realtimeStats,
            systemHealth: systemHealth,
            alerts: [alert]
        )
        
        XCTAssertEqual(realtimeMetrics.activePipelines, 8)
        XCTAssertEqual(realtimeMetrics.pipelines.count, 1)
        XCTAssertEqual(realtimeMetrics.realtimeStats.pipelinesPerMinute, 2.5, accuracy: 0.1)
        XCTAssertEqual(realtimeMetrics.systemHealth.cpuUsagePercent, 45.2, accuracy: 0.1)
        XCTAssertEqual(realtimeMetrics.alerts.count, 1)
        XCTAssertEqual(realtimeMetrics.alerts.first?.severity, "medium")
    }
    
    func testActivePipelineMetricsIdentifiable() {
        let pipeline = ActivePipelineMetrics(
            id: "identifiable-test",
            url: "https://test.com",
            startTime: "2024-08-11T10:00:00.000Z",
            elapsedTimeMs: 5000,
            openaiTokens: 100,
            localLlmTokens: 5000,
            currentCostUsd: 0.015,
            status: "running",
            progress: 0.4
        )
        
        XCTAssertEqual(pipeline.id, "identifiable-test")
        // Test that it conforms to Identifiable
        let _ = pipeline.id as String
    }
    
    // MARK: - V2ComparisonData Tests
    
    func testV2ComparisonDataInitialization() {
        let v1Metrics = V1PipelineMetrics(
            totalTokens: 500000,
            totalCostUsd: 120.0,
            averageProcessingTimeMs: 8500.0,
            successRate: 89.5,
            pipelinesExecuted: 100
        )
        
        let v2Metrics = V2PipelineMetrics(
            totalTokens: 10000,
            openaiTokens: 200,
            localLlmTokens: 9800,
            totalCostUsd: 2.4,
            averageProcessingTimeMs: 4200.0,
            successRate: 95.8,
            pipelinesExecuted: 100,
            hybridEfficiency: 0.98
        )
        
        let improvements = V2ImprovementMetrics(
            tokenReductionPercentage: 98.0,
            costSavingsPercentage: 98.0,
            speedImprovementPercentage: 50.6,
            qualityImprovementPercentage: 6.3,
            reliabilityImprovementPercentage: 6.3,
            carbonFootprintReductionPercentage: 95.0
        )
        
        let comparison = V2ComparisonData(
            comparisonPeriodHours: 48,
            v1Metrics: v1Metrics,
            v2Metrics: v2Metrics,
            improvements: improvements
        )
        
        XCTAssertEqual(comparison.comparisonPeriodHours, 48)
        XCTAssertEqual(comparison.v1Metrics.totalTokens, 500000)
        XCTAssertEqual(comparison.v2Metrics.totalTokens, 10000)
        XCTAssertEqual(comparison.v2Metrics.hybridEfficiency, 0.98, accuracy: 0.01)
        XCTAssertEqual(comparison.improvements.tokenReductionPercentage, 98.0, accuracy: 0.1)
        XCTAssertEqual(comparison.improvements.carbonFootprintReductionPercentage, 95.0, accuracy: 0.1)
    }
    
    // MARK: - V2MetricsAlert Tests
    
    func testV2MetricsAlertInitialization() {
        let alert = V2MetricsAlert(
            id: "custom-alert-id",
            alertType: "cost_threshold_exceeded",
            severity: "high",
            message: "Daily cost exceeded $50 threshold",
            details: ["threshold": "50.00", "current": "52.30"],
            timestamp: "2024-08-11T10:00:00.000Z",
            resolved: false
        )
        
        XCTAssertEqual(alert.id, "custom-alert-id")
        XCTAssertEqual(alert.alertType, "cost_threshold_exceeded")
        XCTAssertEqual(alert.severity, "high")
        XCTAssertEqual(alert.message, "Daily cost exceeded $50 threshold")
        XCTAssertEqual(alert.details?["threshold"], "50.00")
        XCTAssertEqual(alert.details?["current"], "52.30")
        XCTAssertFalse(alert.resolved)
    }
    
    func testV2MetricsAlertDefaultId() {
        let alert = V2MetricsAlert(
            alertType: "test_alert",
            severity: "low",
            message: "Test message"
        )
        
        XCTAssertFalse(alert.id.isEmpty)
        // UUID format check
        XCTAssertEqual(alert.id.count, 36) // UUID string length
        XCTAssertTrue(alert.id.contains("-"))
    }
    
    // MARK: - JSON Serialization Tests
    
    func testV2MetricsSummaryJSONSerialization() throws {
        let summary = V2MetricsSummary(
            period: "hourly",
            totalPipelines: 25,
            successfulPipelines: 24,
            failedPipelines: 1,
            successRate: 96.0,
            averageProcessingTimeMs: 3800.5,
            tokenReductionVsV1: 97.8,
            costSavingsVsV1: 97.5,
            projectedMonthlySavings: 1850.0,
            hybridEfficiencyRatio: 0.978,
            dataQualityScore: 0.92
        )
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(summary)
        
        let decoder = JSONDecoder()
        let decodedSummary = try decoder.decode(V2MetricsSummary.self, from: jsonData)
        
        XCTAssertEqual(decodedSummary.period, summary.period)
        XCTAssertEqual(decodedSummary.totalPipelines, summary.totalPipelines)
        XCTAssertEqual(decodedSummary.successRate, summary.successRate, accuracy: 0.1)
        XCTAssertEqual(decodedSummary.projectedMonthlySavings, summary.projectedMonthlySavings, accuracy: 0.1)
    }
    
    func testRealtimeV2MetricsJSONSerialization() throws {
        let pipeline = ActivePipelineMetrics(
            id: "json-test",
            url: "https://json-test.com",
            startTime: "2024-08-11T10:00:00.000Z",
            elapsedTimeMs: 3000,
            openaiTokens: 75,
            localLlmTokens: 3750,
            currentCostUsd: 0.012,
            status: "running",
            progress: 0.3
        )
        
        let stats = RealtimeStatistics(
            pipelinesPerMinute: 1.8,
            avgProcessingTimeMs: 4500.0,
            avgCostPerPipeline: 0.025,
            avgTokensPerPipeline: 8000.0,
            successRate: 94.5,
            queueDepth: 5
        )
        
        let health = V2SystemHealth(
            openaiApiStatus: "healthy",
            localLlmStatus: "healthy",
            firestoreStatus: "healthy",
            pipelineRunnerStatus: "running",
            cpuUsagePercent: 35.0,
            memoryUsagePercent: 55.0,
            diskUsagePercent: 20.0,
            networkLatencyMs: 100.0
        )
        
        let metrics = RealtimeV2Metrics(
            activePipelines: 3,
            pipelines: [pipeline],
            realtimeStats: stats,
            systemHealth: health
        )
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(metrics)
        
        let decoder = JSONDecoder()
        let decodedMetrics = try decoder.decode(RealtimeV2Metrics.self, from: jsonData)
        
        XCTAssertEqual(decodedMetrics.activePipelines, metrics.activePipelines)
        XCTAssertEqual(decodedMetrics.pipelines.count, metrics.pipelines.count)
        XCTAssertEqual(decodedMetrics.pipelines.first?.id, pipeline.id)
        XCTAssertEqual(decodedMetrics.systemHealth.cpuUsagePercent, health.cpuUsagePercent, accuracy: 0.1)
    }
    
    // MARK: - JSON Schema Tests
    
    func testAllMetricsModelsHaveJSONSchemas() {
        XCTAssertFalse(V2MetricsSummary.jsonSchema.isEmpty)
        XCTAssertFalse(V2TokenUsage.jsonSchema.isEmpty)
        XCTAssertFalse(V2CostAnalysis.jsonSchema.isEmpty)
        XCTAssertFalse(RealtimeV2Metrics.jsonSchema.isEmpty)
        XCTAssertFalse(V2ComparisonData.jsonSchema.isEmpty)
    }
    
    func testJSONSchemasAreValidJSON() throws {
        let schemas = [
            V2MetricsSummary.jsonSchema,
            V2TokenUsage.jsonSchema,
            V2CostAnalysis.jsonSchema,
            RealtimeV2Metrics.jsonSchema,
            V2ComparisonData.jsonSchema
        ]
        
        for schema in schemas {
            let jsonData = schema.data(using: .utf8)!
            XCTAssertNoThrow(try JSONSerialization.jsonObject(with: jsonData))
        }
    }
    
    // MARK: - Performance Tests
    
    func testV2MetricsSerializationPerformance() throws {
        let summary = V2MetricsSummary(
            period: "daily",
            totalPipelines: 1000,
            successfulPipelines: 950,
            failedPipelines: 50,
            successRate: 95.0,
            averageProcessingTimeMs: 4000.0,
            tokenReductionVsV1: 98.0,
            costSavingsVsV1: 97.5,
            projectedMonthlySavings: 10000.0,
            hybridEfficiencyRatio: 0.98,
            dataQualityScore: 0.9
        )
        
        let encoder = JSONEncoder()
        
        measure {
            for _ in 0..<100 {
                _ = try? encoder.encode(summary)
            }
        }
    }
    
    func testComplexV2MetricsSerializationPerformance() throws {
        // Create a complex metrics object with many nested components
        let pipelines = (0..<50).map { i in
            ActivePipelineMetrics(
                id: "pipeline-\(i)",
                url: "https://test\(i).com",
                startTime: "2024-08-11T10:00:00.000Z",
                elapsedTimeMs: 1000 + i * 100,
                openaiTokens: 100,
                localLlmTokens: 5000,
                currentCostUsd: 0.02,
                status: "running",
                progress: Double(i) / 50.0
            )
        }
        
        let stats = RealtimeStatistics(
            pipelinesPerMinute: 5.0,
            avgProcessingTimeMs: 4000.0,
            avgCostPerPipeline: 0.02,
            avgTokensPerPipeline: 5100.0,
            successRate: 95.0,
            queueDepth: 10
        )
        
        let health = V2SystemHealth(
            openaiApiStatus: "healthy",
            localLlmStatus: "healthy",
            firestoreStatus: "healthy",
            pipelineRunnerStatus: "running",
            cpuUsagePercent: 50.0,
            memoryUsagePercent: 60.0,
            diskUsagePercent: 25.0,
            networkLatencyMs: 120.0
        )
        
        let metrics = RealtimeV2Metrics(
            activePipelines: pipelines.count,
            pipelines: pipelines,
            realtimeStats: stats,
            systemHealth: health
        )
        
        let encoder = JSONEncoder()
        
        measure {
            for _ in 0..<10 {
                _ = try? encoder.encode(metrics)
            }
        }
    }
}