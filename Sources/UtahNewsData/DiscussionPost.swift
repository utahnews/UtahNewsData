//
//  DiscussionPost.swift
//  UtahNewsData
//
//  Created by Mark Evans on 2025-06-16
//
//  Summary: Defines the DiscussionPost model which represents a post/reply
//           in a discussion thread. Posts can be nested to form conversation trees.
//           Conforms to JSONSchemaProvider for LLM responses.

import Foundation
import SwiftUI

/// A struct representing a discussion post in the news platform.
/// Posts are individual messages within a thread and can be nested as replies.
public struct DiscussionPost: AssociatedData, JSONSchemaProvider, Codable, Identifiable, Hashable, Equatable, Sendable {
    /// Unique identifier for the post
    public var id: String
    
    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []
    
    /// Post excerpt for name (required by BaseEntity)
    public var name: String
    
    /// Thread ID this post belongs to
    public var threadId: String
    
    /// Parent post ID for nested replies
    public var parentId: String?
    
    /// Root post ID for deep reply chains
    public var rootId: String?
    
    /// Post content/body
    public var content: String
    
    /// Author user ID
    public var authorId: String
    
    /// Author display name
    public var authorName: String
    
    /// Author avatar URL
    public var authorAvatar: String?
    
    /// Author reputation score
    public var authorReputation: Int
    
    /// Whether author is a moderator
    public var isModerator: Bool
    
    /// Whether author is verified
    public var isVerified: Bool
    
    /// Post creation timestamp
    public var createdAt: Date
    
    /// Last edit timestamp
    public var editedAt: Date?
    
    /// Whether post has been edited
    public var isEdited: Bool
    
    /// Number of direct replies
    public var replyCount: Int
    
    /// Reaction counts by type
    public var reactionCounts: [String: Int]
    
    /// Calculated score based on reactions
    public var score: Int
    
    /// Nesting depth in reply tree
    public var depth: Int
    
    /// Child post IDs for building tree
    public var childIds: [String]
    
    /// Whether post is collapsed in UI
    public var isCollapsed: Bool
    
    /// Whether post is deleted (soft delete)
    public var isDeleted: Bool
    
    /// Whether post is hidden by moderation
    public var isHidden: Bool
    
    /// User mentions in the post
    public var mentions: [String]
    
    /// Attachment IDs for media
    public var attachmentIds: [String]
    
    /// ID of quoted post if quoting
    public var quotedPostId: String?
    
    /// Post status
    public var status: String
    
    /// Moderation notes
    public var moderationNotes: String?
    
    /// Creates a new discussion post
    public init(
        id: String = UUID().uuidString,
        name: String,
        threadId: String,
        parentId: String? = nil,
        rootId: String? = nil,
        content: String,
        authorId: String,
        authorName: String,
        authorAvatar: String? = nil,
        authorReputation: Int = 0,
        isModerator: Bool = false,
        isVerified: Bool = false,
        createdAt: Date = Date(),
        editedAt: Date? = nil,
        isEdited: Bool = false,
        replyCount: Int = 0,
        reactionCounts: [String: Int] = [:],
        score: Int = 0,
        depth: Int = 0,
        childIds: [String] = [],
        isCollapsed: Bool = false,
        isDeleted: Bool = false,
        isHidden: Bool = false,
        mentions: [String] = [],
        attachmentIds: [String] = [],
        quotedPostId: String? = nil,
        status: String = "active",
        moderationNotes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.threadId = threadId
        self.parentId = parentId
        self.rootId = rootId
        self.content = content
        self.authorId = authorId
        self.authorName = authorName
        self.authorAvatar = authorAvatar
        self.authorReputation = authorReputation
        self.isModerator = isModerator
        self.isVerified = isVerified
        self.createdAt = createdAt
        self.editedAt = editedAt
        self.isEdited = isEdited
        self.replyCount = replyCount
        self.reactionCounts = reactionCounts
        self.score = score
        self.depth = depth
        self.childIds = childIds
        self.isCollapsed = isCollapsed
        self.isDeleted = isDeleted
        self.isHidden = isHidden
        self.mentions = mentions
        self.attachmentIds = attachmentIds
        self.quotedPostId = quotedPostId
        self.status = status
        self.moderationNotes = moderationNotes
    }
    
    // MARK: - Computed Properties
    
    /// Returns a truncated excerpt of the content for display
    public var excerpt: String {
        String(content.prefix(150))
    }
    
    /// Whether this is a top-level post (no parent)
    public var isTopLevel: Bool {
        parentId == nil
    }
    
    // MARK: - JSONSchemaProvider Implementation
    
    public static var jsonSchema: String {
        """
        {
            "type": "object",
            "properties": {
                "id": { "type": "string", "format": "uuid" },
                "name": { "type": "string" },
                "threadId": { "type": "string", "format": "uuid" },
                "parentId": { "type": "string", "format": "uuid" },
                "rootId": { "type": "string", "format": "uuid" },
                "content": { "type": "string", "maxLength": 10000 },
                "authorId": { "type": "string", "format": "uuid" },
                "authorName": { "type": "string" },
                "authorAvatar": { "type": "string", "format": "uri" },
                "authorReputation": { "type": "integer", "minimum": 0 },
                "isModerator": { "type": "boolean" },
                "isVerified": { "type": "boolean" },
                "createdAt": { "type": "string", "format": "date-time" },
                "editedAt": { "type": "string", "format": "date-time" },
                "isEdited": { "type": "boolean" },
                "replyCount": { "type": "integer", "minimum": 0 },
                "reactionCounts": { 
                    "type": "object",
                    "additionalProperties": { "type": "integer" }
                },
                "score": { "type": "integer" },
                "depth": { "type": "integer", "minimum": 0, "maximum": 10 },
                "childIds": { 
                    "type": "array",
                    "items": { "type": "string", "format": "uuid" }
                },
                "isCollapsed": { "type": "boolean" },
                "isDeleted": { "type": "boolean" },
                "isHidden": { "type": "boolean" },
                "mentions": { 
                    "type": "array",
                    "items": { "type": "string" }
                },
                "attachmentIds": { 
                    "type": "array",
                    "items": { "type": "string" }
                },
                "quotedPostId": { "type": "string", "format": "uuid" },
                "status": { 
                    "type": "string",
                    "enum": ["active", "hidden", "deleted", "pending"]
                },
                "moderationNotes": { "type": "string" }
            },
            "required": ["id", "name", "threadId", "content", "authorId", "authorName", "createdAt", "status"]
        }
        """
    }
}