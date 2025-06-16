//
//  DiscussionCategory.swift
//  UtahNewsData
//
//  Created by Mark Evans on 2025-06-16
//
//  Summary: Defines the DiscussionCategory model which represents a category
//           for organizing discussion threads in the UtahNewsData system.
//           Conforms to JSONSchemaProvider for LLM responses.

import Foundation
import SwiftUI

/// A struct representing a discussion category in the news platform.
/// Categories are used to organize discussion threads by topic.
public struct DiscussionCategory: AssociatedData, JSONSchemaProvider, Codable, Identifiable, Hashable, Equatable, Sendable {
    /// Unique identifier for the category
    public var id: String
    
    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []
    
    /// Name of the category
    public var name: String
    
    /// Description of the category's purpose
    public var description: String
    
    /// Icon name for the category (SF Symbol)
    public var icon: String
    
    /// Color hex code for the category
    public var color: String
    
    /// Display order for sorting categories
    public var order: Int
    
    /// Whether the category is active
    public var isActive: Bool
    
    /// Number of threads in this category
    public var threadCount: Int
    
    /// Last activity timestamp in this category
    public var lastActivityAt: Date?
    
    /// Category creation date
    public var createdAt: Date
    
    /// URL slug for the category
    public var slug: String
    
    /// Whether this is a default category
    public var isDefault: Bool
    
    /// Parent category ID for nested categories
    public var parentCategoryId: String?
    
    /// Creates a new discussion category
    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        icon: String = "bubble.left.and.bubble.right",
        color: String = "#007AFF",
        order: Int = 0,
        isActive: Bool = true,
        threadCount: Int = 0,
        lastActivityAt: Date? = nil,
        createdAt: Date = Date(),
        slug: String,
        isDefault: Bool = false,
        parentCategoryId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.color = color
        self.order = order
        self.isActive = isActive
        self.threadCount = threadCount
        self.lastActivityAt = lastActivityAt
        self.createdAt = createdAt
        self.slug = slug
        self.isDefault = isDefault
        self.parentCategoryId = parentCategoryId
    }
    
    // MARK: - JSONSchemaProvider Implementation
    
    public static var jsonSchema: String {
        """
        {
            "type": "object",
            "properties": {
                "id": { "type": "string", "format": "uuid" },
                "name": { "type": "string", "minLength": 1, "maxLength": 100 },
                "description": { "type": "string", "maxLength": 500 },
                "icon": { "type": "string" },
                "color": { 
                    "type": "string", 
                    "pattern": "^#[0-9A-Fa-f]{6}$",
                    "description": "Hex color code"
                },
                "order": { "type": "integer", "minimum": 0 },
                "isActive": { "type": "boolean" },
                "threadCount": { "type": "integer", "minimum": 0 },
                "lastActivityAt": { "type": "string", "format": "date-time" },
                "createdAt": { "type": "string", "format": "date-time" },
                "slug": { 
                    "type": "string", 
                    "pattern": "^[a-z0-9-]+$",
                    "description": "URL-friendly slug" 
                },
                "isDefault": { "type": "boolean" },
                "parentCategoryId": { "type": "string", "format": "uuid" }
            },
            "required": ["id", "name", "description", "slug", "createdAt"]
        }
        """
    }
}