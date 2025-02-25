//
//  Article.swift
//  UtahNewsData
//
//  Created by Mark Evans on 2/12/25.
//

/*
 # Article Model
 
 This file defines the Article model, which represents news articles in the UtahNewsData system.
 Articles are one of the primary content types and can be linked to various other entities
 such as authors (Person), sources (Organization), locations, and topics.
 
 ## Key Features:
 
 1. Core article metadata (title, subtitle, publication date)
 2. Content sections (body text, structured as an array of sections)
 3. Authorship information
 4. Source attribution
 5. Categorization (topics, categories)
 6. Related entities (people, organizations, locations mentioned)
 7. Media attachments
 
 ## Usage:
 
 ```swift
 // Create a basic article
 let basicArticle = Article(
     title: "Utah Legislature Passes New Water Conservation Bill",
     subtitle: "New measures aim to address ongoing drought concerns",
     body: ["The Utah State Legislature passed a new water conservation bill on Monday...",
            "The bill includes provisions for..."]
 )
 
 // Create a detailed article with relationships
 let detailedArticle = Article(
     title: "Tech Industry Growth in Salt Lake Valley",
     subtitle: "Utah's Silicon Slopes continues expansion",
     body: ["The technology sector in Utah has seen unprecedented growth...",
            "Several major companies have announced new offices in the region..."],
     authors: [johnDoe], // Person entity
     source: utahTechNews, // Organization entity
     publicationDate: Date(),
     topics: ["Technology", "Business", "Economic Development"],
     categories: [techCategory, businessCategory], // Category entities
     locations: [saltLakeCity], // Location entity
     relatedPeople: [janeDoe, samSmith], // Person entities
     relatedOrganizations: [techCorp, investmentFirm] // Organization entities
 )
 
 // Access article content
 let title = detailedArticle.title
 let firstSection = detailedArticle.body.first
 
 // Generate context for RAG
 let context = detailedArticle.generateContext()
 ```
 
 The Article model implements EntityDetailsProvider, allowing it to generate
 rich text descriptions for RAG (Retrieval Augmented Generation) systems.
 */

import SwiftUI
import Foundation

/// Represents a news article in the UtahNewsData system.
/// Articles are one of the primary content types and can be linked to various other entities.
public struct Article: Codable, Identifiable, Hashable, Equatable, EntityDetailsProvider {
    /// Unique identifier for the article
    public var id: String = UUID().uuidString
    
    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []
    
    /// The main headline of the article
    public var title: String
    
    /// Secondary headline providing additional context
    public var subtitle: String?
    
    /// The main content of the article, structured as an array of text sections
    public var body: [String]
    
    /// Authors of the article (Person entities)
    public var authors: [Person]?
    
    /// The news organization or other source that published the article
    public var source: Organization?
    
    /// When the article was published
    public var publicationDate: Date?
    
    /// Keywords or subject areas covered by the article
    public var topics: [String]?
    
    /// Formal categories the article belongs to (Category entities)
    public var categories: [Category]?
    
    /// Geographic locations mentioned in or relevant to the article
    public var locations: [Location]?
    
    /// People mentioned in or relevant to the article
    public var relatedPeople: [Person]?
    
    /// Organizations mentioned in or relevant to the article
    public var relatedOrganizations: [Organization]?
    
    /// Media items associated with the article (images, videos, etc.)
    public var mediaItems: [MediaItem]?
    
    /// URL to the original article if available
    public var url: String?
    
    /// Creates a new Article with the specified properties.
    ///
    /// - Parameters:
    ///   - title: The main headline of the article
    ///   - subtitle: Secondary headline providing additional context
    ///   - body: The main content of the article, structured as an array of text sections
    ///   - authors: Authors of the article (Person entities)
    ///   - source: The news organization or other source that published the article
    ///   - publicationDate: When the article was published
    ///   - topics: Keywords or subject areas covered by the article
    ///   - categories: Formal categories the article belongs to (Category entities)
    ///   - locations: Geographic locations mentioned in or relevant to the article
    ///   - relatedPeople: People mentioned in or relevant to the article
    ///   - relatedOrganizations: Organizations mentioned in or relevant to the article
    ///   - mediaItems: Media items associated with the article (images, videos, etc.)
    ///   - url: URL to the original article if available
    public init(
        title: String,
        subtitle: String? = nil,
        body: [String],
        authors: [Person]? = nil,
        source: Organization? = nil,
        publicationDate: Date? = nil,
        topics: [String]? = nil,
        categories: [Category]? = nil,
        locations: [Location]? = nil,
        relatedPeople: [Person]? = nil,
        relatedOrganizations: [Organization]? = nil,
        mediaItems: [MediaItem]? = nil,
        url: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.authors = authors
        self.source = source
        self.publicationDate = publicationDate
        self.topics = topics
        self.categories = categories
        self.locations = locations
        self.relatedPeople = relatedPeople
        self.relatedOrganizations = relatedOrganizations
        self.mediaItems = mediaItems
        self.url = url
    }
    
    /// Generates a detailed text description of the article for use in RAG systems.
    /// The description includes the title, subtitle, publication details, and content.
    ///
    /// - Returns: A formatted string containing the article's details
    public func getDetailedDescription() -> String {
        var description = "ARTICLE: \(title)"
        
        if let subtitle = subtitle {
            description += "\nSubtitle: \(subtitle)"
        }
        
        if let source = source {
            description += "\nSource: \(source.name)"
        }
        
        if let publicationDate = publicationDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            description += "\nPublished: \(formatter.string(from: publicationDate))"
        }
        
        if let authors = authors, !authors.isEmpty {
            let authorNames = authors.map { $0.name }.joined(separator: ", ")
            description += "\nAuthors: \(authorNames)"
        }
        
        if let topics = topics, !topics.isEmpty {
            description += "\nTopics: \(topics.joined(separator: ", "))"
        }
        
        description += "\n\nContent:\n"
        for section in body {
            description += "\(section)\n"
        }
        
        return description
    }
}

public extension Article {
    init(
        id: UUID = UUID(),
        title: String,
        url: String,
        urlToImage: String? = "https://picsum.photos/800/1200",
        publishedAt: Date = Date(),
        textContent: String? = nil,
        author: String? = nil,
        category: String? = nil,
        location: Location? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.urlToImage = urlToImage
        self.publishedAt = publishedAt
        self.textContent = textContent
        self.author = author
        self.category = category
        self.location = location
    }
}

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

