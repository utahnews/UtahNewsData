//
//  Source.swift
//  UtahNewsDataModels
//
//  Created by Mark Evans on 01/29/25
//
//  Summary: Defines the Source model which represents news sources and information providers
//           in the UtahNewsDataModels system. Lightweight version without HTML parsing.

import Foundation

/// Represents a news source or information provider in the news system.
/// Sources can include news organizations, government agencies, academic institutions,
/// and other entities that produce or distribute news content.
public struct Source: AssociatedData, Codable, Identifiable, Hashable, Equatable, JSONSchemaProvider, Sendable {
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
    public var category: String?
    /// Subcategory providing more specific classification
    public var subCategory: NewsSourceSubcategory?
    /// Detailed description of the source, its focus, and its background
    public var sourceDescription: String?
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
    /// Language code for the source's content (e.g., "en-US")
    public var language: String?

    /// Creates a new source with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the source (defaults to a new UUID string)
    ///   - name: Name of the news source or information provider
    ///   - url: URL to the source's website or main page
    ///   - sourceDescription: Detailed description of the source
    ///   - category: Primary category of the source
    ///   - language: Language code for the source's content
    public init(
        id: String = UUID().uuidString,
        name: String,
        url: String,
        sourceDescription: String? = nil,
        category: String? = nil,
        language: String? = nil
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.sourceDescription = sourceDescription
        self.category = category
        self.language = language
        self.type = "news" // Default type
        self.isActive = true // Default to active
        self.lastChecked = Date() // Current date
        self.hasRobotsTxt = false // Default to false
        self.hasSitemap = false // Default to false
        self.feedUrls = [] // Empty array
        self.metadata = [:] // Empty dictionary
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
                "url": { "type": "string", "format": "uri" },
                "category": { "type": "string" },
                "language": { "type": "string" },
                "country": { "type": "string" },
                "reliability": {
                    "type": "object",
                    "properties": {
                        "score": { "type": "number", "minimum": 0, "maximum": 1 },
                        "lastUpdated": { "type": "string", "format": "date-time" }
                    }
                }
            },
            "required": ["id", "name", "url"]
        }
        """
    }
}

public enum JSONSchema: String, CaseIterable, Codable, Sendable {
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
public enum NewsSourceCategory: String, CaseIterable, Codable, Sendable {
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
public enum NewsSourceSubcategory: String, CaseIterable, Codable, Sendable {
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