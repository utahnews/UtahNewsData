//
//  DiscussionModeration.swift
//  UtahNewsData
//
//  Created by Mark Evans on 2025-06-16
//
//  Summary: Defines moderation-related models for the discussion forum including
//           moderation actions, content reports, and user permissions.

import Foundation
import SwiftUI

/// A struct representing a moderation action taken on content or users.
public struct ModerationAction: BaseEntity, JSONSchemaProvider, Codable, Identifiable, Hashable, Equatable, Sendable {
    /// Unique identifier for the action
    public var id: String
    
    /// Action summary for name
    public var name: String
    
    /// ID of the target (thread, post, or user)
    public var targetId: String
    
    /// Type of target being moderated
    public var targetType: ModerationType
    
    /// Action taken
    public var action: ModerationActionType
    
    /// Moderator user ID
    public var moderatorId: String
    
    /// Moderator name
    public var moderatorName: String
    
    /// Reason for the action
    public var reason: String?
    
    /// Additional notes
    public var notes: String?
    
    /// Action timestamp
    public var createdAt: Date
    
    /// Duration for temporary actions (in seconds)
    public var duration: Int?
    
    /// Expiration date for temporary actions
    public var expiresAt: Date?
    
    /// Whether the action has been reversed
    public var isReversed: Bool
    
    /// Creates a new moderation action
    public init(
        id: String = UUID().uuidString,
        targetId: String,
        targetType: ModerationType,
        action: ModerationActionType,
        moderatorId: String,
        moderatorName: String,
        reason: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        duration: Int? = nil,
        expiresAt: Date? = nil,
        isReversed: Bool = false
    ) {
        self.id = id
        self.name = "\(action.rawValue) on \(targetType.rawValue)"
        self.targetId = targetId
        self.targetType = targetType
        self.action = action
        self.moderatorId = moderatorId
        self.moderatorName = moderatorName
        self.reason = reason
        self.notes = notes
        self.createdAt = createdAt
        self.duration = duration
        self.expiresAt = expiresAt
        self.isReversed = isReversed
    }
    
    /// Types of content that can be moderated
    public enum ModerationType: String, Codable, CaseIterable {
        case thread = "thread"
        case post = "post"
        case user = "user"
        case category = "category"
    }
    
    /// Types of moderation actions
    public enum ModerationActionType: String, Codable, CaseIterable {
        case remove = "remove"
        case hide = "hide"
        case lock = "lock"
        case unlock = "unlock"
        case pin = "pin"
        case unpin = "unpin"
        case warn = "warn"
        case mute = "mute"
        case unmute = "unmute"
        case ban = "ban"
        case unban = "unban"
        case edit = "edit"
        case merge = "merge"
        case move = "move"
        
        /// Whether this action is reversible
        public var isReversible: Bool {
            switch self {
            case .remove, .warn, .edit, .merge:
                return false
            default:
                return true
            }
        }
        
        /// Severity level of the action
        public var severity: ActionSeverity {
            switch self {
            case .remove, .ban:
                return .high
            case .hide, .mute:
                return .medium
            case .lock, .warn, .edit:
                return .low
            case .pin, .unpin, .unlock, .unmute, .unban, .merge, .move:
                return .info
            }
        }
    }
    
    /// Action severity levels
    public enum ActionSeverity: String, Codable {
        case info = "info"
        case low = "low"
        case medium = "medium"
        case high = "high"
        
        public var color: String {
            switch self {
            case .info: return "#007AFF"
            case .low: return "#FFD60A"
            case .medium: return "#FF9500"
            case .high: return "#FF3B30"
            }
        }
    }
    
    // MARK: - JSONSchemaProvider Implementation
    
    public static var jsonSchema: String {
        """
        {
            "type": "object",
            "properties": {
                "id": { "type": "string", "format": "uuid" },
                "name": { "type": "string" },
                "targetId": { "type": "string", "format": "uuid" },
                "targetType": { 
                    "type": "string",
                    "enum": ["thread", "post", "user", "category"]
                },
                "action": { 
                    "type": "string",
                    "enum": ["remove", "hide", "lock", "unlock", "pin", "unpin", "warn", "mute", "unmute", "ban", "unban", "edit", "merge", "move"]
                },
                "moderatorId": { "type": "string", "format": "uuid" },
                "moderatorName": { "type": "string" },
                "reason": { "type": "string" },
                "notes": { "type": "string" },
                "createdAt": { "type": "string", "format": "date-time" },
                "duration": { "type": "integer", "minimum": 0 },
                "expiresAt": { "type": "string", "format": "date-time" },
                "isReversed": { "type": "boolean" }
            },
            "required": ["id", "name", "targetId", "targetType", "action", "moderatorId", "moderatorName", "createdAt"]
        }
        """
    }
}

/// A struct representing a user report of content
public struct ContentReport: BaseEntity, JSONSchemaProvider, Codable, Identifiable, Hashable, Equatable, Sendable {
    /// Unique identifier for the report
    public var id: String
    
    /// Report summary for name
    public var name: String
    
    /// ID of reported content
    public var contentId: String
    
    /// Type of content reported
    public var contentType: String
    
    /// Reporter user ID
    public var reporterId: String
    
    /// Reporter name
    public var reporterName: String
    
    /// Report reason
    public var reason: ReportReason
    
    /// Additional description
    public var description: String?
    
    /// Report status
    public var status: ReportStatus
    
    /// Report creation timestamp
    public var createdAt: Date
    
    /// Review timestamp
    public var reviewedAt: Date?
    
    /// Reviewer user ID
    public var reviewerId: String?
    
    /// Reviewer name
    public var reviewerName: String?
    
    /// Resolution notes
    public var resolutionNotes: String?
    
    /// Action taken
    public var actionTaken: String?
    
    /// Creates a new content report
    public init(
        id: String = UUID().uuidString,
        contentId: String,
        contentType: String,
        reporterId: String,
        reporterName: String,
        reason: ReportReason,
        description: String? = nil,
        status: ReportStatus = .pending,
        createdAt: Date = Date(),
        reviewedAt: Date? = nil,
        reviewerId: String? = nil,
        reviewerName: String? = nil,
        resolutionNotes: String? = nil,
        actionTaken: String? = nil
    ) {
        self.id = id
        self.name = "\(reason.rawValue) report"
        self.contentId = contentId
        self.contentType = contentType
        self.reporterId = reporterId
        self.reporterName = reporterName
        self.reason = reason
        self.description = description
        self.status = status
        self.createdAt = createdAt
        self.reviewedAt = reviewedAt
        self.reviewerId = reviewerId
        self.reviewerName = reviewerName
        self.resolutionNotes = resolutionNotes
        self.actionTaken = actionTaken
    }
    
    /// Reasons for reporting content
    public enum ReportReason: String, Codable, CaseIterable {
        case spam = "spam"
        case harassment = "harassment"
        case hatespeech = "hatespeech"
        case misinformation = "misinformation"
        case inappropriate = "inappropriate"
        case offtopic = "offtopic"
        case duplicate = "duplicate"
        case copyright = "copyright"
        case personalinfo = "personalinfo"
        case other = "other"
        
        /// Display title for the reason
        public var title: String {
            switch self {
            case .spam: return "Spam"
            case .harassment: return "Harassment or Bullying"
            case .hatespeech: return "Hate Speech"
            case .misinformation: return "Misinformation"
            case .inappropriate: return "Inappropriate Content"
            case .offtopic: return "Off Topic"
            case .duplicate: return "Duplicate Post"
            case .copyright: return "Copyright Violation"
            case .personalinfo: return "Personal Information"
            case .other: return "Other"
            }
        }
        
        /// Description of the reason
        public var description: String {
            switch self {
            case .spam: return "Unwanted commercial content or spam"
            case .harassment: return "Targeted harassment or bullying"
            case .hatespeech: return "Content promoting hate or discrimination"
            case .misinformation: return "False or misleading information"
            case .inappropriate: return "Sexually explicit or violent content"
            case .offtopic: return "Content not relevant to the discussion"
            case .duplicate: return "Duplicate or reposted content"
            case .copyright: return "Unauthorized use of copyrighted material"
            case .personalinfo: return "Shares private personal information"
            case .other: return "Other community guideline violation"
            }
        }
    }
    
    /// Status of a content report
    public enum ReportStatus: String, Codable, CaseIterable {
        case pending = "pending"
        case reviewing = "reviewing"
        case resolved = "resolved"
        case dismissed = "dismissed"
        case escalated = "escalated"
        
        /// Display color for the status
        public var color: String {
            switch self {
            case .pending: return "#FFD60A"
            case .reviewing: return "#007AFF"
            case .resolved: return "#34C759"
            case .dismissed: return "#8E8E93"
            case .escalated: return "#FF3B30"
            }
        }
    }
    
    // MARK: - JSONSchemaProvider Implementation
    
    public static var jsonSchema: String {
        """
        {
            "type": "object",
            "properties": {
                "id": { "type": "string", "format": "uuid" },
                "name": { "type": "string" },
                "contentId": { "type": "string", "format": "uuid" },
                "contentType": { "type": "string" },
                "reporterId": { "type": "string", "format": "uuid" },
                "reporterName": { "type": "string" },
                "reason": { 
                    "type": "string",
                    "enum": ["spam", "harassment", "hatespeech", "misinformation", "inappropriate", "offtopic", "duplicate", "copyright", "personalinfo", "other"]
                },
                "description": { "type": "string", "maxLength": 1000 },
                "status": { 
                    "type": "string",
                    "enum": ["pending", "reviewing", "resolved", "dismissed", "escalated"]
                },
                "createdAt": { "type": "string", "format": "date-time" },
                "reviewedAt": { "type": "string", "format": "date-time" },
                "reviewerId": { "type": "string", "format": "uuid" },
                "reviewerName": { "type": "string" },
                "resolutionNotes": { "type": "string" },
                "actionTaken": { "type": "string" }
            },
            "required": ["id", "name", "contentId", "contentType", "reporterId", "reporterName", "reason", "status", "createdAt"]
        }
        """
    }
}