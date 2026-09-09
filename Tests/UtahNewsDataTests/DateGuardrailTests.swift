//
//  DateGuardrailTests.swift
//  UtahNewsDataTests
//
//  WS-B date-repair guardrail tests.
//  Covers: missing publish date, conflicting/ambiguous date, conclusive date pass-through,
//  legacy ingest timestamp present but canonical missing, and confidence threshold enforcement.
//
//  2026-09-09 — `DateGuardrailResult` and the four raw properties it reads are
//  UNCHANGED and still asserted here: they are the LEGACY WS-B audit shape and
//  they gate nothing. What changed is `isDraftEligible`, which now delegates to
//  `DraftEligibilityRule` (KNOWN-STALE => SKIP, UNKNOWN => PROCEED). Every draft
//  assertion below therefore asks `draftEligibility(now:)` with a FROZEN clock —
//  the fixtures carry February 2026 dates, so a wall-clock `now` would make
//  every one of them stale and the file would pass for the wrong reason.
//

import Foundation
import XCTest
@testable import UtahNewsData
@testable import UtahNewsDataModels

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

    /// Frozen clock. `makeSupabaseItem`'s default `processingTimestamp` is
    /// 2026-02-25T10:00:00Z and every fixture date sits within days of it, so
    /// the age limb is exact and calendar-independent.
    static let frozenNow = ISO8601DateFormatter().date(from: "2026-02-25T10:00:00Z")!

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
        XCTAssertEqual(item.draftEligibility(now: Self.frozenNow), .eligible)
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
        // 2026-09-09: a medium-confidence date is a DATE, not an absence. The
        // 0.93 floor no longer gates drafting; this row is eligible on its age.
        XCTAssertEqual(item.draftEligibility(now: Self.frozenNow), .eligible)
    }

    func testLowConfidenceBelowThreshold() {
        let item = makeSupabaseItem(
            publishedAt: "2026-02-20T08:00:00Z",
            publishedAtSource: "raw_content",
            publishedAtConfidence: "low",
            isEvergreen: false
        )
        XCTAssertEqual(item.publishedAtConfidenceScore, 0.40)
        // http_last_modified/low is 6,231 rows in 7 days (censused 2026-09-09).
        XCTAssertEqual(item.draftEligibility(now: Self.frozenNow), .eligible)
    }

    func testNilConfidenceReturnsZero() {
        let item = makeSupabaseItem(
            publishedAt: "2026-02-20T08:00:00Z",
            publishedAtSource: "raw_content",
            publishedAtConfidence: nil,
            isEvergreen: false
        )
        XCTAssertEqual(item.publishedAtConfidenceScore, 0.0)
        XCTAssertEqual(item.draftEligibility(now: Self.frozenNow), .eligible)
    }

    // MARK: - Missing Publish Date

    // 2026-09-09 — renamed. A missing publish date is UNKNOWN, and unknown
    // PROCEEDS (limb 3). Only the LEGACY DateGuardrailResult still blocks on it.
    func testMissingPublishDateIsEligibleAndOnlyTheLegacyGuardrailBlocks() {
        let item = makeSupabaseItem(
            publishedAt: nil,
            publishedAtSource: "raw_content",
            publishedAtConfidence: "high",
            isEvergreen: false
        )
        XCTAssertEqual(item.draftEligibility(now: Self.frozenNow), .eligible)

        let result = item.dateGuardrailResult
        XCTAssertFalse(result.eligible)
        XCTAssertEqual(result.blockCode, .missingPublishDate)
    }

    func testEmptyPublishDateStringIsEligible() {
        let item = makeSupabaseItem(
            publishedAt: "",
            publishedAtSource: "raw_content",
            publishedAtConfidence: "high",
            isEvergreen: false
        )
        // publishedDate parses to nil for empty string
        XCTAssertNil(item.publishedDate)
        XCTAssertEqual(item.draftEligibility(now: Self.frozenNow), .eligible)
    }

    // MARK: - Unknown Source

    // 2026-09-09 — renamed. `source == "unknown"` is the inversion spelled in
    // one word (103 rows of 423,000 over 90 days, mig 1405 s1(b)); it is
    // subsumed by limbs 2/3 and no longer refuses. The LEGACY result still blocks.
    func testUnknownSourceIsEligibleAndOnlyTheLegacyGuardrailBlocks() {
        let item = makeSupabaseItem(
            publishedAt: "2026-02-20T08:00:00Z",
            publishedAtSource: "unknown",
            publishedAtConfidence: "high",
            isEvergreen: false
        )
        XCTAssertEqual(item.draftEligibility(now: Self.frozenNow), .eligible)

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
        // Limb 1: a KNOWN classification, so refusing on it is not the inversion.
        XCTAssertEqual(item.draftEligibility(now: Self.frozenNow), .evergreen)
    }

    // MARK: - Ingest Timestamp Reuse Detection

    // 2026-09-09 — renamed. The ingest-reuse limb was DROPPED as a refusal:
    // a date equal to the ingest instant IS the crawl clock under another name.
    // It stays a DISPLAYED fact (publishDateMatchesIngestTimestamp) and a
    // LEGACY block code.
    func testPublishDateMatchingProcessingTimestampIsEligible() {
        let timestamp = "2026-02-25T10:00:00Z"
        let item = makeSupabaseItem(
            publishedAt: timestamp,
            publishedAtSource: "raw_content",
            publishedAtConfidence: "high",
            isEvergreen: false,
            processingTimestamp: timestamp
        )
        XCTAssertTrue(item.publishDateMatchesIngestTimestamp)
        XCTAssertEqual(item.draftEligibility(now: Self.frozenNow), .eligible)

        let result = item.dateGuardrailResult
        XCTAssertFalse(result.eligible)
        XCTAssertEqual(result.blockCode, .ingestTimestampReused)
    }

    func testPublishDateMatchingDiscoveredAtIsEligible() {
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
        XCTAssertEqual(item.draftEligibility(now: Self.frozenNow), .eligible)
    }

    func testPublishDateMatchingIngestedAtIsEligible() {
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
        XCTAssertEqual(item.draftEligibility(now: Self.frozenNow), .eligible)
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
        XCTAssertEqual(item.draftEligibility(now: Self.frozenNow), .eligible)

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
        XCTAssertEqual(item.draftEligibility(now: Self.frozenNow), .eligible)
    }

    // MARK: - Legacy Ingest Timestamp Present But Canonical Missing

    // 2026-09-09 — this is the ABSENT-STAMP class (mig 1105): 448 rows in the
    // trailing 7 days (censused live 2026-09-09). Limb 2 admits it.
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

        // Even though ingest timestamps exist, no canonical publish date =
        // UNKNOWN, and unknown PROCEEDS. `isEvergreenItem` still says "true"
        // because it folds in the legacy conclusive-date rule; it is not a gate.
        XCTAssertEqual(item.draftEligibility(now: Self.frozenNow), .eligible)
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

    // MARK: - DraftEligibilityRule on the item (2026-09-09)

    /// The class the inversion refused: crawl_at/inferred, 67,607 rows in the
    /// trailing 7 days (censused read-only 2026-09-09).
    func testCrawlInferredIsDraftEligibleAtAnyAge() {
        for age in ["2026-02-24T10:00:00Z", "2024-01-01T00:00:00Z"] {
            let item = makeSupabaseItem(
                publishedAt: age,
                publishedAtSource: "crawl_at",
                publishedAtConfidence: "inferred",
                isEvergreen: false
            )
            XCTAssertEqual(item.draftEligibility(now: Self.frozenNow), .eligible)
        }
    }

    /// The only date refusal: a REAL date older than Rule 11's 30-day window.
    func testKnownStaleIsNotDraftEligible() {
        let item = makeSupabaseItem(
            publishedAt: "2025-01-01T00:00:00Z",
            publishedAtSource: "byline_date_text",
            publishedAtConfidence: "medium",
            isEvergreen: false
        )
        let verdict = item.draftEligibility(now: Self.frozenNow)
        XCTAssertFalse(verdict.isEligible)
        if case .knownStale(let ageDays) = verdict {
            XCTAssertEqual(ageDays, 420)
        } else {
            XCTFail("expected knownStale, got \(verdict)")
        }
    }

    /// 30 days is inside the window; 31 is outside.
    func testDraftEligibilityWindowBoundary() {
        XCTAssertEqual(DraftEligibilityRule.maxAgeDays, 30)
        let inside = makeSupabaseItem(
            publishedAt: "2026-01-26T10:00:00Z",
            publishedAtSource: "byline_date_text",
            publishedAtConfidence: "medium",
            isEvergreen: false
        )
        XCTAssertEqual(inside.draftEligibility(now: Self.frozenNow), .eligible)

        let outside = makeSupabaseItem(
            publishedAt: "2026-01-25T10:00:00Z",
            publishedAtSource: "byline_date_text",
            publishedAtConfidence: "medium",
            isEvergreen: false
        )
        XCTAssertEqual(outside.draftEligibility(now: Self.frozenNow), .knownStale(ageDays: 31))
    }

    /// `publishedDate` falls back to `publish_date`, so limb 4 reads the better
    /// of the two dates and limb 2's absent-stamp conjunct sees the column.
    func testPublishDateFallbackFeedsTheAgeLimb() {
        let item = makeSupabaseItem(
            publishDate: "2026-02-20T08:00:00Z",
            publishedAt: nil,
            publishedAtSource: nil,
            publishedAtConfidence: nil,
            isEvergreen: nil
        )
        XCTAssertEqual(item.draftEligibility(now: Self.frozenNow), .eligible)
    }

    /// PRECEDENCE, the case the fallback test above cannot see (review F5,
    /// 2026-09-09). `publishedDate` is
    /// `SupabaseDate.parse(publishedAt) ?? SupabaseDate.parse(publishDate)`, so
    /// `published_at` WINS whenever both columns are populated. Re-measured
    /// live 2026-09-09 17:1x MDT: 48,973 rows carry BOTH columns and 612 of
    /// them straddle the 30-day boundary in OPPOSITE directions (326
    /// canonical-fresh/legacy-stale, 286 the reverse; both roll with `now()`).
    /// A reversed order would invert those verdicts silently, and every other
    /// test in this file sets one column or the other. The SQL twin of this
    /// case is mig 1417 self-test 15/16.
    func testPublishedAtWinsOverPublishDateWhenBothArePresent() {
        // canonical fresh, legacy stale => eligible, and the instant is the
        // canonical one.
        let canonicalFresh = makeSupabaseItem(
            publishDate: "2025-01-01T00:00:00Z",     // 420 d before the frozen clock
            publishedAt: "2026-02-24T10:00:00Z",     // 1 d before it
            publishedAtSource: "byline_date_text",
            publishedAtConfidence: "medium",
            isEvergreen: false
        )
        XCTAssertEqual(canonicalFresh.publishedDate,
                       ISO8601DateFormatter().date(from: "2026-02-24T10:00:00Z"))
        XCTAssertEqual(canonicalFresh.draftEligibility(now: Self.frozenNow), .eligible)

        // The mirror: a fresh `publish_date` must NOT rescue a stale
        // `published_at`.
        let canonicalStale = makeSupabaseItem(
            publishDate: "2026-02-24T10:00:00Z",
            publishedAt: "2025-01-01T00:00:00Z",
            publishedAtSource: "byline_date_text",
            publishedAtConfidence: "medium",
            isEvergreen: false
        )
        XCTAssertEqual(canonicalStale.publishedDate,
                       ISO8601DateFormatter().date(from: "2025-01-01T00:00:00Z"))
        XCTAssertEqual(canonicalStale.draftEligibility(now: Self.frozenNow),
                       .knownStale(ageDays: 420))
    }

    // MARK: - Fractional seconds (verifier Correction B, 2026-09-09)
    //
    // `publishedDate` used a BARE `ISO8601DateFormatter()` (default
    // `formatOptions`, no `.withFractionalSeconds`) while `ingestedDate` and
    // `processingDate` beside it already used `SupabaseDate.parse`. PostgREST
    // preserves stored sub-second precision, so `pipeline.processed_items`
    // returns `"2025-04-19T22:36:33.362+00:00"` for a large minority of rows
    // and every one of them parsed to `nil`. MEASURED live 2026-09-09 over
    // 7 days (134,089 rows): 2,374 fractional `published_at`, 1,329 of them
    // with no `publish_date` fallback (`publish_date` carries fractional
    // seconds on 0 rows), 1,194 of those older than 30 days.

    /// The literal string this DB returns. Before the fix this was `nil`.
    func testPublishedDateParsesFractionalSeconds() {
        let item = makeSupabaseItem(publishedAt: "2025-04-19T22:36:33.362+00:00")
        let parsed = try? XCTUnwrap(item.publishedDate)
        XCTAssertNotNil(parsed, "fractional-second published_at must parse")
        // Prove the INSTANT, not merely non-nil: 2025-04-19T22:36:33Z + 0.362 s.
        var comps = DateComponents()
        comps.year = 2025; comps.month = 4; comps.day = 19
        comps.hour = 22; comps.minute = 36; comps.second = 33
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let whole = cal.date(from: comps)!
        XCTAssertEqual(item.publishedDate!.timeIntervalSince(whole), 0.362, accuracy: 0.002)
    }

    /// The plain (whole-second) shape must still parse — the fallback leg of
    /// `SupabaseDate.parse` is the one a fractional-only formatter would break.
    func testPublishedDateStillParsesWholeSeconds() {
        XCTAssertNotNil(makeSupabaseItem(publishedAt: "2026-02-20T08:00:00+00:00").publishedDate)
        XCTAssertNotNil(makeSupabaseItem(publishedAt: "2026-02-20T08:00:00Z").publishedDate)
    }

    /// The `publish_date` fallback leg is fractional-tolerant too.
    func testPublishDateFallbackParsesFractionalSeconds() {
        let item = makeSupabaseItem(
            publishDate: "2023-08-25T23:47:22.082+00:00",
            publishedAt: nil
        )
        XCTAssertNotNil(item.publishedDate)
    }

    /// The behaviour this fix buys, stated as a contract: a fractional-second
    /// date OLDER than the 30-day window now reaches limb 4 and is refused as
    /// `knownStale`, instead of falling to limb 3 ("no date ⇒ eligible") purely
    /// because of milliseconds. This is the 1,194-rows/7 d class.
    func testFractionalSecondsDateReachesTheAgeLimb() {
        let item = makeSupabaseItem(
            publishedAt: "2025-01-01T00:00:00.123+00:00",
            publishedAtSource: "byline_date_text",
            publishedAtConfidence: "medium",
            isEvergreen: false
        )
        let verdict = item.draftEligibility(now: Self.frozenNow)
        XCTAssertFalse(verdict.isEligible)
        if case .knownStale(let ageDays) = verdict {
            XCTAssertEqual(ageDays, 420)
        } else {
            XCTFail("expected knownStale, got \(verdict)")
        }
    }

    /// A fractional-second date INSIDE the window stays eligible — the fix is
    /// not a blanket refusal of the class.
    func testFractionalSecondsFreshDateStaysEligible() {
        let item = makeSupabaseItem(
            publishedAt: "2026-02-20T08:00:00.500+00:00",
            publishedAtSource: "byline_date_text",
            publishedAtConfidence: "medium",
            isEvergreen: false
        )
        XCTAssertEqual(item.draftEligibility(now: Self.frozenNow), .eligible)
    }

    /// `discoveredDate` carried the identical bare-formatter defect one line
    /// below `publishedDate`. Inert against the live DB (`processed_items` has
    /// no `discovered_at` column, censused 2026-09-09) but fixed with it.
    func testDiscoveredDateParsesFractionalSeconds() {
        let item = makeSupabaseItem(discoveredAt: "2026-02-24T09:00:00.987+00:00")
        XCTAssertNotNil(item.discoveredDate)
        XCTAssertNotNil(makeSupabaseItem(discoveredAt: "2026-02-24T09:00:00Z").discoveredDate)
        XCTAssertNil(makeSupabaseItem(discoveredAt: nil).discoveredDate)
    }

    /// The LEGACY audit shape moves with it, by construction: a fractional
    /// high-confidence date used to be reported `missingPublishDate` because
    /// `publishedDate` was nil. Now the audit line tells the truth. Nothing
    /// takes a verdict from `DateGuardrailResult`, so this is an audit-quality
    /// change, not a gate change — but it IS a change and is asserted here.
    func testLegacyGuardrailNoLongerReportsMissingDateForFractionalSeconds() {
        let item = makeSupabaseItem(
            publishedAt: "2026-02-20T08:00:00.362+00:00",
            publishedAtSource: "multi_signal_agreement",
            publishedAtConfidence: "high",
            isEvergreen: false
        )
        let result = item.dateGuardrailResult
        XCTAssertTrue(result.eligible)
        XCTAssertNil(result.blockCode)
        XCTAssertTrue(item.hasConclusivePublishDate)
        XCTAssertFalse(item.isEvergreenItem)
    }
}
