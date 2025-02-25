//
//  Category.swift
//  UtahNewsData
//
//  Created by Mark Evans on 2/12/25.
//

/*
 # Category Model
 
 This file defines the Category model, which represents content categories in the UtahNewsData system.
 Categories provide a way to organize and classify content such as articles, media items, and other
 news-related entities.
 
 ## Key Features:
 
 1. Core identification (id, name)
 2. Hierarchical structure (parent category, subcategories)
 3. Descriptive information
 
 ## Usage:
 
 ```swift
 // Create a parent category
 let newsCategory = Category(
     name: "News",
     description: "General news content"
 )
 
 // Create subcategories
 let politicsCategory = Category(
     name: "Politics",
     description: "Political news and analysis",
     parentCategory: newsCategory
 )
 
 let localPoliticsCategory = Category(
     name: "Local Politics",
     description: "Utah state and local political news",
     parentCategory: politicsCategory
 )
 
 // Add subcategories to parent
 newsCategory.subcategories = [politicsCategory]
 politicsCategory.subcategories = [localPoliticsCategory]
 
 // Use with an Article
 let article = Article(
     title: "Utah Legislature Passes New Bill",
     body: ["The Utah State Legislature passed a new bill today..."],
     categories: [localPoliticsCategory]
 )
 ```
 
 The Category model implements EntityDetailsProvider, allowing it to generate
 rich text descriptions for RAG (Retrieval Augmented Generation) systems.
 */

import Foundation

/// Represents a content category in the UtahNewsData system.
/// Categories provide a way to organize and classify content such as articles,
/// media items, and other news-related entities.
public struct Category: AssociatedData, EntityDetailsProvider {
    /// Unique identifier for the category
    public var id: String = UUID().uuidString
    
    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []
    
    /// The name of the category
    public var name: String
    
    /// Detailed description of what the category encompasses
    public var description: String?
    
    /// Parent category if this is a subcategory
    public var parentCategory: Category?
    
    /// Child categories if this category has subcategories
    public var subcategories: [Category]?
    
    /// Creates a new Category with the specified properties.
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
        self.parentCategory = parentCategory
        self.subcategories = subcategories
    }
    
    /// Generates a detailed text description of the category for use in RAG systems.
    /// The description includes the category name, description, and hierarchical information.
    ///
    /// - Returns: A formatted string containing the category's details
    public func getDetailedDescription() -> String {
        var description = "CATEGORY: \(name)"
        
        if let categoryDescription = self.description {
            description += "\nDescription: \(categoryDescription)"
        }
        
        if let parentCategory = parentCategory {
            description += "\nParent Category: \(parentCategory.name)"
        }
        
        if let subcategories = subcategories, !subcategories.isEmpty {
            let subcategoryNames = subcategories.map { $0.name }.joined(separator: ", ")
            description += "\nSubcategories: \(subcategoryNames)"
        }
        
        return description
    }
}
