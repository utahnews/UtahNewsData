# UtahNewsData V2 Pipeline Models - Developer Guide

## 🚀 V2 Architecture Overview

The UtahNewsData Swift Package has been enhanced with comprehensive V2 pipeline models that provide 98% cost reduction through intelligent hybrid architecture (2% OpenAI orchestration + 98% Local LLM processing).

### Key V2 Features

- **Complete Agent Pipeline Models**: Agent0Input through Agent9Output with perfect Python backend alignment
- **Real-time Monitoring**: Live pipeline metrics and performance tracking
- **Agent Communication**: Full agent-to-agent handoff tracking and validation
- **Cost Optimization**: Detailed token usage and cost analysis
- **Cross-Platform Sync**: Swift models perfectly aligned with Python backend

## 📦 New V2 Files Added

### Core V2 Models
- `V2PipelineModels.swift` - Complete agent input/output structures
- `AgentCommunicationProtocols.swift` - Base protocols for V2 agent communication
- `V2MetricsIntegration.swift` - Real-time monitoring and performance metrics
- `V2AgentExecutionMetadata.swift` - Execution tracking and handoff management
- `V2CoreModels.swift` (UtahNewsDataModels) - Lightweight models for app distribution

### Enhanced Existing Models
- `FinalDataPayload.swift` - Added V2 compatibility extensions and conversion methods

## 🔧 Usage Instructions

### 1. Import Strategy

```swift
// For UI and lightweight operations, prefer UtahNewsDataModels
import UtahNewsDataModels

// For full V2 functionality and utilities, import UtahNewsData
import UtahNewsData
```

### 2. Working with V2 Pipeline Models

#### Agent Input/Output Usage

```swift
import UtahNewsData

// Create Agent1 input for source validation
let agent1Input = Agent1Input(
    url: "https://example.com/news",
    sourceType: "website",
    discoveredFeeds: []
)

// Process Agent1 output
let agent1Output = Agent1Output(
    decision: .suitable,
    reason: "Valid news source with RSS feed",
    validatedUrl: "https://example.com/news",
    discoveredFeeds: [
        V2DiscoveredFeed(
            feedUrl: "https://example.com/rss",
            feedType: "RSS",
            title: "News RSS Feed"
        )
    ],
    identifiedContentType: .article,
    newsCategory: "Politics"
)
```

#### V2 Enhanced Final Data Payload

```swift
import UtahNewsData

// Create V2 enhanced payload with cost and token metrics
let tokenUsage = V2TokenUsageMetadata(
    openaiTokens: 200,
    localLlmTokens: 9800,
    totalTokens: 10000,
    tokenReductionPercentage: 98.0
)

let costMetadata = V2CostMetadata(
    openaiCostUsd: 0.02,
    localLlmCostUsd: 0.001,
    totalCostUsd: 0.021,
    v1EstimatedCostUsd: 1.2,
    costSavingsPercentage: 98.25
)

let v2Payload = V2FinalDataPayload(
    url: "https://example.com/news",
    processingTimestamp: "2024-08-11T10:00:00.000Z",
    cleanedText: "Processed article content...",
    summary: "Article summary",
    topics: ["Politics", "Utah"],
    sentimentLabel: "neutral",
    isRelevantToUtah: true,
    relevanceScore: 0.95,
    pipelineId: "pipeline-123",
    agentsCompleted: ["Agent1", "Agent2", "Agent3", "Agent5", "Agent7", "Agent9"],
    tokenUsage: tokenUsage,
    costMetadata: costMetadata,
    dataQualityScore: 0.92
)

// Access V2-specific efficiency metrics
if let efficiency = v2Payload.processingEfficiency {
    print("Token reduction: \(efficiency.tokenReductionPercentage)%")
    print("Cost savings: \(efficiency.costSavingsPercentage)%")
}

// Convert between V1/V2 formats for backward compatibility
let v1Compatible = v2Payload.toV1()
```

### 3. Real-time Monitoring Integration

#### Monitor Active Pipelines

```swift
import UtahNewsData

// Monitor active pipelines with real-time metrics
let realtimeMetrics = RealtimeV2Metrics(
    activePipelines: 5,
    pipelines: [
        ActivePipelineMetrics(
            id: "pipeline-abc",
            url: "https://news-source.com/article",
            currentAgent: "Agent3",
            startTime: "2024-08-11T10:00:00.000Z",
            elapsedTimeMs: 15000,
            openaiTokens: 150,
            localLlmTokens: 7350,
            currentCostUsd: 0.018,
            status: "processing",
            progress: 0.6
        )
    ],
    realtimeStats: RealtimeStatistics(
        pipelinesPerMinute: 2.5,
        avgProcessingTimeMs: 4200.0,
        avgCostPerPipeline: 0.022,
        avgTokensPerPipeline: 7500.0,
        successRate: 96.8,
        queueDepth: 8
    )
)

// Display pipeline progress
for pipeline in realtimeMetrics.pipelines {
    print("Pipeline \(pipeline.id): \(Int(pipeline.progress * 100))% complete")
    print("Token split: \(pipeline.openaiTokens) OpenAI + \(pipeline.localLlmTokens) Local")
}
```

#### Agent Execution Tracking

```swift
import UtahNewsData

// Track agent execution metadata
var executionMetadata = V2PipelineExecutionMetadata(
    pipelineId: "pipeline-xyz",
    sourceUrl: "https://example.com",
    currentAgent: "Agent1"
)

// Add execution checkpoints
executionMetadata.addCheckpoint(
    agentId: "agent-1",
    agentName: "Source Validator", 
    checkpoint: "validation_complete",
    status: .completed,
    metadata: ["decision": "SUITABLE", "category": "Politics"],
    duration: 1.5
)

// Track agent handoffs
let handoffRecord = V2AgentHandoffRecord(
    pipelineId: executionMetadata.pipelineId,
    fromAgent: "Agent1",
    toAgent: "Agent2",
    handoffType: .directPass,
    dataSize: 1024,
    validationResults: V2HandoffValidationRecord(
        isValid: true,
        validationScore: 0.98,
        schemaCompliance: true,
        warnings: [],
        errors: []
    )
)
```

### 4. Lightweight Models for iOS Apps

```swift
import UtahNewsDataModels

// Use lightweight V2 models for app UI
let metricsLite = V2MetricsSummaryLite(
    successRate: 96.5,
    tokenReductionVsV1: 98.2,
    costSavingsVsV1: 97.8,
    averageProcessingTimeMs: 4200.0,
    hybridEfficiencyRatio: 0.98,
    totalPipelinesProcessed: 1250
)

let pipelineStatus = V2PipelineStatusLite(
    pipelineId: "ui-pipeline",
    url: "https://ui-example.com",
    status: .running,
    currentAgent: "Agent5",
    progress: 0.75,
    startTime: "2024-08-11T10:00:00.000Z",
    tokensUsed: 6800,
    costUsd: 0.019
)

// Perfect for SwiftUI views
struct V2DashboardView: View {
    let metrics: V2MetricsSummaryLite
    
    var body: some View {
        VStack {
            HStack {
                Text("Success Rate")
                Spacer()
                Text("\(metrics.successRate, specifier: "%.1f")%")
                    .foregroundColor(.green)
            }
            
            HStack {
                Text("Token Reduction")
                Spacer()
                Text("\(metrics.tokenReductionVsV1, specifier: "%.1f")%")
                    .foregroundColor(.blue)
            }
        }
    }
}
```

### 5. Agent Communication Protocols

```swift
import UtahNewsData

// Implement custom agents conforming to V2 protocols
struct CustomAgentInput: V2AgentInput {
    let inputId: String = UUID().uuidString
    let createdAt: Date = Date()
    let pipelineMetadata: [String: String]?
    
    // Custom input fields
    let customData: String
}

struct CustomAgentOutput: V2AgentOutput {
    let executionStatus: V2AgentExecutionStatus
    let processingTimeMs: Int
    let errors: [V2AgentError]?
    let executionMetadata: V2AgentExecutionMetadata?
    
    // Custom output fields
    let processedData: String
}
```

## 📋 JSON Schema Support

All V2 models include comprehensive JSON schema generation for LLM interactions:

```swift
import UtahNewsData

// Access JSON schemas for any V2 model
let schema = V2FinalDataPayload.jsonSchema
let metricsSchema = V2MetricsSummary.jsonSchema
let agentSchema = Agent1Output.jsonSchema

// Use schemas to instruct LLMs
print("Use this schema to generate valid V2 payload JSON:")
print(schema)
```

## 🔄 Migration from V1

### Converting Existing V1 Code

```swift
// V1 Code (old)
let v1Payload = FinalDataPayload(
    url: "https://example.com",
    cleanedText: "content",
    summary: "summary"
)

// V2 Migration (new)
let v2Payload = v1Payload.toV2(
    pipelineId: "pipeline-123",
    agentsCompleted: ["Agent1", "Agent3", "Agent5"],
    tokenUsage: tokenUsageMetadata,
    costMetadata: costMetadata
)
```

### Backward Compatibility

```swift
// Convert V2 back to V1 when needed
let v2Payload = V2FinalDataPayload(...)
let v1Compatible = v2Payload.toV1()
```

## 🚦 Performance Considerations

### Lightweight vs Full Models

- **Use UtahNewsDataModels** for:
  - SwiftUI views and UI components
  - Basic data display and storage
  - Cross-platform sharing
  - Minimal memory footprint

- **Use UtahNewsData** for:
  - Pipeline processing and orchestration
  - Real-time monitoring and metrics
  - Agent communication and handoffs
  - Advanced V2 functionality

### JSON Serialization Performance

All V2 models are optimized for high-performance JSON serialization:

```swift
import UtahNewsData

let encoder = JSONEncoder()
let decoder = JSONDecoder()

// High-performance serialization
let jsonData = try encoder.encode(v2Payload)
let decodedPayload = try decoder.decode(V2FinalDataPayload.self, from: jsonData)
```

## 🔍 Debugging and Monitoring

### Enable Detailed Logging

```swift
import UtahNewsData

// Track pipeline execution with detailed metadata
let executionMetadata = V2PipelineExecutionMetadata(
    pipelineId: "debug-pipeline",
    sourceUrl: "https://debug-url.com",
    currentAgent: "Agent1"
)

// Add comprehensive checkpoints for debugging
executionMetadata.addCheckpoint(
    agentId: "agent-1",
    agentName: "Debug Agent",
    checkpoint: "debug_point",
    status: .inProgress,
    metadata: [
        "debug_info": "Processing stage 1",
        "memory_usage": "45MB",
        "cpu_usage": "23%"
    ],
    duration: 2.5,
    memorySnapshot: V2MemorySnapshot(
        usedMemoryMb: 45.2,
        availableMemoryMb: 156.8,
        memoryPressure: "normal"
    )
)
```

## 🧪 Testing V2 Models

### Unit Testing Example

```swift
import XCTest
@testable import UtahNewsData

class V2PipelineTests: XCTestCase {
    func testV2PayloadCreation() {
        let payload = V2FinalDataPayload(
            url: "https://test.com",
            processingTimestamp: "2024-08-11T10:00:00.000Z",
            cleanedText: "Test content",
            summary: "Test summary",
            pipelineId: "test-pipeline"
        )
        
        XCTAssertEqual(payload.url, "https://test.com")
        XCTAssertEqual(payload.pipelineVersion, "v2")
        XCTAssertEqual(payload.processingMethod, "hybrid")
    }
    
    func testV2JSONSerialization() throws {
        let payload = V2FinalDataPayload(...)
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(payload)
        
        let decoder = JSONDecoder()
        let decodedPayload = try decoder.decode(V2FinalDataPayload.self, from: jsonData)
        
        XCTAssertEqual(payload.url, decodedPayload.url)
    }
}
```

## 📚 Additional Resources

- **README.md** - Complete V2 architecture documentation with examples
- **V2PipelineModels.swift** - Full agent model definitions
- **V2MetricsIntegration.swift** - Monitoring and metrics documentation
- **AgentCommunicationProtocols.swift** - Protocol definitions and usage

## 🎯 Best Practices

1. **Import Strategy**: Use `UtahNewsDataModels` for UI, `UtahNewsData` for processing
2. **Error Handling**: Always handle optional fields with proper nil coalescing
3. **Performance**: Use lightweight models for high-frequency UI updates
4. **Monitoring**: Implement comprehensive checkpoint tracking for debugging
5. **Testing**: Include both serialization and functional tests for V2 models

## 🔧 Swift 6 Compliance

All V2 models are fully compliant with Swift 6 strict concurrency:

- **Sendable conformance** for all data structures
- **@MainActor isolation** for UI-bound operations
- **Async/await patterns** for agent communication
- **Actor-based architectures** for pipeline orchestration

---

*This guide covers the complete V2 pipeline model integration. For questions or issues, refer to the main README.md or create an issue in the repository.*