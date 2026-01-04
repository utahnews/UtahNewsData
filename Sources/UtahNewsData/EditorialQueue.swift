//
//  EditorialQueue.swift
//  UtahNewsData
//
//  Models for the editorial queue workflow.
//  Bridges processed_items_v2 content to NewsCapture for editorial review.
//

@preconcurrency import FirebaseFirestore
import Foundation

// MARK: - Editorial Queue Item

/// Represents an item in the editorial queue for staff review
/// Stored in Firestore `editorialQueue` collection
public struct EditorialQueueItem: Identifiable, Codable, Sendable {
    /// Document ID
    @DocumentID public var id: String?

    /// Reference to processed_items_v2 document ID
    public let processedItemId: String

    /// Original source URL
    public let url: String

    /// Source/publication name
    public let sourceTitle: String

    /// AI-generated summary from pipeline
    public let summary: String

    /// Extracted article title
    public let articleTitle: String?

    /// City assignment from pipeline
    public let assignedCity: String?

    /// Content category
    public let category: String?

    /// Editorial workflow status
    public var status: EditorialStatus

    /// Staff member assigned to review (optional)
    public var assignedTo: String?

    /// Editorial priority level
    public var priority: EditorialPriority

    /// When added to queue - populated by server timestamp on write
    @ServerTimestamp public var createdAt: Timestamp?

    /// Who sent to editorial
    public let sentBy: String

    /// Optional staff notes
    public var notes: String?

    /// If published, link to article document
    public var articleId: String?

    /// When status last changed - populated by server timestamp on update
    @ServerTimestamp public var lastUpdated: Timestamp?

    public init(
        id: String? = nil,
        processedItemId: String,
        url: String,
        sourceTitle: String,
        summary: String,
        articleTitle: String? = nil,
        assignedCity: String? = nil,
        category: String? = nil,
        status: EditorialStatus = .pending,
        assignedTo: String? = nil,
        priority: EditorialPriority = .normal,
        createdAt: Timestamp? = nil,
        sentBy: String,
        notes: String? = nil,
        articleId: String? = nil,
        lastUpdated: Timestamp? = nil
    ) {
        self.id = id
        self.processedItemId = processedItemId
        self.url = url
        self.sourceTitle = sourceTitle
        self.summary = summary
        self.articleTitle = articleTitle
        self.assignedCity = assignedCity
        self.category = category
        self.status = status
        self.assignedTo = assignedTo
        self.priority = priority
        self._createdAt = ServerTimestamp(wrappedValue: createdAt)
        self.sentBy = sentBy
        self.notes = notes
        self.articleId = articleId
        self._lastUpdated = ServerTimestamp(wrappedValue: lastUpdated)
    }

    // MARK: - Display Helpers

    /// Time since added to queue
    public var timeInQueue: String {
        guard let timestamp = createdAt else { return "Just now" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp.dateValue(), relativeTo: Date())
    }

    /// Created date as Date (for sorting/display)
    public var createdDate: Date {
        createdAt?.dateValue() ?? Date()
    }

    /// Display-friendly source domain
    public var domain: String {
        URL(string: url)?.host ?? sourceTitle
    }
}

// MARK: - Editorial Status

/// Status of an item in the editorial queue
public enum EditorialStatus: String, Codable, CaseIterable, Sendable {
    case pending = "pending"
    case inProgress = "inProgress"
    case generating = "generating"
    case review = "review"
    case published = "published"
    case rejected = "rejected"

    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .generating: return "Generating"
        case .review: return "Under Review"
        case .published: return "Published"
        case .rejected: return "Rejected"
        }
    }

    public var iconName: String {
        switch self {
        case .pending: return "clock"
        case .inProgress: return "person.fill"
        case .generating: return "sparkles"
        case .review: return "eye.fill"
        case .published: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        }
    }

    public var colorName: String {
        switch self {
        case .pending: return "gray"
        case .inProgress: return "blue"
        case .generating: return "purple"
        case .review: return "orange"
        case .published: return "green"
        case .rejected: return "red"
        }
    }
}

// MARK: - Editorial Priority

/// Priority level for editorial review
public enum EditorialPriority: String, Codable, CaseIterable, Sendable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case breaking = "breaking"

    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High Priority"
        case .breaking: return "Breaking News"
        }
    }

    public var iconName: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .normal: return "minus.circle"
        case .high: return "exclamationmark.circle"
        case .breaking: return "bolt.circle.fill"
        }
    }

    public var sortOrder: Int {
        switch self {
        case .breaking: return 0
        case .high: return 1
        case .normal: return 2
        case .low: return 3
        }
    }
}

// MARK: - Editorial Action

/// Actions that can be taken on editorial queue items
public enum EditorialAction: String, CaseIterable, Sendable {
    case generate = "generate"
    case assign = "assign"
    case quickDraft = "quickDraft"
    case reject = "reject"
    case publish = "publish"

    public var displayName: String {
        switch self {
        case .generate: return "Generate Article"
        case .assign: return "Assign to Staff"
        case .quickDraft: return "Quick Draft"
        case .reject: return "Reject"
        case .publish: return "Publish"
        }
    }

    public var iconName: String {
        switch self {
        case .generate: return "sparkles"
        case .assign: return "person.badge.plus"
        case .quickDraft: return "doc.text"
        case .reject: return "xmark"
        case .publish: return "paperplane"
        }
    }
}
