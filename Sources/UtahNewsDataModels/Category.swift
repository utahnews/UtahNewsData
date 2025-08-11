//
//  Category.swift
//  UtahNewsDataModels
//
//  Created by Mark Evans on 01/29/25
//
//  Summary: Defines the Category model which represents content categories in the UtahNewsDataModels system.
//           Lightweight version without heavy dependencies.

import Foundation

/// Represents a content category in the UtahNewsDataModels system.
/// Categories provide a way to organize and classify content such as articles,
/// media items, and other news-related entities.
public struct Category: AssociatedData, BaseEntity, JSONSchemaProvider, Sendable {
    /// Unique identifier for the category
    public var id: String = UUID().uuidString

    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []

    /// The name of the category
    public var name: String

    /// Detailed description of what the category encompasses
    public var description: String?

    /// Parent category reference (using id instead of direct reference)
    public var parentCategoryId: String?

    /// Child category references (using ids instead of direct references)
    public var subcategoryIds: [String]?

    /// Creates a new Category with the specified properties.
    ///
    /// - Parameters:
    ///   - name: The name of the category
    ///   - description: Detailed description of what the category encompasses
    ///   - parentCategoryId: ID of parent category if this is a subcategory
    ///   - subcategoryIds: IDs of child categories if this category has subcategories
    public init(
        name: String,
        description: String? = nil,
        parentCategoryId: String? = nil,
        subcategoryIds: [String]? = nil
    ) {
        self.name = name
        self.description = description
        self.parentCategoryId = parentCategoryId
        self.subcategoryIds = subcategoryIds
    }

    /// Convenience initializer that takes Category instances for parent and subcategories
    ///
    /// - Parameters:
    ///   - name: The name of the category
    ///   - description: Detailed description of what the category encompasses
    ///   - parentCategory: Parent category if this is a subcategory
    ///   - subcategories: Child categories if this category has subcategories
    public init(
        name: String,
        description: String? = nil,
        parentCategory: Category? = nil,
        subcategories: [Category]? = nil
    ) {
        self.name = name
        self.description = description
        self.parentCategoryId = parentCategory?.id
        self.subcategoryIds = subcategories?.map { $0.id }
    }

    /// JSON schema for LLM responses
    public static var jsonSchema: String {
        """
        {
            "type": "object",
            "properties": {
                "id": {"type": "string"},
                "name": {"type": "string"},
                "description": {"type": "string", "optional": true},
                "parentCategory": {
                    "$ref": "#/definitions/Category",
                    "optional": true
                },
                "subcategories": {
                    "type": "array",
                    "items": {"$ref": "#/definitions/Category"},
                    "optional": true
                },
                "metadata": {
                    "type": "object",
                    "additionalProperties": true,
                    "optional": true
                }
            },
            "required": ["id", "name"],
            "definitions": {
                "Category": {
                    "type": "object",
                    "properties": {
                        "id": {"type": "string"},
                        "name": {"type": "string"}
                    },
                    "required": ["id", "name"]
                }
            }
        }
        """
    }
}