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
