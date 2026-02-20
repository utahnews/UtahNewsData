//
//  CitizenJournalismModels.swift
//  UtahNewsDataModels
//
//  Shared data models for citizen journalism contributions, AI-journalist interviews,
//  story versioning, contributor profiles, and submission review pipeline.
//
//  Extracted from UtahNews app and promoted to the shared package so that
//  UtahNews, NewsCapture, V2PipelineTester, and any future apps can all
//  read and write UserContribution data without duplicating model definitions.
//
//  BACKWARD-COMPAT NOTE: Do NOT remove or rename any existing property.
//  Only additive changes (new optional properties, new enum cases) are safe.
//

import Foundation

// MARK: - Contribution Status

/// Lifecycle state of a citizen-journalism contribution as it moves through
/// the editorial pipeline.
///
/// Cases:
/// - `pending`      – submitted, awaiting any processing
/// - `aiReview`     – currently being evaluated by an AI triage agent
/// - `corroborated` – at least one independent source has confirmed the claim(s)
/// - `humanReview`  – flagged for human-editor review (keep for UtahNews compatibility)
/// - `approved`     – editorial review passed; ready for publication queue
/// - `rejected`     – rejected by AI or human review; not published
/// - `published`    – live on the platform
public enum ContributionStatus: String, Codable, Sendable, CaseIterable {
    case pending
    case aiReview
    case corroborated
    case humanReview   // retained for backward-compat with existing UtahNews code
    case approved
    case rejected
    case published
}

// MARK: - Draft Status

/// Tracks the lifecycle of a generated draft article produced from a citizen interview.
public enum DraftStatus: String, Codable, Sendable, CaseIterable {
    /// No draft generated yet.
    case none
    /// Foundation Models (or other AI) is actively generating the draft.
    case generating
    /// Draft ready for the contributor to review.
    case ready
    /// Contributor submitted the draft for editorial review.
    case submitted
    /// Editorial team published the draft to the main feed.
    case published
    /// Editorial team rejected the draft.
    case rejected
}

// MARK: - Claim Category

/// Classifies the epistemic nature of an extracted claim.
public enum ClaimCategory: String, Codable, Sendable, CaseIterable {
    case eyewitness
    case hearsay
    case factual
    case opinion
    case correction
}

// MARK: - Submission Type

/// The medium through which a citizen submitted their contribution.
public enum SubmissionType: String, Codable, Sendable, CaseIterable {
    case interview
    case tip
    case photo
    case document
}

// MARK: - Version Trigger Type

/// What caused a new story-version to be created.
public enum VersionTriggerType: String, Codable, Sendable, CaseIterable {
    case editorial
    case aiEnhanced
    case communityContribution
}

// MARK: - Review Stage

/// The current stage in the multi-step submission-review pipeline.
public enum ReviewStage: String, Codable, Sendable, CaseIterable {
    case aiTriage
    case corroboration
    case confidenceScoring
    case humanReview
    case complete
}

// MARK: - Review Decision

/// The editorial decision at any given review stage.
public enum ReviewDecision: String, Codable, Sendable, CaseIterable {
    case pending
    case approved
    case rejected
    case needsMoreInfo
}

// MARK: - Tool Usage

/// Tracks a single invocation of an AI journalist tool during an interview session.
public struct ToolUsage: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let toolName: String
    public let timestamp: Date
    public let arguments: String
    public let result: String?
    public let executionTime: TimeInterval

    public init(
        id: String = UUID().uuidString,
        toolName: String,
        arguments: String,
        result: String? = nil,
        executionTime: TimeInterval = 0
    ) {
        self.id = id
        self.toolName = toolName
        self.timestamp = Date()
        self.arguments = arguments
        self.result = result
        self.executionTime = executionTime
    }
}

// MARK: - Uploaded Photo

/// A photo uploaded by a citizen reporter during an interview session.
public struct UploadedPhoto: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let url: String
    public let description: String
    public let suggestedCaptions: [String]

    public init(
        id: String = UUID().uuidString,
        url: String,
        description: String = "",
        suggestedCaptions: [String] = []
    ) {
        self.id = id
        self.url = url
        self.description = description
        self.suggestedCaptions = suggestedCaptions
    }
}

// MARK: - Interview Transcript

/// A full record of a citizen-journalist AI-interview session including
/// the conversation entries and any tool invocations.
public struct InterviewTranscript: Codable, Hashable, Sendable {

    // MARK: Nested Types

    public struct Entry: Identifiable, Codable, Hashable, Sendable {
        public let id: String
        public let speaker: Speaker
        public let text: String
        public let timestamp: Date

        public init(
            id: String = UUID().uuidString,
            speaker: Speaker,
            text: String,
            timestamp: Date = Date()
        ) {
            self.id = id
            self.speaker = speaker
            self.text = text
            self.timestamp = timestamp
        }
    }

    public enum Speaker: String, Codable, Sendable {
        case user
        case assistant

        public var displayName: String {
            switch self {
            case .user:      return "Reporter"
            case .assistant: return "UtahNews Journalist"
            }
        }

        public var icon: String {
            switch self {
            case .user:      return "person.circle.fill"
            case .assistant: return "newspaper.fill"
            }
        }
    }

    // MARK: Properties

    public var entries: [Entry]
    public var toolUsages: [ToolUsage]

    // MARK: Init

    public init(entries: [Entry] = [], toolUsages: [ToolUsage] = []) {
        self.entries = entries
        self.toolUsages = toolUsages
    }

    // MARK: Helpers

    public mutating func addEntry(speaker: Speaker, text: String) {
        entries.append(Entry(speaker: speaker, text: text, timestamp: Date()))
    }

    public mutating func addToolUsage(_ toolUsage: ToolUsage) {
        toolUsages.append(toolUsage)
    }

    public var formattedTranscript: String {
        entries.map { "\($0.speaker.displayName): \($0.text)" }.joined(separator: "\n\n")
    }

    public func formatForStoryGeneration() -> String {
        entries.map { entry in
            let ts = DateFormatter.localizedString(
                from: entry.timestamp, dateStyle: .none, timeStyle: .medium)
            return "[\(ts)] \(entry.speaker.displayName.uppercased()): \(entry.text)"
        }.joined(separator: "\n\n")
    }
}

// MARK: - Interview Metadata

/// Structured context captured before / during a citizen-journalist interview.
public struct InterviewMetadata: Codable, Hashable, Sendable {

    // MARK: Nested Type

    public enum StoryCategory: String, Codable, CaseIterable, Sendable {
        case general      = "General"
        case breaking     = "Breaking News"
        case community    = "Community"
        case crime        = "Crime & Safety"
        case education    = "Education"
        case environment  = "Environment"
        case government   = "Government & Politics"
        case health       = "Health"
        case business     = "Business"
        case sports       = "Sports"
        case culture      = "Arts & Culture"
        case weather      = "Weather"
        case traffic      = "Traffic & Transportation"
        case development  = "Development"
    }

    // MARK: Properties

    public var intervieweeName: String
    public var intervieweeTitle: String
    public var intervieweeOrganization: String
    public var interviewDate: Date
    public var interviewLocation: String
    public var storyCategory: StoryCategory
    public var backgroundContext: String
    public var keyQuestions: [String]
    public var uploadedPhotos: [UploadedPhoto]

    // MARK: Init

    public init(
        intervieweeName: String = "",
        intervieweeTitle: String = "",
        intervieweeOrganization: String = "",
        interviewDate: Date = Date(),
        interviewLocation: String = "",
        storyCategory: StoryCategory = .general,
        backgroundContext: String = "",
        keyQuestions: [String] = [],
        uploadedPhotos: [UploadedPhoto] = []
    ) {
        self.intervieweeName = intervieweeName
        self.intervieweeTitle = intervieweeTitle
        self.intervieweeOrganization = intervieweeOrganization
        self.interviewDate = interviewDate
        self.interviewLocation = interviewLocation
        self.storyCategory = storyCategory
        self.backgroundContext = backgroundContext
        self.keyQuestions = keyQuestions
        self.uploadedPhotos = uploadedPhotos
    }
}

// MARK: - Extracted Claim

/// A single factual claim extracted from a contribution, with corroboration metadata.
public struct ExtractedClaim: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public let text: String
    public let category: ClaimCategory
    public let confidence: Double
    public let corroboratedBy: [String]
    public let contradictedBy: [String]
    public let sourceCount: Int
    public let includedInArticle: Bool

    enum CodingKeys: String, CodingKey {
        case id, text, category, confidence
        case corroboratedBy    = "corroborated_by"
        case contradictedBy    = "contradicted_by"
        case sourceCount       = "source_count"
        case includedInArticle = "included_in_article"
    }

    public init(
        id: UUID = UUID(),
        text: String,
        category: ClaimCategory,
        confidence: Double,
        corroboratedBy: [String] = [],
        contradictedBy: [String] = [],
        sourceCount: Int = 0,
        includedInArticle: Bool = false
    ) {
        self.id = id
        self.text = text
        self.category = category
        self.confidence = confidence
        self.corroboratedBy = corroboratedBy
        self.contradictedBy = contradictedBy
        self.sourceCount = sourceCount
        self.includedInArticle = includedInArticle
    }

    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: ExtractedClaim, rhs: ExtractedClaim) -> Bool { lhs.id == rhs.id }
}

// MARK: - User Contribution

/// A citizen-journalist contribution that has been submitted to the editorial pipeline.
///
/// This is the primary shared model.  All apps that participate in the contribution
/// workflow (UtahNews consumer-facing, NewsCapture capture tool, V2PipelineTester)
/// should use this type rather than maintaining their own copies.
public struct UserContribution: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public let userId: String
    public let displayName: String
    public let articleId: String?
    public let submissionType: SubmissionType
    public let transcript: InterviewTranscript
    public let metadata: InterviewMetadata
    public let status: ContributionStatus
    public let confidenceScore: Double?
    public let corroborationCount: Int
    public let claims: [ExtractedClaim]
    public let latitude: Double?
    public let longitude: Double?
    public let city: String?
    public let state: String?
    public let createdAt: Date
    public let updatedAt: Date

    // Draft article fields – added in a later migration; optional for back-compat.
    public let draftArticleId: String?
    public let draftStatus: DraftStatus

    enum CodingKeys: String, CodingKey {
        case id
        case userId              = "user_id"
        case displayName         = "display_name"
        case articleId           = "article_id"
        case submissionType      = "submission_type"
        case transcript, metadata, status
        case confidenceScore     = "confidence_score"
        case corroborationCount  = "corroboration_count"
        case claims, latitude, longitude, city, state
        case createdAt           = "created_at"
        case updatedAt           = "updated_at"
        case draftArticleId      = "draft_article_id"
        case draftStatus         = "draft_status"
    }

    public init(
        id: UUID = UUID(),
        userId: String,
        displayName: String,
        articleId: String? = nil,
        submissionType: SubmissionType,
        transcript: InterviewTranscript,
        metadata: InterviewMetadata,
        status: ContributionStatus = .pending,
        confidenceScore: Double? = nil,
        corroborationCount: Int = 0,
        claims: [ExtractedClaim] = [],
        latitude: Double? = nil,
        longitude: Double? = nil,
        city: String? = nil,
        state: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        draftArticleId: String? = nil,
        draftStatus: DraftStatus = .none
    ) {
        self.id = id
        self.userId = userId
        self.displayName = displayName
        self.articleId = articleId
        self.submissionType = submissionType
        self.transcript = transcript
        self.metadata = metadata
        self.status = status
        self.confidenceScore = confidenceScore
        self.corroborationCount = corroborationCount
        self.claims = claims
        self.latitude = latitude
        self.longitude = longitude
        self.city = city
        self.state = state
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.draftArticleId = draftArticleId
        self.draftStatus = draftStatus
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                 = try c.decode(UUID.self,                 forKey: .id)
        userId             = try c.decode(String.self,               forKey: .userId)
        displayName        = try c.decode(String.self,               forKey: .displayName)
        articleId          = try c.decodeIfPresent(String.self,      forKey: .articleId)
        submissionType     = try c.decode(SubmissionType.self,       forKey: .submissionType)
        transcript         = try c.decode(InterviewTranscript.self,  forKey: .transcript)
        metadata           = try c.decode(InterviewMetadata.self,    forKey: .metadata)
        status             = try c.decode(ContributionStatus.self,   forKey: .status)
        confidenceScore    = try c.decodeIfPresent(Double.self,      forKey: .confidenceScore)
        corroborationCount = try c.decode(Int.self,                  forKey: .corroborationCount)
        claims             = try c.decode([ExtractedClaim].self,     forKey: .claims)
        latitude           = try c.decodeIfPresent(Double.self,      forKey: .latitude)
        longitude          = try c.decodeIfPresent(Double.self,      forKey: .longitude)
        city               = try c.decodeIfPresent(String.self,      forKey: .city)
        state              = try c.decodeIfPresent(String.self,      forKey: .state)
        createdAt          = try c.decode(Date.self,                 forKey: .createdAt)
        updatedAt          = try c.decode(Date.self,                 forKey: .updatedAt)
        draftArticleId     = try c.decodeIfPresent(String.self,      forKey: .draftArticleId)
        draftStatus        = try c.decodeIfPresent(DraftStatus.self, forKey: .draftStatus) ?? .none
    }

    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: UserContribution, rhs: UserContribution) -> Bool { lhs.id == rhs.id }
}

// MARK: - Story Version

/// An immutable snapshot of a story at a particular point in time.
public struct StoryVersion: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let articleId: String
    public let versionNumber: Int
    public let title: String
    public let textContent: String
    public let summary: String
    public let contributorIds: [String]
    public let changes: String
    public let triggerType: VersionTriggerType
    public let previousVersionId: String?
    public let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, summary, changes
        case articleId         = "article_id"
        case versionNumber     = "version_number"
        case textContent       = "text_content"
        case contributorIds    = "contributor_ids"
        case triggerType       = "trigger_type"
        case previousVersionId = "previous_version_id"
        case createdAt         = "created_at"
    }

    public init(
        id: String = UUID().uuidString,
        articleId: String,
        versionNumber: Int,
        title: String,
        textContent: String,
        summary: String,
        contributorIds: [String] = [],
        changes: String,
        triggerType: VersionTriggerType,
        previousVersionId: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.articleId = articleId
        self.versionNumber = versionNumber
        self.title = title
        self.textContent = textContent
        self.summary = summary
        self.contributorIds = contributorIds
        self.changes = changes
        self.triggerType = triggerType
        self.previousVersionId = previousVersionId
        self.createdAt = createdAt
    }

    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: StoryVersion, rhs: StoryVersion) -> Bool { lhs.id == rhs.id }
}

// MARK: - Contributor Profile

/// Reputation and statistics for a registered citizen journalist.
public struct ContributorProfile: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let displayName: String
    public let totalContributions: Int
    public let acceptedContributions: Int
    public let credibilityScore: Double
    public let badges: [String]
    public let joinedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, badges
        case displayName          = "display_name"
        case totalContributions   = "total_contributions"
        case acceptedContributions = "accepted_contributions"
        case credibilityScore     = "credibility_score"
        case joinedAt             = "joined_at"
    }

    public init(
        id: String,
        displayName: String,
        totalContributions: Int = 0,
        acceptedContributions: Int = 0,
        credibilityScore: Double = 0.5,
        badges: [String] = [],
        joinedAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.totalContributions = totalContributions
        self.acceptedContributions = acceptedContributions
        self.credibilityScore = credibilityScore
        self.badges = badges
        self.joinedAt = joinedAt
    }

    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: ContributorProfile, rhs: ContributorProfile) -> Bool { lhs.id == rhs.id }
}

// MARK: - Submission Review

/// A review record tracking an individual contribution through the editorial pipeline.
public struct SubmissionReview: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public let contributionId: String
    public let stage: ReviewStage
    public let aiTriageResult: String?
    public let corroborationResult: String?
    public let confidenceResult: Double?
    public let humanReviewerId: String?
    public let humanReviewNotes: String?
    public let decision: ReviewDecision
    public let createdAt: Date
    public let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, stage, decision
        case contributionId       = "contribution_id"
        case aiTriageResult       = "ai_triage_result"
        case corroborationResult  = "corroboration_result"
        case confidenceResult     = "confidence_result"
        case humanReviewerId      = "human_reviewer_id"
        case humanReviewNotes     = "human_review_notes"
        case createdAt            = "created_at"
        case updatedAt            = "updated_at"
    }

    public init(
        id: UUID = UUID(),
        contributionId: String,
        stage: ReviewStage = .aiTriage,
        aiTriageResult: String? = nil,
        corroborationResult: String? = nil,
        confidenceResult: Double? = nil,
        humanReviewerId: String? = nil,
        humanReviewNotes: String? = nil,
        decision: ReviewDecision = .pending,
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

    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: SubmissionReview, rhs: SubmissionReview) -> Bool { lhs.id == rhs.id }
}
