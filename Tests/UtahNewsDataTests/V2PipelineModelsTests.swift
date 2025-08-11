//
//  V2PipelineModelsTests.swift
//  UtahNewsDataTests
//
//  Unit tests for V2 Pipeline Models
//

import XCTest
@testable import UtahNewsData

final class V2PipelineModelsTests: XCTestCase {
    
    // MARK: - Agent0Input Tests
    
    func testAgent0InputInitialization() {
        let input = Agent0Input(
            cityName: "Salt Lake City",
            targetCategories: ["Politics", "Education"],
            existingSources: [["url": "https://example.com", "name": "Example Source"]],
            searchQueries: ["utah news", "salt lake city"]
        )
        
        XCTAssertEqual(input.cityName, "Salt Lake City")
        XCTAssertEqual(input.targetCategories, ["Politics", "Education"])
        XCTAssertEqual(input.existingSources.count, 1)
        XCTAssertEqual(input.searchQueries, ["utah news", "salt lake city"])
    }
    
    func testAgent0InputJSONSerialization() throws {
        let input = Agent0Input(
            cityName: "Provo",
            existingSources: []
        )
        
        let jsonData = try JSONEncoder().encode(input)
        let decodedInput = try JSONDecoder().decode(Agent0Input.self, from: jsonData)
        
        XCTAssertEqual(decodedInput.cityName, "Provo")
        XCTAssertEqual(decodedInput.existingSources.count, 0)
        XCTAssertNil(decodedInput.targetCategories)
    }
    
    func testAgent0InputJSONSchema() {
        let schema = Agent0Input.jsonSchema
        XCTAssertTrue(schema.contains("city_name"))
        XCTAssertTrue(schema.contains("existing_sources"))
        XCTAssertTrue(schema.contains("additionalProperties"))
    }
    
    // MARK: - Agent1StructuredInput Tests
    
    func testAgent1StructuredInputInitialization() {
        let input = Agent1StructuredInput(
            url: "https://example.com/article",
            title: "Test Article",
            snippet: "This is a test article snippet"
        )
        
        XCTAssertEqual(input.url, "https://example.com/article")
        XCTAssertEqual(input.title, "Test Article")
        XCTAssertEqual(input.snippet, "This is a test article snippet")
    }
    
    func testAgent1StructuredInputRequiredFields() {
        let input = Agent1StructuredInput(url: "https://required.com")
        
        XCTAssertEqual(input.url, "https://required.com")
        XCTAssertNil(input.title)
        XCTAssertNil(input.snippet)
    }
    
    // MARK: - Agent1Output Tests
    
    func testAgent1OutputSuitableDecision() {
        let discoveredFeed = V2DiscoveredFeed(url: "https://example.com/feed", type: "RSS", title: "Test Feed")
        
        let output = Agent1Output(
            decision: .suitable,
            reason: "Valid news source",
            validatedUrl: "https://example.com/validated",
            discoveredFeeds: [discoveredFeed],
            identifiedContentType: .article,
            newsCategory: "Politics"
        )
        
        XCTAssertEqual(output.decision, .suitable)
        XCTAssertEqual(output.reason, "Valid news source")
        XCTAssertEqual(output.discoveredFeeds.count, 1)
        XCTAssertEqual(output.identifiedContentType, .article)
    }
    
    func testAgent1OutputUnsuitableDecision() {
        let output = Agent1Output(
            decision: .unsuitable,
            reason: "Not a news source"
        )
        
        XCTAssertEqual(output.decision, .unsuitable)
        XCTAssertEqual(output.reason, "Not a news source")
        XCTAssertEqual(output.discoveredFeeds.count, 0)
    }
    
    // MARK: - V2ContentType Tests
    
    func testV2ContentTypeAllCases() {
        let allCases = V2ContentType.allCases
        
        XCTAssertTrue(allCases.contains(.article))
        XCTAssertTrue(allCases.contains(.feed))
        XCTAssertTrue(allCases.contains(.sitemap))
        XCTAssertTrue(allCases.contains(.directory))
        XCTAssertTrue(allCases.contains(.list))
        XCTAssertTrue(allCases.contains(.personProfile))
        XCTAssertTrue(allCases.contains(.organizationProfile))
        XCTAssertTrue(allCases.contains(.general))
    }
    
    func testV2ContentTypeRawValues() {
        XCTAssertEqual(V2ContentType.article.rawValue, "Article")
        XCTAssertEqual(V2ContentType.personProfile.rawValue, "PersonProfile")
    }
    
    // MARK: - Agent2Output Tests
    
    func testAgent2OutputInitialization() {
        let fetchResult = V2FetchedContentResult(
            status: "success",
            sourceUrl: "https://example.com",
            contentId: "test-content-id",
            contentType: "text/html"
        )
        
        let output = Agent2Output(
            fetchResult: fetchResult,
            identifiedContentType: .article,
            discoveredUrls: ["https://example.com/page1", "https://example.com/page2"]
        )
        
        XCTAssertEqual(output.fetchResult.status, "success")
        XCTAssertEqual(output.fetchResult.sourceUrl, "https://example.com")
        XCTAssertEqual(output.identifiedContentType, .article)
        XCTAssertEqual(output.discoveredUrls?.count, 2)
    }
    
    // MARK: - Agent3Output Tests
    
    func testAgent3OutputModerationPassed() {
        let output = Agent3Output(
            moderationPassed: true,
            flaggedCategories: [],
            needsHumanReview: false,
            statusMessage: "Content approved",
            cleanedText: "This is clean content"
        )
        
        XCTAssertTrue(output.moderationPassed)
        XCTAssertEqual(output.flaggedCategories.count, 0)
        XCTAssertFalse(output.needsHumanReview)
        XCTAssertEqual(output.cleanedText, "This is clean content")
    }
    
    func testAgent3OutputModerationFailed() {
        let output = Agent3Output(
            moderationPassed: false,
            flaggedCategories: ["violence", "hate"],
            needsHumanReview: true,
            statusMessage: "Content flagged"
        )
        
        XCTAssertFalse(output.moderationPassed)
        XCTAssertEqual(output.flaggedCategories, ["violence", "hate"])
        XCTAssertTrue(output.needsHumanReview)
        XCTAssertNil(output.cleanedText)
    }
    
    // MARK: - V2GeocodeResult Tests
    
    func testV2GeocodeResultInitialization() {
        let result = V2GeocodeResult(
            query: "Salt Lake City, UT",
            status: "success",
            latitude: 40.7608,
            longitude: -111.8910,
            address: "Salt Lake City, Utah, USA",
            confidence: 0.95
        )
        
        XCTAssertEqual(result.query, "Salt Lake City, UT")
        XCTAssertEqual(result.status, "success")
        XCTAssertEqual(result.latitude ?? 0, 40.7608, accuracy: 0.0001)
        XCTAssertEqual(result.longitude ?? 0, -111.8910, accuracy: 0.0001)
        XCTAssertEqual(result.confidence ?? 0, 0.95, accuracy: 0.001)
    }
    
    // MARK: - V2SentimentAnalysisOutput Tests
    
    func testV2SentimentAnalysisOutputInitialization() {
        let sentimentOutput = V2SentimentAnalysisOutput(
            sentimentLabel: "positive",
            sentimentScore: 0.85,
            confidence: 0.92
        )
        
        XCTAssertEqual(sentimentOutput.sentimentLabel, "positive")
        XCTAssertEqual(sentimentOutput.sentimentScore, 0.85, accuracy: 0.001)
        XCTAssertEqual(sentimentOutput.confidence ?? 0, 0.92, accuracy: 0.001)
    }
    
    // MARK: - V2RelevanceOutput Tests
    
    func testV2RelevanceOutputInitialization() {
        let relevanceOutput = V2RelevanceOutput(
            isRelevant: true,
            relevanceScore: 0.78,
            reason: "Contains Utah-specific content"
        )
        
        XCTAssertTrue(relevanceOutput.isRelevant)
        XCTAssertEqual(relevanceOutput.relevanceScore, 0.78, accuracy: 0.001)
        XCTAssertEqual(relevanceOutput.reason, "Contains Utah-specific content")
    }
    
    // MARK: - V2IdentifiedRelationship Tests
    
    func testV2IdentifiedRelationshipInitialization() {
        let relationship = V2IdentifiedRelationship(
            subject: "John Doe",
            predicate: "works_at",
            object: "Utah State University",
            confidence: 0.89,
            context: "Mentioned in article about faculty"
        )
        
        XCTAssertEqual(relationship.subject, "John Doe")
        XCTAssertEqual(relationship.predicate, "works_at")
        XCTAssertEqual(relationship.object, "Utah State University")
        XCTAssertEqual(relationship.confidence ?? 0, 0.89, accuracy: 0.001)
        XCTAssertEqual(relationship.context, "Mentioned in article about faculty")
    }
    
    // MARK: - V2TokenUsageMetadata Tests
    
    func testV2TokenUsageMetadataInitialization() {
        let tokenUsage = V2TokenUsageMetadata(
            openaiTokens: 200,
            localLlmTokens: 8000,
            totalTokens: 8200,
            tokenReductionPercentage: 95.0
        )
        
        XCTAssertEqual(tokenUsage.openaiTokens, 200)
        XCTAssertEqual(tokenUsage.localLlmTokens, 8000)
        XCTAssertEqual(tokenUsage.totalTokens, 8200)
        XCTAssertEqual(tokenUsage.tokenReductionPercentage, 95.0, accuracy: 0.1)
    }
    
    // MARK: - V2CostMetadata Tests
    
    func testV2CostMetadataInitialization() {
        let costMetadata = V2CostMetadata(
            openaiCostUsd: 0.02,
            localLlmCostUsd: 0.001,
            totalCostUsd: 0.021,
            v1EstimatedCostUsd: 1.0,
            costSavingsPercentage: 97.9
        )
        
        XCTAssertEqual(costMetadata.openaiCostUsd, 0.02, accuracy: 0.001)
        XCTAssertEqual(costMetadata.localLlmCostUsd, 0.001, accuracy: 0.0001)
        XCTAssertEqual(costMetadata.totalCostUsd, 0.021, accuracy: 0.001)
        XCTAssertEqual(costMetadata.v1EstimatedCostUsd, 1.0, accuracy: 0.01)
        XCTAssertEqual(costMetadata.costSavingsPercentage, 97.9, accuracy: 0.1)
    }
    
    // MARK: - V2FinalDataPayload Tests
    
    func testV2FinalDataPayloadInitialization() {
        let tokenUsage = V2TokenUsageMetadata(
            openaiTokens: 150,
            localLlmTokens: 7500,
            totalTokens: 7650,
            tokenReductionPercentage: 98.0
        )
        
        let costMetadata = V2CostMetadata(
            openaiCostUsd: 0.015,
            localLlmCostUsd: 0.0008,
            totalCostUsd: 0.0158,
            v1EstimatedCostUsd: 0.8,
            costSavingsPercentage: 98.0
        )
        
        let payload = V2FinalDataPayload(
            url: "https://example.com/news",
            processingTimestamp: "2024-08-11T10:00:00.000Z",
            cleanedText: "This is the cleaned article text",
            summary: "Article summary",
            topics: ["Politics", "Utah"],
            sentimentLabel: "neutral",
            sentimentScore: 0.5,
            isRelevantToUtah: true,
            relevanceScore: 0.9,
            pipelineId: "pipeline-123",
            agentsCompleted: ["Agent1", "Agent2", "Agent3"],
            tokenUsage: tokenUsage,
            costMetadata: costMetadata,
            dataQualityScore: 0.85
        )
        
        XCTAssertEqual(payload.url, "https://example.com/news")
        XCTAssertEqual(payload.pipelineVersion, "v2")
        XCTAssertEqual(payload.processingMethod, "hybrid")
        XCTAssertEqual(payload.agentsCompleted.count, 3)
        XCTAssertNotNil(payload.tokenUsage)
        XCTAssertNotNil(payload.costMetadata)
        XCTAssertEqual(payload.dataQualityScore ?? 0, 0.85, accuracy: 0.001)
    }
    
    func testV2FinalDataPayloadJSONSerialization() throws {
        let payload = V2FinalDataPayload(
            url: "https://test.com",
            processingTimestamp: "2024-08-11T10:00:00.000Z"
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let jsonData = try encoder.encode(payload)
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString?.contains("https://test.com") == true)
        XCTAssertTrue(jsonString?.contains("pipeline_version") == true)
        
        // Test round-trip
        let decodedPayload = try JSONDecoder().decode(V2FinalDataPayload.self, from: jsonData)
        XCTAssertEqual(decodedPayload.url, payload.url)
        XCTAssertEqual(decodedPayload.pipelineVersion, payload.pipelineVersion)
    }
    
    func testV2FinalDataPayloadJSONSchema() {
        let schema = V2FinalDataPayload.jsonSchema
        
        XCTAssertTrue(schema.contains("url"))
        XCTAssertTrue(schema.contains("pipeline_version"))
        XCTAssertTrue(schema.contains("processing_method"))
        XCTAssertTrue(schema.contains("agents_completed"))
        XCTAssertTrue(schema.contains("additionalProperties"))
        XCTAssertTrue(schema.contains("false"))
    }
    
    // MARK: - Performance Tests
    
    func testV2ModelSerializationPerformance() throws {
        let payload = V2FinalDataPayload(
            url: "https://performance-test.com",
            processingTimestamp: "2024-08-11T10:00:00.000Z",
            cleanedText: String(repeating: "This is test content. ", count: 1000), // ~20KB
            topics: Array(repeating: "TestTopic", count: 100)
        )
        
        let encoder = JSONEncoder()
        
        measure {
            for _ in 0..<100 {
                _ = try? encoder.encode(payload)
            }
        }
    }
    
    func testV2ModelDeserializationPerformance() throws {
        let payload = V2FinalDataPayload(
            url: "https://performance-test.com",
            processingTimestamp: "2024-08-11T10:00:00.000Z"
        )
        
        let jsonData = try JSONEncoder().encode(payload)
        let decoder = JSONDecoder()
        
        measure {
            for _ in 0..<100 {
                _ = try? decoder.decode(V2FinalDataPayload.self, from: jsonData)
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testV2ModelDecodingWithInvalidJSON() {
        let invalidJSON = """
        {
            "url": "https://test.com",
            "pipeline_version": 123,
            "extra_field": "not_allowed"
        }
        """.data(using: .utf8)!
        
        XCTAssertThrowsError(try JSONDecoder().decode(V2FinalDataPayload.self, from: invalidJSON))
    }
    
    func testV2ModelDecodingWithMissingRequiredFields() {
        let incompleteJSON = """
        {
            "processing_timestamp": "2024-08-11T10:00:00.000Z"
        }
        """.data(using: .utf8)!
        
        XCTAssertThrowsError(try JSONDecoder().decode(V2FinalDataPayload.self, from: incompleteJSON))
    }
}