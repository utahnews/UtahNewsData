//
//  DraftEligibilityTests.swift
//  UtahNewsDataModelsTests
//
//  Parity with NewsCapture's `NewsCaptureTests/DraftEligibilityTests.swift`
//  (NC 9b74575, 2026-09-09) — same ten cases, same fixtures, same frozen clock.
//  Every fixture names the live provenance pair it stands for; the pairs and
//  their 7-day counts were censused read-only on 2026-09-09 (134,239 rows):
//  crawl_at/inferred 67,607 · byline_date_text/medium 24,940 ·
//  multi_signal_agreement/high 12,282 · http_last_modified/low 6,231 ·
//  og_published_time/medium 6,086 · (null)/(null) 2,958.
//

import Foundation
import Testing
@testable import UtahNewsDataModels

struct DraftEligibilityTests {

    /// Frozen so the boundary cases are exact, not calendar-dependent.
    static let now = ISO8601DateFormatter().date(from: "2026-09-09T18:00:00Z")!

    private static func daysAgo(_ days: Int) -> Date {
        now.addingTimeInterval(-Double(days) * 86_400)
    }

    // MARK: - Limb 2 — unverified provenance is ELIGIBLE

    @Test("crawl_at/inferred is eligible at 0 days AND at 200 days, case-insensitively")
    func crawlInferredIsEligible() {
        for (src, conf) in [("crawl_at", "inferred"), ("CRAWL_AT", "INFERRED")] {
            for age in [0, 200] {
                #expect(DraftEligibilityRule.evaluate(
                    publishedAt: Self.daysAgo(age),
                    publishedAtSource: src,
                    publishedAtConfidence: conf,
                    hasPublishDate: false,
                    isEvergreen: false,
                    now: Self.now
                ) == .eligible)
            }
        }
    }

    @Test("The wholly absent stamp (mig 1105) is eligible")
    func absentStampIsEligible() {
        #expect(DraftEligibilityRule.evaluate(
            publishedAt: nil,
            publishedAtSource: nil,
            publishedAtConfidence: nil,
            hasPublishDate: false,
            isEvergreen: nil,
            now: Self.now
        ) == .eligible)
    }

    @Test("A present publish_date defeats the absent-stamp limb but not limb 3")
    func publishDatePresenceIsPartOfTheAbsentStampLimb() {
        #expect(DraftEligibilityRule.hasUnverifiedDateProvenance(
            hasPublishedAt: false,
            publishedAtSource: nil,
            publishedAtConfidence: nil,
            hasPublishDate: true
        ) == false)
        // …and http_last_modified is NOT the crawl clock.
        #expect(DraftEligibilityRule.hasUnverifiedDateProvenance(
            hasPublishedAt: true,
            publishedAtSource: "http_last_modified",
            publishedAtConfidence: "low",
            hasPublishDate: false
        ) == false)
    }

    // MARK: - The dropped limbs

    @Test("Low/medium confidence no longer skips — the 0.93 floor is gone")
    func lowConfidenceIsEligible() {
        for (src, conf) in [("http_last_modified", "low"), ("unknown", "low"),
                            ("byline_date_text", "medium")] {
            #expect(DraftEligibilityRule.evaluate(
                publishedAt: Self.daysAgo(2),
                publishedAtSource: src,
                publishedAtConfidence: conf,
                hasPublishDate: false,
                isEvergreen: false,
                now: Self.now
            ) == .eligible)
        }
    }

    @Test("A date equal to the ingest instant is eligible — that IS the crawl clock")
    func ingestTimestampReuseIsEligible() {
        #expect(DraftEligibilityRule.evaluate(
            publishedAt: Self.now,
            publishedAtSource: "crawl_at",
            publishedAtConfidence: "inferred",
            hasPublishDate: false,
            isEvergreen: false,
            now: Self.now
        ) == .eligible)
    }

    // MARK: - Limb 4 — KNOWN-STALE is the only date refusal

    @Test("Publisher-dated fresh rows are eligible")
    func publisherDatedIsEligible() {
        #expect(DraftEligibilityRule.evaluate(
            publishedAt: Self.daysAgo(2), publishedAtSource: "byline_date_text",
            publishedAtConfidence: "medium", hasPublishDate: false,
            isEvergreen: false, now: Self.now) == .eligible)
        #expect(DraftEligibilityRule.evaluate(
            publishedAt: Self.daysAgo(29), publishedAtSource: "multi_signal_agreement",
            publishedAtConfidence: "high", hasPublishDate: false,
            isEvergreen: false, now: Self.now) == .eligible)
    }

    @Test("The window is 30 days; 30 is eligible and 31 is knownStale")
    func windowBoundary() {
        #expect(DraftEligibilityRule.maxAgeDays == 30)
        #expect(DraftEligibilityRule.evaluate(
            publishedAt: Self.daysAgo(30), publishedAtSource: "byline_date_text",
            publishedAtConfidence: "medium", hasPublishDate: false,
            isEvergreen: false, now: Self.now) == .eligible)
        #expect(DraftEligibilityRule.evaluate(
            publishedAt: Self.daysAgo(31), publishedAtSource: "byline_date_text",
            publishedAtConfidence: "medium", hasPublishDate: false,
            isEvergreen: false, now: Self.now) == .knownStale(ageDays: 31))
    }

    @Test("A 400-day-old real date is refused and the label carries the number")
    func knownStaleIsNotEligible() {
        let verdict = DraftEligibilityRule.evaluate(
            publishedAt: Self.daysAgo(400), publishedAtSource: "byline_date_text",
            publishedAtConfidence: "medium", hasPublishDate: false,
            isEvergreen: false, now: Self.now)
        #expect(verdict == .knownStale(ageDays: 400))
        #expect(verdict.isEligible == false)
        #expect(verdict.shortReason.contains("400"))
    }

    @Test("Age alone condemns — trusted provenance does not rescue a stale date")
    func staleTrustedProvenanceIsNotEligible() {
        #expect(DraftEligibilityRule.evaluate(
            publishedAt: Self.daysAgo(90), publishedAtSource: "multi_signal_agreement",
            publishedAtConfidence: "high", hasPublishDate: false,
            isEvergreen: false, now: Self.now) == .knownStale(ageDays: 90))
    }

    // MARK: - Limb 1 — evergreen

    @Test("Evergreen is refused; nil and false proceed; evergreen beats limb 2")
    func evergreenIsNotEligible() {
        #expect(DraftEligibilityRule.evaluate(
            publishedAt: Self.daysAgo(1), publishedAtSource: "byline_date_text",
            publishedAtConfidence: "medium", hasPublishDate: false,
            isEvergreen: true, now: Self.now) == .evergreen)
        for flag: Bool? in [nil, false] {
            #expect(DraftEligibilityRule.evaluate(
                publishedAt: Self.daysAgo(1), publishedAtSource: "byline_date_text",
                publishedAtConfidence: "medium", hasPublishDate: false,
                isEvergreen: flag, now: Self.now) == .eligible)
        }
        #expect(DraftEligibilityRule.evaluate(
            publishedAt: Self.daysAgo(1), publishedAtSource: "crawl_at",
            publishedAtConfidence: "inferred", hasPublishDate: false,
            isEvergreen: true, now: Self.now) == .evergreen)
    }

    // MARK: - Twin parity

    @Test("ageInDays floors at 0 and is whole days, matching SourceContentDateResolver")
    func ageInDaysMatchesTheNewsCaptureTwin() {
        #expect(DraftEligibilityRule.ageInDays(of: Self.daysAgo(0), today: Self.now) == 0)
        #expect(DraftEligibilityRule.ageInDays(of: Self.now.addingTimeInterval(3600), today: Self.now) == 0)
        #expect(DraftEligibilityRule.ageInDays(of: Self.daysAgo(31), today: Self.now) == 31)
    }
}
