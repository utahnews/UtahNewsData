//
//  Article.swift
//  UtahNewsData
//
//  Created by Mark Evans on 11/18/24
//
//  Summary: Defines the Article model which represents a news article in the UtahNewsData system.
//           Now conforms to JSONSchemaProvider to provide a static JSON schema for LLM responses.

import Foundation
import SwiftUI

/// A struct representing an article in the news app.
/// Articles are a type of news content that can maintain relationships with other entities.
public struct Article: NewsContent, AssociatedData, JSONSchemaProvider, Sendable {
    /// Unique identifier for the article
    public var id: String

    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []

    /// Title or headline of the article
    public var title: String

    /// URL where the article can be accessed
    public var url: String

    /// URL to a featured image for the article
    public var urlToImage: String?

    /// Additional images associated with the article
    public var additionalImages: [String]?

    /// When the article was published
    public var publishedAt: Date

    /// The main text content of the article
    public var textContent: String?

    /// Author or writer of the article
    public var author: String?

    /// Category or section the article belongs to
    public var category: String?

    /// URL to a video associated with the article
    public var videoURL: String?

    /// Geographic location associated with the article
    public var location: Location?
    
    /// Indicates if the article is relevant to Utah (used for filtering)
    public var isRelevantToUtah: Bool
    
    /// Indicates if this content was AI-generated (vs ingested from source)
    public var generated: Bool
    
    /// Type of content (e.g., "ingested", "generated", "curated")
    public var contentType: String
    
    /// ISO timestamp when the article was processed by the pipeline
    public var processingTimestamp: String?
    
    /// Array of related article IDs for cross-referencing
    public var relatedArticleIds: [String]

    // MARK: - Initializers

    /// Creates a new article with the specified properties.
    public init(
        id: String = UUID().uuidString,
        title: String,
        url: String,
        urlToImage: String? = nil,
        additionalImages: [String]? = nil,
        publishedAt: Date = Date(),
        textContent: String? = nil,
        author: String? = nil,
        category: String? = nil,
        videoURL: String? = nil,
        location: Location? = nil,
        relationships: [Relationship] = [],
        isRelevantToUtah: Bool = true,
        generated: Bool = false,
        contentType: String = "ingested",
        processingTimestamp: String? = nil,
        relatedArticleIds: [String] = []
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.urlToImage = urlToImage
        self.additionalImages = additionalImages
        self.publishedAt = publishedAt
        self.textContent = textContent
        self.author = author
        self.category = category
        self.videoURL = videoURL
        self.location = location
        self.relationships = relationships
        self.isRelevantToUtah = isRelevantToUtah
        self.generated = generated
        self.contentType = contentType
        self.processingTimestamp = processingTimestamp
        self.relatedArticleIds = relatedArticleIds
    }

    // MARK: - Methods

    /// Determines the appropriate MediaType for this Article.
    public func determineMediaType() -> MediaType {
        return .text
    }

    /// Converts this Article to a MediaItem with all relevant properties.
    public func toMediaItem() -> MediaItem {
        var mediaItem = MediaItem(
            id: id,
            title: title,
            type: .text,
            url: url,
            textContent: textContent,
            author: author,
            publishedAt: publishedAt,
            relationships: relationships
        )

        // Add article-specific properties
        if let category = category {
            mediaItem.tags = [category]
        }

        if let location = location {
            mediaItem.location = location
        }

        return mediaItem
    }

    // MARK: - JSON Schema Provider

    /// Provides the JSON schema for Article.
    public static var jsonSchema: String {
        return """
            {
                "type": "object",
                "properties": {
                    "id": {"type": "string"},
                    "title": {"type": "string"},
                    "url": {"type": "string"},
                    "urlToImage": {"type": ["string", "null"]},
                    "additionalImages": {"type": ["array", "null"], "items": {"type": "string"}},
                    "publishedAt": {"type": "string", "format": "date-time"},
                    "textContent": {"type": ["string", "null"]},
                    "author": {"type": ["string", "null"]},
                    "category": {"type": ["string", "null"]},
                    "videoURL": {"type": ["string", "null"]},
                    "location": {"type": ["object", "null"]},
                    "isRelevantToUtah": {"type": "boolean"},
                    "generated": {"type": "boolean"},
                    "contentType": {"type": "string"},
                    "processingTimestamp": {"type": ["string", "null"]},
                    "relatedArticleIds": {"type": "array", "items": {"type": "string"}}
                },
                "required": ["id", "title", "url", "publishedAt", "isRelevantToUtah", "generated", "contentType", "relatedArticleIds"]
            }
            """
    }
}

/// Extension providing an example Article for previews and testing.
extension Article {
    /// An example instance of `Article` for previews and testing.
    @MainActor public static let example = Article(
        title: "Utah News App Launches Today: Get the Latest News, Sports, and Weather",
        url: "https://www.utahnews.com",
        urlToImage: "https://picsum.photos/800/1200",
        textContent: """
            Utah News is a news app for Utah. Get the latest news, sports, and weather from Utah News.
            Stay informed about local events and stories that matter to you.
            """,
        author: "Mark Evans",
        category: "News"
    )
}
