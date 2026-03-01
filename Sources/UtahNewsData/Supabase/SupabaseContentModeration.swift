//
//  SupabaseContentModeration.swift
//  UtahNewsData
//
//  Content moderation models for user submissions and community posts.
//  Maps to pipeline.submission_reviews and supports the AI triage workflow.
//

import Foundation

// MARK: - Submission Review

/// A row from the `pipeline.submission_reviews` table.
///
/// Tracks a user contribution through the moderation pipeline:
/// aiTriage → corroboration → confidenceScoring → humanReview → complete
nonisolated public struct SupabaseSubmissionReview: Codable, Sendable, Identifiable {
    public let id: String
    public let contributionId: String
    public var stage: String
    public var aiTriageResult: String?
    public var corroborationResult: String?
    public var confidenceResult: Double?
    public var humanReviewerId: String?
    public var humanReviewNotes: String?
    public var decision: String
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        contributionId: String,
        stage: String = ReviewStage.aiTriage,
        aiTriageResult: String? = nil,
        corroborationResult: String? = nil,
        confidenceResult: Double? = nil,
        humanReviewerId: String? = nil,
        humanReviewNotes: String? = nil,
        decision: String = ReviewDecision.pending,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.contributionId = contributionId
        self.stage = stage
        self.aiTriageResult = aiTriageResult
        self.corroborationResult = corroborationResult
        self.confidenceResult = confidenceResult
        self.humanReviewerId = humanReviewerId
        self.humanReviewNotes = humanReviewNotes
        self.decision = decision
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, stage, decision
        case contributionId = "contribution_id"
        case aiTriageResult = "ai_triage_result"
        case corroborationResult = "corroboration_result"
        case confidenceResult = "confidence_result"
        case humanReviewerId = "human_reviewer_id"
        case humanReviewNotes = "human_review_notes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Review Stage Constants

extension SupabaseSubmissionReview {
    /// Well-known review stage names
    nonisolated public enum ReviewStage {
        public static let aiTriage = "aiTriage"
        public static let corroboration = "corroboration"
        public static let confidenceScoring = "confidenceScoring"
        public static let humanReview = "humanReview"
        public static let complete = "complete"
    }

    /// Well-known review decision values
    nonisolated public enum ReviewDecision {
        public static let pending = "pending"
        public static let approved = "approved"
        public static let rejected = "rejected"
        public static let needsMoreInfo = "needsMoreInfo"
    }
}

// MARK: - Submission Review Insert

nonisolated public struct SupabaseSubmissionReviewInsert: Codable, Sendable {
    public let contributionId: String
    public var stage: String
    public var aiTriageResult: String?
    public var decision: String

    public init(
        contributionId: String,
        stage: String = SupabaseSubmissionReview.ReviewStage.aiTriage,
        aiTriageResult: String? = nil,
        decision: String = SupabaseSubmissionReview.ReviewDecision.pending
    ) {
        self.contributionId = contributionId
        self.stage = stage
        self.aiTriageResult = aiTriageResult
        self.decision = decision
    }

    enum CodingKeys: String, CodingKey {
        case stage, decision
        case contributionId = "contribution_id"
        case aiTriageResult = "ai_triage_result"
    }
}

// MARK: - Discussion Post Moderation

/// Moderation status for community discussion posts.
///
/// Maps to the `moderation_notes` and status fields in `pipeline.discussion_posts`.
nonisolated public struct DiscussionModerationAction: Codable, Sendable {
    public let postId: String
    public var status: String
    public var moderationNotes: String?
    public var moderatorId: String?

    public init(
        postId: String,
        status: String,
        moderationNotes: String? = nil,
        moderatorId: String? = nil
    ) {
        self.postId = postId
        self.status = status
        self.moderationNotes = moderationNotes
        self.moderatorId = moderatorId
    }
}

extension DiscussionModerationAction {
    /// Well-known post status values
    nonisolated public enum PostStatus {
        public static let active = "active"
        public static let hidden = "hidden"
        public static let deleted = "deleted"
        public static let flagged = "flagged"
    }
}

// MARK: - Content Safety Check Result

/// Result of an AI content safety evaluation.
///
/// Used by the moderation pipeline to screen user submissions
/// and community posts before they become visible.
nonisolated public struct ContentSafetyResult: Codable, Sendable {
    /// Whether the content passed safety checks
    public let isSafe: Bool

    /// Confidence in the safety assessment (0.0 to 1.0)
    public let confidence: Double

    /// Detected category flags (spam, harassment, misinformation, etc.)
    public let flags: [String]

    /// Human-readable explanation of the assessment
    public let explanation: String?

    /// Recommended action: approve, flag_for_review, reject
    public let recommendedAction: String

    public init(
        isSafe: Bool,
        confidence: Double,
        flags: [String] = [],
        explanation: String? = nil,
        recommendedAction: String = "approve"
    ) {
        self.isSafe = isSafe
        self.confidence = confidence
        self.flags = flags
        self.explanation = explanation
        self.recommendedAction = recommendedAction
    }

    enum CodingKeys: String, CodingKey {
        case isSafe = "is_safe"
        case confidence, flags, explanation
        case recommendedAction = "recommended_action"
    }
}

extension ContentSafetyResult {
    nonisolated public enum Action {
        public static let approve = "approve"
        public static let flagForReview = "flag_for_review"
        public static let reject = "reject"
    }

    nonisolated public enum Flag {
        public static let spam = "spam"
        public static let harassment = "harassment"
        public static let misinformation = "misinformation"
        public static let hateSpeech = "hate_speech"
        public static let personalInfo = "personal_info"
        public static let copyright = "copyright"
        public static let offTopic = "off_topic"
    }
}
