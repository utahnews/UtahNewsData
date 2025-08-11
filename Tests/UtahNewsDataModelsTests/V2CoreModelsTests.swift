//
//  V2CoreModelsTests.swift
//  UtahNewsDataModelsTests
//
//  Unit tests for V2 Core Models (Lightweight)
//

import XCTest
@testable import UtahNewsDataModels

final class V2CoreModelsTests: XCTestCase {
    
    // MARK: - V2FinalDataPayloadLite Tests
    
    func testV2FinalDataPayloadLiteInitialization() {
        let payload = V2FinalDataPayloadLite(
            url: "https://example.com/article",
            processingTimestamp: "2024-08-11T10:00:00.000Z",
            cleanedText: "This is the cleaned text content.",
            summary: "Article summary here.",
            topics: ["Politics", "Utah", "Education"],
            sentimentLabel: "positive",
            sentimentScore: 0.75,
            isRelevantToUtah: true,
            relevanceScore: 0.9,
            pipelineId: "pipeline-abc123",
            totalProcessingTimeMs: 5000,
            tokenReductionPercentage: 98.5,
            costSavingsPercentage: 97.2
        )
        
        XCTAssertEqual(payload.url, "https://example.com/article")
        XCTAssertEqual(payload.pipelineVersion, "v2")
        XCTAssertEqual(payload.processingMethod, "hybrid")
        XCTAssertEqual(payload.cleanedText, "This is the cleaned text content.")
        XCTAssertEqual(payload.summary, "Article summary here.")
        XCTAssertEqual(payload.topics, ["Politics", "Utah", "Education"])
        XCTAssertEqual(payload.sentimentLabel, "positive")
        XCTAssertEqual(payload.sentimentScore, 0.75, accuracy: 0.001)
        XCTAssertTrue(payload.isRelevantToUtah ?? false)
        XCTAssertEqual(payload.relevanceScore, 0.9, accuracy: 0.001)
        XCTAssertEqual(payload.pipelineId, "pipeline-abc123")
        XCTAssertEqual(payload.totalProcessingTimeMs, 5000)
        XCTAssertEqual(payload.tokenReductionPercentage, 98.5, accuracy: 0.1)
        XCTAssertEqual(payload.costSavingsPercentage, 97.2, accuracy: 0.1)
    }
    
    func testV2FinalDataPayloadLiteMinimalInitialization() {
        let payload = V2FinalDataPayloadLite(
            url: "https://minimal.com",
            processingTimestamp: "2024-08-11T10:00:00.000Z"
        )
        
        XCTAssertEqual(payload.url, "https://minimal.com")
        XCTAssertEqual(payload.pipelineVersion, "v2")
        XCTAssertEqual(payload.processingMethod, "hybrid")
        XCTAssertNil(payload.cleanedText)
        XCTAssertNil(payload.summary)
        XCTAssertNil(payload.topics)
        XCTAssertNil(payload.pipelineId)
    }
    
    func testV2FinalDataPayloadLiteJSONSerialization() throws {
        let payload = V2FinalDataPayloadLite(
            url: "https://json-test.com",
            processingTimestamp: "2024-08-11T10:00:00.000Z",
            cleanedText: "Test content",
            topics: ["Test"]
        )
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(payload)
        
        let decoder = JSONDecoder()
        let decodedPayload = try decoder.decode(V2FinalDataPayloadLite.self, from: jsonData)
        
        XCTAssertEqual(decodedPayload.url, payload.url)
        XCTAssertEqual(decodedPayload.processingTimestamp, payload.processingTimestamp)
        XCTAssertEqual(decodedPayload.cleanedText, payload.cleanedText)
        XCTAssertEqual(decodedPayload.topics, payload.topics)
    }
    
    func testV2FinalDataPayloadLiteJSONSchema() {
        let schema = V2FinalDataPayloadLite.jsonSchema
        
        XCTAssertTrue(schema.contains("url"))
        XCTAssertTrue(schema.contains("processing_timestamp"))
        XCTAssertTrue(schema.contains("pipeline_version"))
        XCTAssertTrue(schema.contains("processing_method"))
        XCTAssertTrue(schema.contains("token_reduction_percentage"))
        XCTAssertTrue(schema.contains("cost_savings_percentage"))
        XCTAssertTrue(schema.contains("additionalProperties"))
        XCTAssertTrue(schema.contains("false"))
    }
    
    // MARK: - V2PipelineStatusLite Tests
    
    func testV2PipelineStatusLiteInitialization() {
        let status = V2PipelineStatusLite(
            pipelineId: "pipeline-xyz789",
            url: "https://status-test.com",
            status: .running,
            currentAgent: "Agent3",
            progress: 0.6,
            startTime: "2024-08-11T10:00:00.000Z",
            estimatedCompletionTime: "2024-08-11T10:05:00.000Z",
            tokensUsed: 5000,
            costUsd: 0.025
        )
        
        XCTAssertEqual(status.pipelineId, "pipeline-xyz789")
        XCTAssertEqual(status.url, "https://status-test.com")
        XCTAssertEqual(status.status, .running)
        XCTAssertEqual(status.currentAgent, "Agent3")
        XCTAssertEqual(status.progress, 0.6, accuracy: 0.001)
        XCTAssertEqual(status.startTime, "2024-08-11T10:00:00.000Z")
        XCTAssertEqual(status.estimatedCompletionTime, "2024-08-11T10:05:00.000Z")
        XCTAssertEqual(status.tokensUsed, 5000)
        XCTAssertEqual(status.costUsd, 0.025, accuracy: 0.001)
    }
    
    func testV2PipelineStatusLiteMinimalInitialization() {
        let status = V2PipelineStatusLite(
            pipelineId: "minimal-pipeline",
            url: "https://minimal-status.com",
            status: .pending,
            startTime: "2024-08-11T10:00:00.000Z"
        )
        
        XCTAssertEqual(status.pipelineId, "minimal-pipeline")
        XCTAssertEqual(status.status, .pending)
        XCTAssertEqual(status.progress, 0.0)
        XCTAssertNil(status.currentAgent)
        XCTAssertNil(status.estimatedCompletionTime)
        XCTAssertNil(status.tokensUsed)
        XCTAssertNil(status.costUsd)
        XCTAssertNil(status.errorMessage)
    }
    
    func testV2PipelineStatusLiteFailedStatus() {
        let status = V2PipelineStatusLite(
            pipelineId: "failed-pipeline",
            url: "https://failed-status.com",
            status: .failed,
            progress: 0.3,
            startTime: "2024-08-11T10:00:00.000Z",
            errorMessage: "Agent 2 failed due to network error"
        )
        
        XCTAssertEqual(status.status, .failed)
        XCTAssertEqual(status.progress, 0.3, accuracy: 0.001)
        XCTAssertEqual(status.errorMessage, "Agent 2 failed due to network error")
    }
    
    func testV2PipelineStatusLiteJSONSerialization() throws {
        let status = V2PipelineStatusLite(
            pipelineId: "json-test-pipeline",
            url: "https://json-status-test.com",
            status: .completed,
            progress: 1.0,
            startTime: "2024-08-11T10:00:00.000Z"
        )
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(status)
        
        let decoder = JSONDecoder()
        let decodedStatus = try decoder.decode(V2PipelineStatusLite.self, from: jsonData)
        
        XCTAssertEqual(decodedStatus.pipelineId, status.pipelineId)
        XCTAssertEqual(decodedStatus.url, status.url)
        XCTAssertEqual(decodedStatus.status, status.status)
        XCTAssertEqual(decodedStatus.progress, status.progress, accuracy: 0.001)
    }
    
    // MARK: - V2PipelineExecutionStatus Tests
    
    func testV2PipelineExecutionStatusAllCases() {
        let allCases = V2PipelineExecutionStatus.allCases
        
        XCTAssertEqual(allCases.count, 5)
        XCTAssertTrue(allCases.contains(.pending))
        XCTAssertTrue(allCases.contains(.running))
        XCTAssertTrue(allCases.contains(.completed))
        XCTAssertTrue(allCases.contains(.failed))
        XCTAssertTrue(allCases.contains(.cancelled))
    }
    
    func testV2PipelineExecutionStatusRawValues() {
        XCTAssertEqual(V2PipelineExecutionStatus.pending.rawValue, "pending")
        XCTAssertEqual(V2PipelineExecutionStatus.running.rawValue, "running")
        XCTAssertEqual(V2PipelineExecutionStatus.completed.rawValue, "completed")
        XCTAssertEqual(V2PipelineExecutionStatus.failed.rawValue, "failed")
        XCTAssertEqual(V2PipelineExecutionStatus.cancelled.rawValue, "cancelled")
    }
    
    func testV2PipelineExecutionStatusCoding() throws {
        let statuses: [V2PipelineExecutionStatus] = [.pending, .running, .completed, .failed, .cancelled]
        
        for status in statuses {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(status)
            
            let decoder = JSONDecoder()
            let decodedStatus = try decoder.decode(V2PipelineExecutionStatus.self, from: jsonData)
            
            XCTAssertEqual(decodedStatus, status)
        }
    }
    
    // MARK: - V2MetricsSummaryLite Tests
    
    func testV2MetricsSummaryLiteInitialization() {
        let metrics = V2MetricsSummaryLite(
            successRate: 94.5,
            tokenReductionVsV1: 98.2,
            costSavingsVsV1: 97.8,
            averageProcessingTimeMs: 4500.0,
            hybridEfficiencyRatio: 0.95,
            totalPipelinesProcessed: 1250,
            timestamp: "2024-08-11T10:00:00.000Z"
        )
        
        XCTAssertEqual(metrics.successRate, 94.5, accuracy: 0.1)
        XCTAssertEqual(metrics.tokenReductionVsV1, 98.2, accuracy: 0.1)
        XCTAssertEqual(metrics.costSavingsVsV1, 97.8, accuracy: 0.1)
        XCTAssertEqual(metrics.averageProcessingTimeMs, 4500.0, accuracy: 0.1)
        XCTAssertEqual(metrics.hybridEfficiencyRatio, 0.95, accuracy: 0.01)
        XCTAssertEqual(metrics.totalPipelinesProcessed, 1250)
        XCTAssertEqual(metrics.timestamp, "2024-08-11T10:00:00.000Z")
    }
    
    func testV2MetricsSummaryLiteDefaultTimestamp() {
        let metrics = V2MetricsSummaryLite(
            successRate: 90.0,
            tokenReductionVsV1: 95.0,
            costSavingsVsV1: 94.0,
            averageProcessingTimeMs: 5000.0,
            hybridEfficiencyRatio: 0.9,
            totalPipelinesProcessed: 100
        )
        
        // Timestamp should be auto-generated
        XCTAssertFalse(metrics.timestamp.isEmpty)
        XCTAssertTrue(metrics.timestamp.contains("T"))
        XCTAssertTrue(metrics.timestamp.hasSuffix("Z"))
    }
    
    func testV2MetricsSummaryLiteJSONSerialization() throws {
        let metrics = V2MetricsSummaryLite(
            successRate: 92.3,
            tokenReductionVsV1: 97.5,
            costSavingsVsV1: 96.8,
            averageProcessingTimeMs: 3800.5,
            hybridEfficiencyRatio: 0.96,
            totalPipelinesProcessed: 850
        )
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(metrics)
        
        let decoder = JSONDecoder()
        let decodedMetrics = try decoder.decode(V2MetricsSummaryLite.self, from: jsonData)
        
        XCTAssertEqual(decodedMetrics.successRate, metrics.successRate, accuracy: 0.1)
        XCTAssertEqual(decodedMetrics.tokenReductionVsV1, metrics.tokenReductionVsV1, accuracy: 0.1)
        XCTAssertEqual(decodedMetrics.totalPipelinesProcessed, metrics.totalPipelinesProcessed)
    }
    
    // MARK: - V2AgentInfoLite Tests
    
    func testV2AgentInfoLiteInitialization() {
        let agentInfo = V2AgentInfoLite(
            id: "agent-1",
            name: "Source Validator",
            description: "Validates and categorizes news sources",
            version: "v2.1.0",
            status: .active,
            capabilities: ["source_validation", "category_detection", "feed_discovery"],
            averageTokenUsage: 1200,
            averageProcessingTimeMs: 850.5,
            successRate: 96.7,
            lastUpdated: "2024-08-11T10:00:00.000Z"
        )
        
        XCTAssertEqual(agentInfo.id, "agent-1")
        XCTAssertEqual(agentInfo.name, "Source Validator")
        XCTAssertEqual(agentInfo.description, "Validates and categorizes news sources")
        XCTAssertEqual(agentInfo.version, "v2.1.0")
        XCTAssertEqual(agentInfo.status, .active)
        XCTAssertEqual(agentInfo.capabilities.count, 3)
        XCTAssertTrue(agentInfo.capabilities.contains("source_validation"))
        XCTAssertEqual(agentInfo.averageTokenUsage, 1200)
        XCTAssertEqual(agentInfo.averageProcessingTimeMs, 850.5, accuracy: 0.1)
        XCTAssertEqual(agentInfo.successRate, 96.7, accuracy: 0.1)
    }
    
    func testV2AgentInfoLiteMinimalInitialization() {
        let agentInfo = V2AgentInfoLite(
            id: "minimal-agent",
            name: "Minimal Agent",
            description: "Basic agent info",
            version: "v1.0.0",
            status: .inactive
        )
        
        XCTAssertEqual(agentInfo.id, "minimal-agent")
        XCTAssertEqual(agentInfo.status, .inactive)
        XCTAssertEqual(agentInfo.capabilities.count, 0)
        XCTAssertNil(agentInfo.averageTokenUsage)
        XCTAssertNil(agentInfo.averageProcessingTimeMs)
        XCTAssertNil(agentInfo.successRate)
    }
    
    func testV2AgentInfoLiteJSONSerialization() throws {
        let agentInfo = V2AgentInfoLite(
            id: "json-agent",
            name: "JSON Test Agent",
            description: "Agent for JSON testing",
            version: "v2.0.0",
            status: .maintenance,
            capabilities: ["json_parsing", "data_validation"]
        )
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(agentInfo)
        
        let decoder = JSONDecoder()
        let decodedAgentInfo = try decoder.decode(V2AgentInfoLite.self, from: jsonData)
        
        XCTAssertEqual(decodedAgentInfo.id, agentInfo.id)
        XCTAssertEqual(decodedAgentInfo.name, agentInfo.name)
        XCTAssertEqual(decodedAgentInfo.status, agentInfo.status)
        XCTAssertEqual(decodedAgentInfo.capabilities, agentInfo.capabilities)
    }
    
    // MARK: - V2AgentStatus Tests
    
    func testV2AgentStatusAllCases() {
        let allCases = V2AgentStatus.allCases
        
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.active))
        XCTAssertTrue(allCases.contains(.inactive))
        XCTAssertTrue(allCases.contains(.maintenance))
        XCTAssertTrue(allCases.contains(.error))
    }
    
    func testV2AgentStatusRawValues() {
        XCTAssertEqual(V2AgentStatus.active.rawValue, "active")
        XCTAssertEqual(V2AgentStatus.inactive.rawValue, "inactive")
        XCTAssertEqual(V2AgentStatus.maintenance.rawValue, "maintenance")
        XCTAssertEqual(V2AgentStatus.error.rawValue, "error")
    }
    
    // MARK: - JSON Schema Tests
    
    func testAllModelsHaveJSONSchema() {
        XCTAssertFalse(V2FinalDataPayloadLite.jsonSchema.isEmpty)
        XCTAssertFalse(V2PipelineStatusLite.jsonSchema.isEmpty)
        XCTAssertFalse(V2MetricsSummaryLite.jsonSchema.isEmpty)
        XCTAssertFalse(V2AgentInfoLite.jsonSchema.isEmpty)
    }
    
    func testJSONSchemasContainRequired() {
        // Test that JSON schemas contain required fields
        let payloadSchema = V2FinalDataPayloadLite.jsonSchema
        XCTAssertTrue(payloadSchema.contains("required"))
        XCTAssertTrue(payloadSchema.contains("url"))
        XCTAssertTrue(payloadSchema.contains("processing_timestamp"))
        
        let statusSchema = V2PipelineStatusLite.jsonSchema
        XCTAssertTrue(statusSchema.contains("required"))
        XCTAssertTrue(statusSchema.contains("pipeline_id"))
        XCTAssertTrue(statusSchema.contains("status"))
        
        let metricsSchema = V2MetricsSummaryLite.jsonSchema
        XCTAssertTrue(metricsSchema.contains("required"))
        XCTAssertTrue(metricsSchema.contains("success_rate"))
    }
    
    // MARK: - Performance Tests
    
    func testV2CoreModelsSerializationPerformance() throws {
        let payload = V2FinalDataPayloadLite(
            url: "https://performance-test.com",
            processingTimestamp: "2024-08-11T10:00:00.000Z",
            cleanedText: String(repeating: "Performance test content. ", count: 500),
            topics: Array(repeating: "PerformanceTopic", count: 50)
        )
        
        let encoder = JSONEncoder()
        
        measure {
            for _ in 0..<200 {
                _ = try? encoder.encode(payload)
            }
        }
    }
    
    func testV2CoreModelsDeserializationPerformance() throws {
        let payload = V2FinalDataPayloadLite(
            url: "https://performance-test.com",
            processingTimestamp: "2024-08-11T10:00:00.000Z"
        )
        
        let jsonData = try JSONEncoder().encode(payload)
        let decoder = JSONDecoder()
        
        measure {
            for _ in 0..<200 {
                _ = try? decoder.decode(V2FinalDataPayloadLite.self, from: jsonData)
            }
        }
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testV2ModelsWithEmptyValues() throws {
        let payload = V2FinalDataPayloadLite(
            url: "",
            processingTimestamp: "",
            topics: []
        )
        
        let jsonData = try JSONEncoder().encode(payload)
        let decodedPayload = try JSONDecoder().decode(V2FinalDataPayloadLite.self, from: jsonData)
        
        XCTAssertEqual(decodedPayload.url, "")
        XCTAssertEqual(decodedPayload.topics?.count, 0)
    }
    
    func testV2ModelsWithExtremeValues() throws {
        let payload = V2FinalDataPayloadLite(
            url: "https://extreme-test.com",
            processingTimestamp: "2024-08-11T10:00:00.000Z",
            sentimentScore: 1.0,
            relevanceScore: 0.0,
            totalProcessingTimeMs: Int.max,
            tokenReductionPercentage: 100.0,
            costSavingsPercentage: 100.0
        )
        
        let jsonData = try JSONEncoder().encode(payload)
        let decodedPayload = try JSONDecoder().decode(V2FinalDataPayloadLite.self, from: jsonData)
        
        XCTAssertEqual(decodedPayload.sentimentScore, 1.0, accuracy: 0.001)
        XCTAssertEqual(decodedPayload.relevanceScore, 0.0, accuracy: 0.001)
        XCTAssertEqual(decodedPayload.totalProcessingTimeMs, Int.max)
        XCTAssertEqual(decodedPayload.tokenReductionPercentage, 100.0, accuracy: 0.1)
        XCTAssertEqual(decodedPayload.costSavingsPercentage, 100.0, accuracy: 0.1)
    }
}