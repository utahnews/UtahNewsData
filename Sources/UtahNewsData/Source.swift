//
//  Source.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

/*
 # Source Model

 This file defines the Source model, which represents news sources and information providers
 in the UtahNewsData system. Sources can include news organizations, government agencies,
 academic institutions, and other entities that produce or distribute news content.

 ## Key Features:

 1. Source identification and attribution
 2. Credibility assessment
 3. Categorization by type and subject area
 4. Metadata for content discovery (siteMapURL, JSONSchema)
 5. Relationship tracking with other entities

 ## Usage:

 ```swift
 // Create a news source
 let tribune = Source(
     name: "Salt Lake Tribune",
     url: URL(string: "https://www.sltrib.com")!,
     credibilityRating: 4,
     category: .news,
     subCategory: .newspaper,
     description: "Utah's largest newspaper, covering news, politics, business, and sports across the state."
 )

 // Add sitemap information for content discovery
 tribune.siteMapURL = URL(string: "https://www.sltrib.com/sitemap.xml")

 // Associate with related entities
 let ownerRelationship = Relationship(
     id: mediaGroup.id,
     type: .organization,
     displayName: "Owned By"
 )
 tribune.relationships.append(ownerRelationship)
 ```

 The Source model implements AssociatedData, allowing it to maintain
 relationships with other entities in the system, such as parent companies,
 affiliated organizations, and key personnel.
 */

import SwiftUI

// By aligning the Source struct with the schema defined in NewsSource, you can decode
// Firestore documents that match the NewsSource structure directly into Source.
// This involves changing Source's properties (e.g., using a String for the id instead
// of UUID, and adding category, subCategory, description, JSONSchema, etc.) so that
// they match what's stored in your Firestore "sources" collection.

/// Represents a news source or information provider in the news system.
/// Sources can include news organizations, government agencies, academic institutions,
/// and other entities that produce or distribute news content.
public struct Source: AssociatedData, Codable, Identifiable, Hashable, Equatable, JSONSchemaProvider
{
    /// Unique identifier for the source
    public var id: String
    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []
    /// Name of the news source or information provider
    public var name: String
    /// URL to the source's website or main page
    public var url: String
    /// Rating from 1-5 indicating the source's credibility and reliability
    /// - 1: Low credibility (unreliable, frequent misinformation)
    /// - 3: Moderate credibility (generally reliable with occasional issues)
    /// - 5: High credibility (highly reliable, fact-checked content)
    public var credibilityRating: Int?
    /// URL to the source's sitemap, used for content discovery
    public var siteMapURL: URL?
    /// Primary category of the source
    public var category: NewsSourceCategory
    /// Subcategory providing more specific classification
    public var subCategory: NewsSourceSubcategory?
    /// Detailed description of the source, its focus, and its background
    public var description: String?
    /// JSON schema for parsing content from this source, if available
    public var JSONSchema: JSONSchema?
    /// Type of the source
    public var type: String
    /// Whether the source is active
    public var isActive: Bool
    /// Last checked date
    public var lastChecked: Date
    /// Whether the source has robots.txt
    public var hasRobotsTxt: Bool
    /// Whether the source has sitemap
    public var hasSitemap: Bool
    /// Feed URLs
    public var feedUrls: [String]
    /// Metadata
    public var metadata: [String: String]

    // If needed, a custom initializer to create a Source from a NewsSource instance:
    //    public init(
    //        newsSource: NewsSource,
    //        credibilityRating: Int? = nil,
    //        relationships: [Relationship] = []
    //    ) {
    //        self.id = newsSource.id
    //        self.name = newsSource.name
    //        self.url = newsSource.url
    //        self.category = newsSource.category
    //        self.subCategory = newsSource.subCategory
    //        self.description = newsSource.description
    //        self.JSONSchema = newsSource.JSONSchema
    //        self.siteMapURL = newsSource.siteMapURL
    //        self.credibilityRating = credibilityRating
    //        self.relationships = relationships
    //    }

    // If you do not have a direct use for the old initializer, you can remove it,
    // or provide a default one that suits your Firestore decode scenario.
    /// Creates a new source with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the source (defaults to a new UUID string)
    ///   - name: Name of the news source or information provider
    ///   - url: URL to the source's website or main page
    ///   - credibilityRating: Rating from 1-5 indicating the source's credibility
    ///   - siteMapURL: URL to the source's sitemap, used for content discovery
    ///   - category: Primary category of the source
    ///   - subCategory: Subcategory providing more specific classification
    ///   - description: Detailed description of the source
    ///   - JSONSchema: JSON schema for parsing content from this source
    ///   - type: Type of the source
    ///   - isActive: Whether the source is active
    ///   - lastChecked: Last checked date
    ///   - hasRobotsTxt: Whether the source has robots.txt
    ///   - hasSitemap: Whether the source has sitemap
    ///   - feedUrls: Feed URLs
    ///   - metadata: Metadata
    public init(
        id: String = UUID().uuidString,
        name: String,
        url: String,
        category: NewsSourceCategory = .general,
        subCategory: NewsSourceSubcategory? = nil,
        description: String? = nil,
        JSONSchema: JSONSchema? = nil,
        siteMapURL: URL? = nil,
        credibilityRating: Int? = nil,
        relationships: [Relationship] = [],
        type: String,
        isActive: Bool = true,
        lastChecked: Date = Date(),
        hasRobotsTxt: Bool = false,
        hasSitemap: Bool = false,
        feedUrls: [String] = [],
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.category = category
        self.subCategory = subCategory
        self.description = description
        self.JSONSchema = JSONSchema
        self.siteMapURL = siteMapURL
        self.credibilityRating = credibilityRating
        self.relationships = relationships
        self.type = type
        self.isActive = isActive
        self.lastChecked = lastChecked
        self.hasRobotsTxt = hasRobotsTxt
        self.hasSitemap = hasSitemap
        self.feedUrls = feedUrls
        self.metadata = metadata
    }

    /// JSON schema for LLM responses
    public static var jsonSchema: String {
        """
        {
            "type": "object",
            "properties": {
                "id": {"type": "string"},
                "name": {"type": "string"},
                "url": {"type": "string", "format": "uri"},
                "credibilityRating": {"type": "number", "minimum": 0, "maximum": 5, "optional": true},
                "category": {"type": "string", "optional": true},
                "subCategory": {"type": "string", "optional": true},
                "description": {"type": "string", "optional": true},
                "siteMapURL": {"type": "string", "format": "uri", "optional": true},
                "rssFeeds": {
                    "type": "array",
                    "items": {"type": "string", "format": "uri"},
                    "optional": true
                },
                "contactInfo": {
                    "type": "object",
                    "properties": {
                        "email": {"type": "string", "format": "email"},
                        "phone": {"type": "string"},
                        "address": {"type": "string"}
                    },
                    "optional": true
                }
            },
            "required": ["id", "name", "url"]
        }
        """
    }
}

public enum JSONSchema: String, CaseIterable, Codable {
    case schema1
    case schema2
    // Add more schemas as needed

    public var label: String {
        switch self {
        case .schema1:
            return "Schema 1"
        case .schema2:
            return "Schema 2"
        }
    }
}

/// Primary categories for news sources and information providers
public enum NewsSourceCategory: String, CaseIterable, Codable {
    /// Traditional news media organizations
    case localGovernmentAndPolitics
    /// Government agencies and official sources
    case publicSafety
    /// Educational and research institutions
    case education
    /// Non-profit organizations and advocacy groups
    case healthcare
    /// Corporate and business entities
    case transportation
    /// Independent content creators and citizen journalists
    case economyAndBusiness
    /// Social media platforms and user-generated content
    case environmentAndSustainability
    /// Human-readable label for the category
    case housing
    /// Human-readable label for the category
    case cultureAndEntertainment
    /// Human-readable label for the category
    case sportsAndRecreation
    /// Human-readable label for the category
    case socialServices
    /// Human-readable label for the category
    case technologyAndInnovation
    /// Human-readable label for the category
    case weatherAndNaturalEvents
    /// Human-readable label for the category
    case infrastructure
    /// Human-readable label for the category
    case communityVoicesAndOpinions
    /// Human-readable label for the category
    case general
    /// Human-readable label for the category
    case newsNoticesEventsAndAnnouncements
    /// Human-readable label for the category
    case religion

    public var label: String {
        switch self {
        case .localGovernmentAndPolitics:
            return "Local Government and Politics"
        case .publicSafety:
            return "Public Safety"
        case .education:
            return "Education"
        case .healthcare:
            return "Healthcare"
        case .transportation:
            return "Transportation"
        case .economyAndBusiness:
            return "Economy and Business"
        case .environmentAndSustainability:
            return "Environment and Sustainability"
        case .housing:
            return "Housing"
        case .cultureAndEntertainment:
            return "Culture and Entertainment"
        case .sportsAndRecreation:
            return "Sports and Recreation"
        case .socialServices:
            return "Social Services"
        case .technologyAndInnovation:
            return "Technology and Innovation"
        case .weatherAndNaturalEvents:
            return "Weather and Natural Events"
        case .infrastructure:
            return "Infrastructure"
        case .communityVoicesAndOpinions:
            return "Community Voices and Opinions"
        case .general:
            return "General"
        case .newsNoticesEventsAndAnnouncements:
            return "News, Notices, Events, and Announcements"
        case .religion:
            return "Religion"
        }
    }
}

/// Subcategories for more specific classification of news sources
public enum NewsSourceSubcategory: String, CaseIterable, Codable {
    /// Print newspapers and their digital properties
    case none
    /// Television news networks and stations
    case meetings
    /// Radio stations and networks
    case policies
    /// Digital-only news publications
    case initiatives
    /// News wire services and content syndicators
    case reports
    /// News wire services and content syndicators
    case events

    /// Human-readable label for the subcategory
    public var label: String {
        switch self {
        case .none:
            return "None"
        case .meetings:
            return "Meetings"
        case .policies:
            return "Policies"
        case .initiatives:
            return "Initiatives"
        case .reports:
            return "Reports"
        case .events:
            return "Events"
        }
    }
}

/// Represents a specific news source with additional metadata
public struct NewsSource: BaseEntity, Codable, Sendable {
    /// Unique identifier for the news source
    public var id: String
    /// Name of the news source
    public var name: String
    /// URL to the news source's website
    public var url: String
    /// Logo or icon for the news source
    public var logoURL: URL?
    /// Primary color associated with the news source's branding
    public var primaryColor: String?

    /// Creates a new news source with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the news source (defaults to a new UUID string)
    ///   - name: Name of the news source
    ///   - url: URL to the news source's website
    ///   - logoURL: URL to the news source's logo or icon
    ///   - primaryColor: Hex color code for the news source's primary branding color
    public init(
        id: String = UUID().uuidString,
        name: String = "",
        url: String = "",
        logoURL: URL? = nil,
        primaryColor: String? = nil
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.logoURL = logoURL
        self.primaryColor = primaryColor
    }
}
