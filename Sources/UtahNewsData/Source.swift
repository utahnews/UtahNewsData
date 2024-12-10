//
//  Source.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

import SwiftUI


// By aligning the Source struct with the schema defined in NewsSource, you can decode
// Firestore documents that match the NewsSource structure directly into Source.
// This involves changing Source's properties (e.g., using a String for the id instead
// of UUID, and adding category, subCategory, description, JSONSchema, etc.) so that
// they match what's stored in your Firestore "sources" collection.

public struct Source: AssociatedData, Codable, Identifiable { // Adding Identifiable for convenience
    public var id: String                               // Updated to String to match Firestore doc ID
    public var relationships: [Relationship] = []
    public var name: String
    public var url: String                              // Storing as String since Firestore often stores URLs as strings
    public var credibilityRating: Int?                  // If you still need this field, leave it, otherwise remove
    public var siteMapURL: URL?                         // This can decode from a string if Firestore stores it correctly
    public var category: NewsSourceCategory             // Matches NewsSource
    public var subCategory: NewsSourceSubcategory?      // Matches NewsSource
    public var description: String?                     // Matches NewsSource
    public var JSONSchema: JSONSchema?                  // Matches NewsSource

    // If needed, a custom initializer to create a Source from a NewsSource instance:
    init(from newsSource: NewsSource, credibilityRating: Int? = nil, relationships: [Relationship] = []) {
        self.id = newsSource.id
        self.name = newsSource.name
        self.url = newsSource.url
        self.category = newsSource.category
        self.subCategory = newsSource.subCategory
        self.description = newsSource.description
        self.JSONSchema = newsSource.JSONSchema
        self.siteMapURL = newsSource.siteMapURL
        self.credibilityRating = credibilityRating
        self.relationships = relationships
    }

    // If you do not have a direct use for the old initializer, you can remove it,
    // or provide a default one that suits your Firestore decode scenario.
    init(
        id: String = UUID().uuidString,
        name: String,
        url: String,
        category: NewsSourceCategory = .general,
        subCategory: NewsSourceSubcategory? = nil,
        description: String? = nil,
        JSONSchema: JSONSchema? = nil,
        siteMapURL: URL? = nil,
        credibilityRating: Int? = nil,
        relationships: [Relationship] = []
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
    }
}



public enum JSONSchema: String, CaseIterable, Codable {
    case schema1
    case schema2
    // Add more schemas as needed

    var label: String {
        switch self {
        case .schema1:
            return "Schema 1"
        case .schema2:
            return "Schema 2"
        }
    }
}

public enum NewsSourceCategory: String, CaseIterable, Codable {
    case localGovernmentAndPolitics
    case publicSafety
    case education
    case healthcare
    case transportation
    case economyAndBusiness
    case environmentAndSustainability
    case housing
    case cultureAndEntertainment
    case sportsAndRecreation
    case socialServices
    case technologyAndInnovation
    case weatherAndNaturalEvents
    case infrastructure
    case communityVoicesAndOpinions
    case general

    var label: String {
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
        }
    }
}

public enum NewsSourceSubcategory: String, CaseIterable, Codable {
    case none
    case meetings
    case policies
    case initiatives
    case reports
    case events

    var label: String {
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


public struct NewsSource: Codable, Identifiable {
    public var id: String
    public var name: String
    public var url: String
    public var category: NewsSourceCategory
    public var subCategory: NewsSourceSubcategory?
    public var description: String?
    public var JSONSchema: JSONSchema?
    public var siteMapURL: URL?

    init(
        id: String = UUID().uuidString,
        name: String = "",
        url: String = "",
        category: NewsSourceCategory = .general,
        subCategory: NewsSourceSubcategory? = nil,
        description: String? = nil,
        JSONSchema: JSONSchema? = nil
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.category = category
        self.subCategory = subCategory
        self.description = description
        self.JSONSchema = JSONSchema
    }
}
