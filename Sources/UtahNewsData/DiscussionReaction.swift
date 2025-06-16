//
//  DiscussionReaction.swift
//  UtahNewsData
//
//  Created by Mark Evans on 2025-06-16
//
//  Summary: Defines the DiscussionReaction model and related types for user
//           reactions to discussion posts. Supports multiple reaction types
//           beyond simple up/down votes.

import Foundation
import SwiftUI

/// A struct representing a user reaction to a discussion post.
/// Reactions provide more nuanced feedback than simple voting.
public struct DiscussionReaction: BaseEntity, JSONSchemaProvider, Codable, Identifiable, Hashable, Equatable, Sendable {
    /// Unique identifier for the reaction
    public var id: String
    
    /// Name for BaseEntity (reaction summary)
    public var name: String
    
    /// Post ID this reaction is for
    public var postId: String
    
    /// User ID who made the reaction
    public var userId: String
    
    /// Type of reaction
    public var type: ReactionType
    
    /// Reaction creation timestamp
    public var createdAt: Date
    
    /// Creates a new discussion reaction
    public init(
        id: String = UUID().uuidString,
        postId: String,
        userId: String,
        type: ReactionType,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = "\(type.rawValue) reaction"
        self.postId = postId
        self.userId = userId
        self.type = type
        self.createdAt = createdAt
    }
    
    // MARK: - JSONSchemaProvider Implementation
    
    public static var jsonSchema: String {
        """
        {
            "type": "object",
            "properties": {
                "id": { "type": "string", "format": "uuid" },
                "name": { "type": "string" },
                "postId": { "type": "string", "format": "uuid" },
                "userId": { "type": "string", "format": "uuid" },
                "type": { 
                    "type": "string",
                    "enum": ["like", "love", "insightful", "funny", "sad", "angry"]
                },
                "createdAt": { "type": "string", "format": "date-time" }
            },
            "required": ["id", "name", "postId", "userId", "type", "createdAt"]
        }
        """
    }
}

/// Types of reactions users can make on posts
public enum ReactionType: String, Codable, CaseIterable, Sendable {
    case like = "like"
    case love = "love"
    case insightful = "insightful"
    case funny = "funny"
    case sad = "sad"
    case angry = "angry"
    
    /// Emoji representation of the reaction
    public var emoji: String {
        switch self {
        case .like: return "👍"
        case .love: return "❤️"
        case .insightful: return "💡"
        case .funny: return "😄"
        case .sad: return "😢"
        case .angry: return "😡"
        }
    }
    
    /// Display name for the reaction
    public var displayName: String {
        switch self {
        case .like: return "Like"
        case .love: return "Love"
        case .insightful: return "Insightful"
        case .funny: return "Funny"
        case .sad: return "Sad"
        case .angry: return "Angry"
        }
    }
    
    /// Score value for the reaction (for ranking)
    public var scoreValue: Int {
        switch self {
        case .like: return 1
        case .love: return 2
        case .insightful: return 3
        case .funny: return 1
        case .sad: return 0
        case .angry: return -1
        }
    }
}

/// Thread sorting options for the discussion forum
public enum ThreadSortOption: String, CaseIterable, Sendable {
    case hot = "hot"
    case top = "top"
    case new = "new"
    case controversial = "controversial"
    
    /// Display title for the sort option
    public var title: String {
        switch self {
        case .hot: return "Hot"
        case .top: return "Top"
        case .new: return "New"
        case .controversial: return "Controversial"
        }
    }
    
    /// SF Symbol icon for the sort option
    public var icon: String {
        switch self {
        case .hot: return "flame"
        case .top: return "arrow.up.circle"
        case .new: return "sparkles"
        case .controversial: return "exclamationmark.triangle"
        }
    }
    
    /// Description of the sort option
    public var description: String {
        switch self {
        case .hot: return "Most active discussions"
        case .top: return "Highest rated threads"
        case .new: return "Recently created"
        case .controversial: return "Most debated topics"
        }
    }
}

/// User badge earned in the discussion forum
public struct ForumBadge: BaseEntity, JSONSchemaProvider, Codable, Identifiable, Hashable, Equatable, Sendable {
    /// Unique identifier for the badge
    public var id: String
    
    /// Badge name
    public var name: String
    
    /// Badge description
    public var description: String
    
    /// SF Symbol icon name
    public var icon: String
    
    /// Color hex code
    public var color: String
    
    /// When the badge was earned
    public var earnedAt: Date
    
    /// Badge tier/level
    public var tier: BadgeTier
    
    /// Creates a new forum badge
    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        icon: String,
        color: String = "#FFD700",
        earnedAt: Date = Date(),
        tier: BadgeTier = .bronze
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.color = color
        self.earnedAt = earnedAt
        self.tier = tier
    }
    
    /// Badge tier levels
    public enum BadgeTier: String, Codable, CaseIterable {
        case bronze = "bronze"
        case silver = "silver"
        case gold = "gold"
        case platinum = "platinum"
        
        public var color: String {
            switch self {
            case .bronze: return "#CD7F32"
            case .silver: return "#C0C0C0"
            case .gold: return "#FFD700"
            case .platinum: return "#E5E4E2"
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
                "description": { "type": "string" },
                "icon": { "type": "string" },
                "color": { "type": "string", "pattern": "^#[0-9A-Fa-f]{6}$" },
                "earnedAt": { "type": "string", "format": "date-time" },
                "tier": { 
                    "type": "string",
                    "enum": ["bronze", "silver", "gold", "platinum"]
                }
            },
            "required": ["id", "name", "description", "icon", "earnedAt", "tier"]
        }
        """
    }
}