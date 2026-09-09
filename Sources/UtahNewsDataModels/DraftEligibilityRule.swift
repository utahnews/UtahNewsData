//
//  DraftEligibilityRule.swift
//  UtahNewsDataModels
//
//  The ONE definition of "may this processed_item be drafted?" in the shared
//  package. Swift twin of NewsCapture's `DraftEligibility` (NC 9b74575,
//  2026-09-09) — same four limbs, same order, same words.
//
//  WHY `Rule` IS IN THE NAME (review F6, 2026-09-09). `UtahNewsDataModels` is
//  `@_exported` by `UtahNewsData` (`Sources/UtahNewsData/Exports.swift`), so
//  this type reaches every `import UtahNewsData` consumer unqualified — and
//  NewsCapture ALREADY declares its own `DraftEligibility`
//  (`NewsCapture/Services/DraftEligibility.swift`) with its own nested
//  `Verdict`, the type `ProcessedItemsError.draftIneligible(_:)` is written
//  against. Module-local lookup should shadow the imported name, but no lane
//  can compile NewsCapture against a tag that does not exist yet, so the
//  collision is AVOIDED by name rather than relied upon to resolve. When
//  NewsCapture's copy is collapsed into this one it becomes
//  `typealias DraftEligibility = DraftEligibilityRule` and there is one text.
//
//  WHAT WAS WRONG. `SupabaseProcessedItem.isDraftEligible` was
//
//      !isEvergreenItem && !publishDateMatchesIngestTimestamp
//
//  where `isEvergreenItem` folds in `hasConclusivePublishDate`
//  (`publishedDate != nil && source != "unknown" && confidenceScore >= 0.93`).
//  Only `high` scores 0.95 on that scale, so the rule refused every
//  medium-confidence publisher date, every low-confidence date, and — because
//  `inferred` maps to 0.0 — the ENTIRE `crawl_at`/`inferred` class. That is
//  literally UNKNOWN ⇒ SKIP. The platform's law is the opposite and is stated
//  in `MultiSourceFreshnessGate` ("known-stale ⇒ skip, unknown ⇒ PROCEED"),
//  `StalenessRule11Gate` ("NULL date ⇒ return nil") and board arm
//  `undated_drafts_floor_deficit_24h` (mig 641), whose whole job is to fire
//  when the undated class stops being drafted.
//
//  MEASURED read-only on the live DB 2026-09-09 (7 d of `pipeline.
//  processed_items`, 134,239 rows): 67,609 carry `crawl_at`/`inferred`, 448
//  carry no date stamp at all. The old rule calls 16,515 rows eligible; this
//  rule calls 76,226 eligible. The difference — 59,711 rows in seven days — is
//  the protected class the inversion refused.
//
//  THE RULE, in the platform's own vocabulary:
//
//    1. EVERGREEN ⇒ ineligible. A KNOWN classification V2 stamped
//       (`is_evergreen = true`), not a missing one, so refusing on it is not
//       the forbidden inversion. `isEvergreen == nil` is unknown and PROCEEDS.
//    2. UNVERIFIED PROVENANCE ⇒ ELIGIBLE. `crawl_at`/`inferred` (mig 546) or an
//       entirely absent stamp (mig 1105). Checked BEFORE the age rule on
//       purpose: a crawl stamp is OUR clock, so an OLD crawl stamp is evidence
//       about when we fetched the page and no evidence at all about when it was
//       published. Condemning it for age would be judging our own timestamp.
//    3. NO DATE AT ALL ⇒ ELIGIBLE (unknown ⇒ proceed).
//    4. KNOWN-STALE ⇒ INELIGIBLE. A real date older than Rule 11's window
//       (30 days, mig 539). Age alone condemns, with no provenance/confidence
//       narrowing — B2 Change D (2026-07-29) removed that narrowing after
//       measuring 0 published of 9,506 archival drafts across EVERY provenance
//       class.
//
//  WHAT WAS DELIBERATELY DROPPED (identical to NewsCapture's list):
//    • the 0.93 confidence floor — a low-confidence date is an UNKNOWN date,
//      and Rule 11 stopped reading confidence in 2026-07-29's B2 Change D;
//    • `published_at_source == "unknown"` — the inversion spelled in one word;
//    • the ingest-timestamp-reuse limb — that IS the crawl clock under another
//      name, and a date equal to the ingest instant is never old enough to trip
//      limb 4. `SupabaseProcessedItem.publishDateMatchesIngestTimestamp` is
//      KEPT as a DISPLAYED fact (it tells an editor the date is machine-made);
//      it is no longer a refusal.
//
//  NOT A PUBLISH GATE. Nothing here admits anything: the canonical,
//  unbypassable refusals are the DB triggers (`articles_publish_gate`,
//  `articles_staleness_gate`, `articles_unverified_date_gate*`). This is a
//  candidate-side predicate and an editor-facing verdict, and it is
//  deliberately a SUPERSET of what those gates allow through.
//
//  TWINS THAT MUST MOVE TOGETHER (change one, change all):
//    • NewsCapture `Services/DraftEligibility.swift` — the same four limbs;
//    • NewsCapture `Services/CrawlInferredDateGate.hasUnverifiedDateProvenance`
//      — the same provenance predicate;
//    • NewsCapture `Services/StalenessRule11Gate.maxAgeDays` = 30;
//    • NewsCapture `Services/SourceContentDateResolver.ageInDays`.
//  `UtahNewsData.DateGuardrailResult` is the LEGACY WS-B shape and is NOT a
//  twin: it still carries the 0.93 floor and is kept only as an audit/ops log
//  line. It gates nothing.
//

import Foundation

/// Draft eligibility. Pure, `nonisolated`, no I/O — safe from any actor, and
/// identical in the daemon and the app.
public nonisolated enum DraftEligibilityRule {

    /// Why an item may or may not be drafted. Carries the reason so an
    /// editor-facing label can be truthful instead of a bare "No".
    public enum Verdict: Equatable, Sendable {
        /// Draft it. Includes every UNKNOWN-date shape, by law.
        case eligible
        /// A real publication date older than Rule 11's window.
        case knownStale(ageDays: Int)
        /// V2 classified the item as evergreen.
        case evergreen

        public var isEligible: Bool { self == .eligible }

        /// One short clause for a metadata cell. Never claims more than the
        /// verdict knows.
        public var shortReason: String {
            switch self {
            case .eligible:
                return "Yes"
            case .knownStale(let ageDays):
                return "No — dated \(ageDays) days ago (older than Rule 11's \(DraftEligibilityRule.maxAgeDays)-day window)"
            case .evergreen:
                return "No — classified evergreen"
            }
        }
    }

    /// Rule 11's window (mig 539). NewsCapture's `StalenessRule11Gate.maxAgeDays`
    /// is the twin — move both together.
    public static let maxAgeDays = 30

    /// Whole days between `date` and `today`, floored at 0. Byte-identical to
    /// NewsCapture's `SourceContentDateResolver.ageInDays`.
    public static func ageInDays(of date: Date, today: Date = Date()) -> Int {
        max(0, Int(today.timeIntervalSince(date) / 86_400))
    }

    /// The provenance predicate: is this row's date OUR clock, or absent?
    ///
    /// Byte-identical to NewsCapture's
    /// `CrawlInferredDateGate.hasUnverifiedDateProvenance(hasPublishedAt:…)`.
    /// The predicate needs only PRESENCE from the two date columns, so the
    /// parameters are `Bool`s and the caller's date type (`String?` off
    /// PostgREST, `Date?` after decoding) cannot fork the rule.
    public static func hasUnverifiedDateProvenance(
        hasPublishedAt: Bool,
        publishedAtSource: String?,
        publishedAtConfidence: String?,
        hasPublishDate: Bool
    ) -> Bool {
        if publishedAtSource?.lowercased() == "crawl_at"
            && publishedAtConfidence?.lowercased() == "inferred" {
            return true
        }
        return !hasPublishedAt
            && publishedAtSource == nil
            && publishedAtConfidence == nil
            && !hasPublishDate
    }

    /// The one draft-eligibility rule.
    ///
    /// - Parameters:
    ///   - publishedAt: the item's publication date as the caller resolves it.
    ///   - publishedAtSource / publishedAtConfidence: the row's date provenance.
    ///   - hasPublishDate: whether `processed_items.publish_date` is present.
    ///     A caller that does not select that column passes `false`, which can
    ///     only widen limb 2 and can never turn an eligible item ineligible.
    ///   - isEvergreen: `processed_items.is_evergreen`; `nil` is unknown.
    ///   - now: injected for tests; defaults to the wall clock.
    public static func evaluate(
        publishedAt: Date?,
        publishedAtSource: String?,
        publishedAtConfidence: String?,
        hasPublishDate: Bool,
        isEvergreen: Bool?,
        now: Date = Date()
    ) -> Verdict {
        // 1. A KNOWN classification, not a missing one.
        if isEvergreen == true { return .evergreen }

        // 2. UNKNOWN ⇒ PROCEED, and before the age rule: an old crawl stamp
        //    dates OUR fetch, not the story.
        if hasUnverifiedDateProvenance(
            hasPublishedAt: publishedAt != nil,
            publishedAtSource: publishedAtSource,
            publishedAtConfidence: publishedAtConfidence,
            hasPublishDate: hasPublishDate
        ) {
            return .eligible
        }

        // 3. No date at all is still UNKNOWN.
        guard let publishedAt else { return .eligible }

        // 4. KNOWN-STALE ⇒ SKIP. Age alone condemns (B2 Change D).
        let ageDays = ageInDays(of: publishedAt, today: now)
        if ageDays > maxAgeDays { return .knownStale(ageDays: ageDays) }

        return .eligible
    }

    /// Boolean convenience for call sites that only branch.
    public static func isEligible(
        publishedAt: Date?,
        publishedAtSource: String?,
        publishedAtConfidence: String?,
        hasPublishDate: Bool,
        isEvergreen: Bool?,
        now: Date = Date()
    ) -> Bool {
        evaluate(
            publishedAt: publishedAt,
            publishedAtSource: publishedAtSource,
            publishedAtConfidence: publishedAtConfidence,
            hasPublishDate: hasPublishDate,
            isEvergreen: isEvergreen,
            now: now
        ).isEligible
    }
}
