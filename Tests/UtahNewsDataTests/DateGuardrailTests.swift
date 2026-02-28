//
//  DateGuardrailTests.swift
//  UtahNewsDataTests
//
//  WS-B date-repair guardrail tests.
//  Covers: missing publish date, conflicting/ambiguous date, conclusive date pass-through,
//  legacy ingest timestamp present but canonical missing, and confidence threshold enforcement.
//

import XCTest
@testable import UtahNewsData

final class DateGuardrailTests: XCTestCase {

    // MARK: - Helpers

    /// Convenience to build a SupabaseProcessedItem with date-specific fields.
    private func makeSupabaseItem(
        publishDate: String? = nil,
        publishedAt: String? = nil,
        publishedAtSource: String? = nil,
        publishedAtConfidence: String? = nil,
        isEvergreen: Bool? = nil,
        discoveredAt: String? = nil,
        ingestedAt: String? = nil,
        processingTimestamp: String = "2026-02-25T10:00:00Z"
    ) -> SupabaseProcessedItem {
        SupabaseProcessedItem(
            id: "test-\(UUID().uuidString.prefix(8))",
            url: "https://example.com/article",
            sourceTitle: "Example News",
            author: nil,
            publishDate: publishDate,
            publishedAt: publishedAt,
            publishedAtSource: publishedAtSource,
            publishedAtConfidence: publishedAtConfidence,
            isEvergreen: isEvergreen,
            discoveredAt: discoveredAt,
            ingestedAt: ingestedAt,
            cleanedText: "Article body text",
            summary: "Article summary",
            fmExcerpt: nil,
            entitiesJson: "[]",
            topics: ["news"],
            sentimentLabel: "neutral",
            sentimentScore: 0.0,
            language: "en",
            isRelevantToUtah: true,
            relevanceScore: 0.8,
            utahLocations: ["Salt Lake City"],
            relevanceMethod: "keyword_match",
            promotionCandidate: false,
            promotedToSource: false,
            sourceId: nil,
            identifiedContentType: "article",
            confidenceScores: nil,
            pageRole: nil,
            discoveryScope: nil,
            classificationConfidence: nil,
            assignedScanFrequency: nil,
            extractedUrlCount: nil,
            keywords: nil,
            processingTimestamp: processingTimestamp,
            cityName: "Salt Lake City",
            sourceDomain: "example.com",
            editorialSignals: nil,
            structuredData: nil
        )
    }

    // MARK: - Confidence Threshold Tests

    func testConfidenceThresholdIs093() {
        XCTAssertEqual(DateGuardrailResult.confidenceThreshold, 0.93)
    }

    func testHighConfidenceMeetsThreshold() {
        let item = makeSupabaseItem(
            publishedAt: "2026-02-20T08:00:00Z",
            publishedAtSource: "raw_content",
            publishedAtConfidence: "high",
            isEvergreen: false
        )
        XCTAssertEqual(item.publishedAtConfidenceScore, 0.95)
        XCTAssertTrue(item.publishedAtConfidenceScore >= DateGuardrailResult.confidenceThreshold)
        XCTAssertTrue(item.hasConclusivePublishDate)
        XCTAssertTrue(item.isDraftEligible)
    }

    func testMediumConfidenceBelowThreshold() {
        let item = makeSupabaseItem(
            publishedAt: "2026-02-20T08:00:00Z",
            publishedAtSource: "raw_content",
            publishedAtConfidence: "medium",
            isEvergreen: false
        )
        XCTAssertEqual(item.publishedAtConfidenceScore, 0.75)
        XCTAssertTrue(item.publishedAtConfidenceScore < DateGuardrailResult.confidenceThreshold)
        XCTAssertFalse(item.hasConclusivePublishDate)
        XCTAssertFalse(item.isDraftEligible)
    }

    func testLowConfidenceBelowThreshold() {
        let item = makeSupabaseItem(
            publishedAt: "2026-02-20T08:00:00Z",
            publishedAtSource: "raw_content",
            publishedAtConfidence: "low",
            isEvergreen: false
        )
        XCTAssertEqual(item.publishedAtConfidenceScore, 0.40)
        XCTAssertFalse(item.isDraftEligible)
    }

    func testNilConfidenceReturnsZero() {
        let item = makeSupabaseItem(
            publishedAt: "2026-02-20T08:00:00Z",
            publishedAtSource: "raw_content",
            publishedAtConfidence: nil,
            isEvergreen: false
        )
        XCTAssertEqual(item.publishedAtConfidenceScore, 0.0)
        XCTAssertFalse(item.isDraftEligible)
    }

    // MARK: - Missing Publish Date

    func testMissingPublishDateBlocksDrafting() {
        let item = makeSupabaseItem(
            publishedAt: nil,
            publishedAtSource: "raw_content",
            publishedAtConfidence: "high",
            isEvergreen: false
        )
        XCTAssertFalse(item.isDraftEligible)

        let result = item.dateGuardrailResult
        XCTAssertFalse(result.eligible)
        XCTAssertEqual(result.blockCode, .missingPublishDate)
    }

    func testEmptyPublishDateStringBlocksDrafting() {
        let item = makeSupabaseItem(
            publishedAt: "",
            publishedAtSource: "raw_content",
            publishedAtConfidence: "high",
            isEvergreen: false
        )
        // publishedDate parses to nil for empty string
        XCTAssertNil(item.publishedDate)
        XCTAssertFalse(item.isDraftEligible)
    }

    // MARK: - Unknown Source

    func testUnknownSourceBlocksDrafting() {
        let item = makeSupabaseItem(
            publishedAt: "2026-02-20T08:00:00Z",
            publishedAtSource: "unknown",
            publishedAtConfidence: "high",
            isEvergreen: false
        )
        XCTAssertFalse(item.isDraftEligible)

        let result = item.dateGuardrailResult
        XCTAssertFalse(result.eligible)
        XCTAssertEqual(result.blockCode, .unknownSource)
    }

    // MARK: - Evergreen Content

    func testEvergreenContentBlocksDrafting() {
        let item = makeSupabaseItem(
            publishedAt: "2026-02-20T08:00:00Z",
            publishedAtSource: "raw_content",
            publishedAtConfidence: "high",
            isEvergreen: true
        )
        XCTAssertTrue(item.isEvergreenItem)
        XCTAssertFalse(item.isDraftEligible)
    }

    // MARK: - Ingest Timestamp Reuse Detection

    func testPublishDateMatchingProcessingTimestampBlocksDrafting() {
        let timestamp = "2026-02-25T10:00:00Z"
        let item = makeSupabaseItem(
            publishedAt: timestamp,
            publishedAtSource: "raw_content",
            publishedAtConfidence: "high",
            isEvergreen: false,
            processingTimestamp: timestamp
        )
        XCTAssertTrue(item.publishDateMatchesIngestTimestamp)
        XCTAssertFalse(item.isDraftEligible)

        let result = item.dateGuardrailResult
        XCTAssertFalse(result.eligible)
        XCTAssertEqual(result.blockCode, .ingestTimestampReused)
    }

    func testPublishDateMatchingDiscoveredAtBlocksDrafting() {
        let discTS = "2026-02-25T09:00:00Z"
        let item = makeSupabaseItem(
            publishedAt: discTS,
            publishedAtSource: "raw_content",
            publishedAtConfidence: "high",
            isEvergreen: false,
            discoveredAt: discTS,
            processingTimestamp: "2026-02-25T10:00:00Z"
        )
        XCTAssertTrue(item.publishDateMatchesIngestTimestamp)
        XCTAssertFalse(item.isDraftEligible)
    }

    func testPublishDateMatchingIngestedAtBlocksDrafting() {
        let ingTS = "2026-02-25T09:30:00Z"
        let item = makeSupabaseItem(
            publishedAt: ingTS,
            publishedAtSource: "raw_content",
            publishedAtConfidence: "high",
            isEvergreen: false,
            ingestedAt: ingTS,
            processingTimestamp: "2026-02-25T10:00:00Z"
        )
        XCTAssertTrue(item.publishDateMatchesIngestTimestamp)
        XCTAssertFalse(item.isDraftEligible)
    }

    // MARK: - Conclusive Date Pass-Through

    func testConclusiveDatePassesAllGuardrails() {
        let item = makeSupabaseItem(
            publishedAt: "2026-02-20T08:00:00Z",
            publishedAtSource: "raw_content",
            publishedAtConfidence: "high",
            isEvergreen: false,
            discoveredAt: "2026-02-25T09:00:00Z",
            ingestedAt: "2026-02-25T09:30:00Z",
            processingTimestamp: "2026-02-25T10:00:00Z"
        )

        XCTAssertTrue(item.hasConclusivePublishDate)
        XCTAssertFalse(item.publishDateMatchesIngestTimestamp)
        XCTAssertFalse(item.isEvergreenItem)
        XCTAssertTrue(item.isDraftEligible)

        let result = item.dateGuardrailResult
        XCTAssertTrue(result.eligible)
        XCTAssertNil(result.blockCode)
        XCTAssertTrue(result.reason.contains("Passed"))
    }

    func testAIFoundationHighConfidencePasses() {
        let item = makeSupabaseItem(
            publishedAt: "2026-02-18T14:00:00Z",
            publishedAtSource: "ai_foundation",
            publishedAtConfidence: "high",
            isEvergreen: false,
            processingTimestamp: "2026-02-25T10:00:00Z"
        )
        XCTAssertTrue(item.isDraftEligible)
    }

    // MARK: - Legacy Ingest Timestamp Present But Canonical Missing

    func testLegacyIngestTimestampPresentButCanonicalMissing() {
        let item = makeSupabaseItem(
            publishedAt: nil,
            publishedAtSource: nil,
            publishedAtConfidence: nil,
            isEvergreen: nil,
            discoveredAt: "2026-02-25T09:00:00Z",
            ingestedAt: "2026-02-25T09:30:00Z",
            processingTimestamp: "2026-02-25T10:00:00Z"
        )

        // Even though ingest timestamps exist, no canonical publish date = blocked
        XCTAssertFalse(item.isDraftEligible)
        XCTAssertTrue(item.isEvergreenItem)

        let result = item.dateGuardrailResult
        XCTAssertFalse(result.eligible)
        XCTAssertEqual(result.blockCode, .missingPublishDate)
    }

    // MARK: - DateGuardrailResult Audit Log

    func testAuditLogLineContainsBlockCode() {
        let result = DateGuardrailResult.evaluate(
            itemId: "item-123",
            publishedAt: nil,
            publishedAtSourceRaw: nil,
            publishedAtConfidenceScore: 0.0,
            isEvergreen: false,
            publishDateMatchesIngestTimestamp: false
        )
        XCTAssertFalse(result.eligible)
        XCTAssertTrue(result.auditLogLine.contains("BLOCK"))
        XCTAssertTrue(result.auditLogLine.contains("MISSING_PUBLISH_DATE"))
        XCTAssertTrue(result.auditLogLine.contains("item=item-123"))
    }

    func testAuditLogLineForPassedItem() {
        let result = DateGuardrailResult.evaluate(
            itemId: "item-456",
            publishedAt: Date(),
            publishedAtSourceRaw: "raw_content",
            publishedAtConfidenceScore: 0.95,
            isEvergreen: false,
            publishDateMatchesIngestTimestamp: false
        )
        XCTAssertTrue(result.eligible)
        XCTAssertTrue(result.auditLogLine.contains("PASS"))
        XCTAssertTrue(result.auditLogLine.contains("item=item-456"))
    }

    func testAuditLogLineForBelowThreshold() {
        let result = DateGuardrailResult.evaluate(
            itemId: "item-789",
            publishedAt: Date(),
            publishedAtSourceRaw: "raw_content",
            publishedAtConfidenceScore: 0.75,
            isEvergreen: false,
            publishDateMatchesIngestTimestamp: false
        )
        XCTAssertFalse(result.eligible)
        XCTAssertEqual(result.blockCode, .belowConfidenceThreshold)
        XCTAssertTrue(result.auditLogLine.contains("BELOW_CONFIDENCE_THRESHOLD"))
        XCTAssertTrue(result.auditLogLine.contains("0.75"))
    }

    // MARK: - PublishedAtConfidence Enum

    func testPublishedAtConfidenceNumericScores() {
        XCTAssertEqual(PublishedAtConfidence.high.numericScore, 0.95)
        XCTAssertEqual(PublishedAtConfidence.medium.numericScore, 0.75)
        XCTAssertEqual(PublishedAtConfidence.low.numericScore, 0.40)
    }

    func testPublishedAtConfidenceMeetsDraftingThreshold() {
        XCTAssertTrue(PublishedAtConfidence.high.meetsDraftingThreshold)
        XCTAssertFalse(PublishedAtConfidence.medium.meetsDraftingThreshold)
        XCTAssertFalse(PublishedAtConfidence.low.meetsDraftingThreshold)
    }

    // MARK: - DateGuardrailResult Codable

    func testDateGuardrailResultRoundTrip() throws {
        let result = DateGuardrailResult.evaluate(
            itemId: "item-codable",
            publishedAt: Date(),
            publishedAtSourceRaw: "raw_content",
            publishedAtConfidenceScore: 0.95,
            isEvergreen: false,
            publishDateMatchesIngestTimestamp: false
        )

        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(DateGuardrailResult.self, from: data)

        XCTAssertEqual(decoded.eligible, result.eligible)
        XCTAssertEqual(decoded.blockCode, result.blockCode)
        XCTAssertEqual(decoded.confidenceScore, result.confidenceScore, accuracy: 0.001)
        XCTAssertEqual(decoded.itemId, result.itemId)
    }

    // MARK: - Guardrail Priority (first failure wins)

    func testGuardrailEvaluatesInCorrectPriority() {
        // Item with BOTH missing date AND evergreen — should report missing date first
        let result = DateGuardrailResult.evaluate(
            itemId: nil,
            publishedAt: nil,
            publishedAtSourceRaw: "unknown",
            publishedAtConfidenceScore: 0.0,
            isEvergreen: true,
            publishDateMatchesIngestTimestamp: false
        )
        XCTAssertEqual(result.blockCode, .missingPublishDate,
                       "Missing publish date should be checked before evergreen")
    }

    func testUnknownSourceCheckedBeforeConfidence() {
        let result = DateGuardrailResult.evaluate(
            itemId: nil,
            publishedAt: Date(),
            publishedAtSourceRaw: "unknown",
            publishedAtConfidenceScore: 0.40,
            isEvergreen: false,
            publishDateMatchesIngestTimestamp: false
        )
        XCTAssertEqual(result.blockCode, .unknownSource,
                       "Unknown source should be checked before confidence threshold")
    }
}
