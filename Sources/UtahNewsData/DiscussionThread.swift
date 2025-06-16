//
//  DiscussionThread.swift
//  UtahNewsData
//
//  Created by Mark Evans on 2025-06-16
//
//  Summary: Defines the DiscussionThread model which represents a discussion thread
//           in the UtahNewsData system. Threads contain posts and facilitate
//           community conversations. Conforms to JSONSchemaProvider for LLM responses.

import Foundation
import SwiftUI

/// A struct representing a discussion thread in the news platform.
/// Threads are containers for posts and represent a single conversation topic.
public struct DiscussionThread: AssociatedData, JSONSchemaProvider, Codable, Identifiable, Hashable, Equatable, Sendable {
    /// Unique identifier for the thread
    public var id: String
    
    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []
    
    /// Thread title (required by BaseEntity as name)
    public var name: String
    
    /// Full thread title for display
    public var title: String
    
    /// Initial thread content/body
    public var content: String
    
    /// Category ID this thread belongs to
    public var categoryId: String
    
    /// Author user ID
    public var authorId: String
    
    /// Author display name
    public var authorName: String
    
    /// Author avatar URL
    public var authorAvatar: String?
    
    /// Thread creation timestamp
    public var createdAt: Date
    
    /// Last update timestamp
    public var updatedAt: Date
    
    /// Last activity timestamp (new post, etc.)
    public var lastActivityAt: Date
    
    /// Number of views
    public var viewCount: Int
    
    /// Number of replies/posts
    public var replyCount: Int
    
    /// Number of unique participants
    public var participantCount: Int
    
    /// Reaction counts by type
    public var reactionCounts: [String: Int]
    
    /// Calculated engagement score
    public var score: Int
    
    /// Whether thread is pinned to top
    public var isPinned: Bool
    
    /// Whether thread is locked for new posts
    public var isLocked: Bool
    
    /// Whether thread is featured
    public var isFeatured: Bool
    
    /// Whether thread is currently "hot"/trending
    public var isHot: Bool
    
    /// Whether thread is closed/archived
    public var isClosed: Bool
    
    /// Associated news story ID (optional)
    public var newsStoryId: String?
    
    /// Type of associated news story
    public var newsStoryType: String?
    
    /// Associated news story title
    public var newsStoryTitle: String?
    
    /// Associated news story image URL
    public var newsStoryImageUrl: String?
    
    /// Thread tags for categorization
    public var tags: [String]
    
    /// User mentions in the thread
    public var mentions: [String]
    
    /// Attachment IDs for media
    public var attachmentIds: [String]
    
    /// URL slug for the thread
    public var slug: String
    
    /// Creates a new discussion thread
    public init(
        id: String = UUID().uuidString,
        name: String,
        title: String,
        content: String,
        categoryId: String,
        authorId: String,
        authorName: String,
        authorAvatar: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastActivityAt: Date = Date(),
        viewCount: Int = 0,
        replyCount: Int = 0,
        participantCount: Int = 1,
        reactionCounts: [String: Int] = [:],
        score: Int = 0,
        isPinned: Bool = false,
        isLocked: Bool = false,
        isFeatured: Bool = false,
        isHot: Bool = false,
        isClosed: Bool = false,
        newsStoryId: String? = nil,
        newsStoryType: String? = nil,
        newsStoryTitle: String? = nil,
        newsStoryImageUrl: String? = nil,
        tags: [String] = [],
        mentions: [String] = [],
        attachmentIds: [String] = [],
        slug: String
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.content = content
        self.categoryId = categoryId
        self.authorId = authorId
        self.authorName = authorName
        self.authorAvatar = authorAvatar
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastActivityAt = lastActivityAt
        self.viewCount = viewCount
        self.replyCount = replyCount
        self.participantCount = participantCount
        self.reactionCounts = reactionCounts
        self.score = score
        self.isPinned = isPinned
        self.isLocked = isLocked
        self.isFeatured = isFeatured
        self.isHot = isHot
        self.isClosed = isClosed
        self.newsStoryId = newsStoryId
        self.newsStoryType = newsStoryType
        self.newsStoryTitle = newsStoryTitle
        self.newsStoryImageUrl = newsStoryImageUrl
        self.tags = tags
        self.mentions = mentions
        self.attachmentIds = attachmentIds
        self.slug = slug
    }
    
    // MARK: - JSONSchemaProvider Implementation
    
    public static var jsonSchema: String {
        """
        {
            "type": "object",
            "properties": {
                "id": { "type": "string", "format": "uuid" },
                "name": { "type": "string", "minLength": 1 },
                "title": { "type": "string", "minLength": 1, "maxLength": 300 },
                "content": { "type": "string", "maxLength": 10000 },
                "categoryId": { "type": "string", "format": "uuid" },
                "authorId": { "type": "string", "format": "uuid" },
                "authorName": { "type": "string" },
                "authorAvatar": { "type": "string", "format": "uri" },
                "createdAt": { "type": "string", "format": "date-time" },
                "updatedAt": { "type": "string", "format": "date-time" },
                "lastActivityAt": { "type": "string", "format": "date-time" },
                "viewCount": { "type": "integer", "minimum": 0 },
                "replyCount": { "type": "integer", "minimum": 0 },
                "participantCount": { "type": "integer", "minimum": 0 },
                "reactionCounts": { 
                    "type": "object",
                    "additionalProperties": { "type": "integer" }
                },
                "score": { "type": "integer" },
                "isPinned": { "type": "boolean" },
                "isLocked": { "type": "boolean" },
                "isFeatured": { "type": "boolean" },
                "isHot": { "type": "boolean" },
                "isClosed": { "type": "boolean" },
                "newsStoryId": { "type": "string", "format": "uuid" },
                "newsStoryType": { 
                    "type": "string",
                    "enum": ["article", "video", "audio"]
                },
                "newsStoryTitle": { "type": "string" },
                "newsStoryImageUrl": { "type": "string", "format": "uri" },
                "tags": { 
                    "type": "array",
                    "items": { "type": "string" }
                },
                "mentions": { 
                    "type": "array",
                    "items": { "type": "string" }
                },
                "attachmentIds": { 
                    "type": "array",
                    "items": { "type": "string" }
                },
                "slug": { 
                    "type": "string", 
                    "pattern": "^[a-z0-9-]+$"
                }
            },
            "required": ["id", "name", "title", "content", "categoryId", "authorId", "authorName", "createdAt", "slug"]
        }
        """
    }
}