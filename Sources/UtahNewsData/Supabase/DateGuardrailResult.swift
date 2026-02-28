//
//  DateGuardrailResult.swift
//  UtahNewsData
//
//  WS-B Date-Repair Guardrail: structured evaluation result for audit logging.
//  Captures why an item was blocked or allowed through the drafting enqueue gate.
//

import Foundation

// MARK: - Date Guardrail Result

/// Structured result from the WS-B date guardrail evaluation.
/// Used for audit logging when items are blocked or allowed through the drafting queue.
nonisolated public struct DateGuardrailResult: Sendable, Codable {

    // MARK: - Outcome

    /// Whether the item passed the guardrail and is eligible for drafting.
    public let eligible: Bool

    /// Human-readable reason for the decision (for ops logs).
    public let reason: String

    /// Machine-readable block code (nil when eligible).
    public let blockCode: BlockCode?

    /// Item ID for traceability (may be nil for in-memory payloads).
    public let itemId: String?

    /// The confidence score that was evaluated.
    public let confidenceScore: Double

    /// The minimum confidence threshold that was applied.
    public static let confidenceThreshold: Double = 0.93

    // MARK: - Block Codes

    /// Machine-readable codes for why an item was blocked.
    public enum BlockCode: String, Sendable, Codable {
        /// No canonical publish date present.
        case missingPublishDate = "MISSING_PUBLISH_DATE"
        /// Confidence score below 0.93 threshold.
        case belowConfidenceThreshold = "BELOW_CONFIDENCE_THRESHOLD"
        /// Published-at source is "unknown".
        case unknownSource = "UNKNOWN_SOURCE"
        /// Item is flagged as evergreen (no time-sensitive date).
        case evergreen = "EVERGREEN"
        /// Canonical publish date matches an ingestion/discovery timestamp (reuse detected).
        case ingestTimestampReused = "INGEST_TIMESTAMP_REUSED"
    }

    // MARK: - Factory (from SupabaseProcessedItem fields)

    /// Evaluate guardrail from Supabase processed item fields.
    public static func evaluate(
        itemId: String? = nil,
        publishedAt: Date?,
        publishedAtSourceRaw: String?,
        publishedAtConfidenceScore: Double,
        isEvergreen: Bool,
        publishDateMatchesIngestTimestamp: Bool
    ) -> DateGuardrailResult {
        // 1. Missing canonical publish date
        guard publishedAt != nil else {
            return DateGuardrailResult(
                eligible: false,
                reason: "No canonical publish date present",
                blockCode: .missingPublishDate,
                itemId: itemId,
                confidenceScore: publishedAtConfidenceScore
            )
        }

        // 2. Source is unknown
        if publishedAtSourceRaw == nil || publishedAtSourceRaw?.lowercased() == "unknown" {
            return DateGuardrailResult(
                eligible: false,
                reason: "Published-at source is unknown; cannot trust date provenance",
                blockCode: .unknownSource,
                itemId: itemId,
                confidenceScore: publishedAtConfidenceScore
            )
        }

        // 3. Confidence below threshold
        if publishedAtConfidenceScore < confidenceThreshold {
            return DateGuardrailResult(
                eligible: false,
                reason: "Confidence \(String(format: "%.2f", publishedAtConfidenceScore)) < threshold \(confidenceThreshold)",
                blockCode: .belowConfidenceThreshold,
                itemId: itemId,
                confidenceScore: publishedAtConfidenceScore
            )
        }

        // 4. Evergreen flag
        if isEvergreen {
            return DateGuardrailResult(
                eligible: false,
                reason: "Item flagged as evergreen; excluded from time-sensitive drafting queue",
                blockCode: .evergreen,
                itemId: itemId,
                confidenceScore: publishedAtConfidenceScore
            )
        }

        // 5. Ingest timestamp reuse
        if publishDateMatchesIngestTimestamp {
            return DateGuardrailResult(
                eligible: false,
                reason: "Canonical publish date matches ingestion/discovery timestamp (reuse detected)",
                blockCode: .ingestTimestampReused,
                itemId: itemId,
                confidenceScore: publishedAtConfidenceScore
            )
        }

        // All checks passed
        return DateGuardrailResult(
            eligible: true,
            reason: "Passed all WS-B date guardrails (confidence \(String(format: "%.2f", publishedAtConfidenceScore)))",
            blockCode: nil,
            itemId: itemId,
            confidenceScore: publishedAtConfidenceScore
        )
    }

    // MARK: - Factory (from V2 pipeline enums)

    /// Evaluate guardrail from FinalDataPayloadV2 enum-typed fields.
    public static func evaluate(
        publishedAt: Date?,
        publishedAtSource: PublishedAtSource,
        publishedAtConfidence: PublishedAtConfidence,
        isEvergreen: Bool,
        discoveredAt: Date,
        ingestedAt: Date
    ) -> DateGuardrailResult {
        let publishDateMatchesIngest: Bool = {
            guard let pub = publishedAt else { return false }
            return pub == discoveredAt || pub == ingestedAt
        }()

        return evaluate(
            publishedAt: publishedAt,
            publishedAtSourceRaw: publishedAtSource.rawValue,
            publishedAtConfidenceScore: publishedAtConfidence.numericScore,
            isEvergreen: isEvergreen,
            publishDateMatchesIngestTimestamp: publishDateMatchesIngest
        )
    }

    // MARK: - Audit Log Line

    /// Compact single-line audit string for os.Logger / print.
    public var auditLogLine: String {
        let status = eligible ? "PASS" : "BLOCK"
        let code = blockCode.map { "[\($0.rawValue)]" } ?? ""
        let id = itemId.map { " item=\($0)" } ?? ""
        return "[DateGuardrail] \(status)\(code)\(id) confidence=\(String(format: "%.2f", confidenceScore)) — \(reason)"
    }
}
