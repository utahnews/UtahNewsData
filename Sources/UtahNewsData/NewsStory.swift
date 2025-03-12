//
//  NewsStory.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

/*
 # NewsStory Model

 This file defines the NewsStory model, which represents a complete news story
 in the UtahNewsData system. A news story is a comprehensive journalistic piece
 that includes a headline, author attribution, publication date, and categorization.

 ## Key Features:

 1. Story identification (headline)
 2. Author attribution
 3. Publication tracking (publishedDate)
 4. Categorization
 5. Source attribution
 6. Relationship tracking with other entities

 ## Usage:

 ```swift
 // Create a news story
 let reporter = Person(name: "Jane Smith", details: "Staff Reporter")

 let story = NewsStory(
     headline: "Utah Legislature Passes New Water Conservation Bill",
     author: reporter,
     publishedDate: Date()
 )

 // Add categories
 story.categories = [
     Category(name: "Politics"),
     Category(name: "Environment")
 ]

 // Add sources
 story.sources = [
     Source(name: "Utah State Legislature", url: "https://le.utah.gov"),
     Source(name: "Department of Natural Resources", url: "https://dnr.utah.gov")
 ]

 // Associate with related entities
 let billRelationship = Relationship(
     id: senateBill101.id,
     type: .legalDocument,
     displayName: "Covers"
 )
 story.relationships.append(billRelationship)
 ```

 The NewsStory model implements AssociatedData, allowing it to maintain
 relationships with other entities in the system, such as people, organizations,
 and legal documents.
 */

import SwiftUI

/// Represents a complete news story in the news system.
/// A news story is a comprehensive journalistic piece that includes
/// a headline, author attribution, publication date, and categorization.
public struct NewsStory: AssociatedData, JSONSchemaProvider, Sendable {
    /// Unique identifier for the news story
    public var id: String

    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []

    /// Headline or title of the news story
    public var headline: String

    /// Author or reporter who wrote the story
    public var author: Person

    /// When the story was published
    public var publishedDate: Date

    /// Categories or topics associated with the story
    public var categories: [Category] = []

    /// Sources cited or referenced in the story
    public var sources: [Source] = []

    /// The name property required by the AssociatedData protocol.
    /// Returns the headline of the story.
    public var name: String {
        return headline
    }

    /// Full text content of the story
    public var content: String?

    /// URL where the story can be accessed
    public var url: String?

    /// Featured image URL for the story
    public var featuredImageURL: String?

    /// Creates a new news story with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the story (defaults to a new UUID string)
    ///   - headline: Headline or title of the news story
    ///   - author: Author or reporter who wrote the story
    ///   - publishedDate: When the story was published
    ///   - content: Full text content of the story
    ///   - url: URL where the story can be accessed
    ///   - featuredImageURL: Featured image URL for the story
    public init(
        id: String = UUID().uuidString,
        headline: String,
        author: Person,
        publishedDate: Date,
        content: String? = nil,
        url: String? = nil,
        featuredImageURL: String? = nil
    ) {
        self.id = id
        self.headline = headline
        self.author = author
        self.publishedDate = publishedDate
        self.content = content
        self.url = url
        self.featuredImageURL = featuredImageURL
    }

    /// JSON schema for LLM responses
    public static var jsonSchema: String {
        """
        {
            "type": "object",
            "properties": {
                "id": {"type": "string"},
                "headline": {"type": "string"},
                "author": {"$ref": "#/definitions/Person"},
                "publishedDate": {"type": "string", "format": "date-time"},
                "categories": {
                    "type": "array",
                    "items": {"$ref": "#/definitions/Category"},
                    "optional": true
                },
                "sources": {
                    "type": "array",
                    "items": {"$ref": "#/definitions/Source"},
                    "optional": true
                },
                "content": {"type": "string", "optional": true},
                "summary": {"type": "string", "optional": true},
                "keywords": {
                    "type": "array",
                    "items": {"type": "string"},
                    "optional": true
                },
                "url": {"type": "string", "format": "uri", "optional": true},
                "mediaItems": {
                    "type": "array",
                    "items": {"$ref": "#/definitions/MediaItem"},
                    "optional": true
                }
            },
            "required": ["id", "headline", "author", "publishedDate"],
            "definitions": {
                "Person": {"$ref": "Person.jsonSchema"},
                "Category": {"$ref": "Category.jsonSchema"},
                "Source": {"$ref": "Source.jsonSchema"},
                "MediaItem": {"$ref": "MediaItem.jsonSchema"}
            }
        }
        """
    }
}
