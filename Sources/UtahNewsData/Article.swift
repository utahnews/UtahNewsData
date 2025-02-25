//
//  Article.swift
//  UtahNewsData
//
//  Created by Mark Evans on 11/18/24.
//

/*
 # Article Model
 
 This file defines the Article model, which represents a news article in the UtahNewsData
 system. The Article struct implements both the NewsContent and AssociatedData protocols,
 providing a consistent interface for working with articles alongside other content types.
 
 ## Key Features:
 
 1. Core news content properties (title, URL, publication date)
 2. Article-specific metadata (category, additional images)
 3. Relationship tracking with other entities
 4. Conversion from ScrapeStory for data import
 5. Preview support with example instance
 
 ## Usage:
 
 ```swift
 // Create an article instance
 let article = Article(
     title: "Utah Legislature Passes New Water Conservation Bill",
     url: "https://www.utahnews.com/articles/water-conservation-bill",
     urlToImage: "https://www.utahnews.com/images/water-conservation.jpg",
     publishedAt: Date(),
     textContent: "The Utah Legislature passed a new bill today that aims to improve water conservation...",
     author: "Jane Smith",
     category: "Politics"
 )
 
 // Access article properties
 print("Article: \(article.title)")
 print("Author: \(article.author ?? "Unknown")")
 print("Category: \(article.category ?? "Uncategorized")")
 
 // Add relationships to other entities
 let location = Location(name: "Utah State Capitol")
 article.relationships.append(Relationship(
     id: location.id,
     type: .location,
     displayName: "Location"
 ))
 
 // Convert to MediaItem for unified handling
 let mediaItem = article.toMediaItem()
 ```
 
 Note: While Article is still supported for backward compatibility, new code should
 consider using the MediaItem struct for a more unified approach to handling content.
 */

import SwiftUI
import Foundation

/// A struct representing an article in the news app.
/// Articles are a type of news content that can maintain relationships with other entities.
public struct Article: NewsContent, AssociatedData {
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
    
    /// Creates a new article from a scraped story.
    ///
    /// - Parameters:
    ///   - scrapeStory: The scraped story data to convert
    ///   - baseURL: Base URL to use for resolving relative URLs
    /// - Returns: A new Article if the scraped data is valid, nil otherwise
    public init?(from scrapeStory: ScrapeStory, baseURL: String?) {
        self.id = UUID().uuidString

        guard let title = scrapeStory.title, !title.isEmpty else {
            print("Invalid title in ScrapeStory: \(scrapeStory)")
            return nil
        }
        self.title = title

        if let urlString = scrapeStory.url, !urlString.isEmpty {
            if let validURLString = urlString.constructValidURL(baseURL: baseURL) {
                self.url = validURLString
            } else {
                print("Invalid URL in ScrapeStory: \(scrapeStory)")
                return nil
            }
        } else {
            print("Missing URL in ScrapeStory: \(scrapeStory)")
            return nil
        }

        self.urlToImage = scrapeStory.urlToImage?.constructValidURL(baseURL: baseURL)
        self.additionalImages = scrapeStory.additionalImages?.compactMap { $0.constructValidURL(baseURL: baseURL) }
        self.textContent = scrapeStory.textContent
        self.author = scrapeStory.author
        self.category = scrapeStory.category
        self.videoURL = scrapeStory.videoURL?.constructValidURL(baseURL: baseURL)

        // Parse date
        if let publishedAtString = scrapeStory.publishedAt {
            let isoFormatter = ISO8601DateFormatter()
            if let date = isoFormatter.date(from: publishedAtString) {
                self.publishedAt = date
            } else {
                print("Invalid date format in ScrapeStory: \(scrapeStory)")
                self.publishedAt = Date()
            }
        } else {
            self.publishedAt = Date()
        }
    }
    
    /// Creates a new article with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the article (defaults to a new UUID string)
    ///   - title: Title or headline of the article
    ///   - url: URL where the article can be accessed
    ///   - urlToImage: URL to a featured image for the article
    ///   - additionalImages: Additional images associated with the article
    ///   - publishedAt: When the article was published (defaults to current date)
    ///   - textContent: The main text content of the article
    ///   - author: Author or writer of the article
    ///   - category: Category or section the article belongs to
    ///   - videoURL: URL to a video associated with the article
    ///   - location: Geographic location associated with the article
    ///   - relationships: Relationships to other entities in the system
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
        relationships: [Relationship] = []
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
    }
    
    /// Determines the appropriate MediaType for this Article.
    ///
    /// - Returns: The MediaType that best matches this content
    public func determineMediaType() -> MediaType {
        return .text
    }
    
    /// Converts this Article to a MediaItem with all relevant properties.
    ///
    /// - Returns: A new MediaItem with properties from this Article
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
}

/// Extension providing an example Article for previews and testing
public extension Article {
    /// An example instance of `Article` for previews and testing.
    @MainActor static let example = Article(
        title: "Utah News App Launches Today: Get the Latest News, Sports, and Weather",
        url: "https://www.utahnews.com",
        urlToImage: "https://picsum.photos/800/1200",
        textContent: """
        Utah News is a news app for Utah. Get the latest news, sports, and weather from Utah News. Stay informed about local events and stories that matter to you.
        """,
        author: "Mark Evans",
        category: "News"
    )
}

public struct MapResponse: Codable {
    public let success: Bool
    public let links: [String]
}

