//
//  Quote.swift
//  UtahNewsData
//
//  Created by Mark Evans on 2/12/25.
//

/*
 # Quote Model
 
 This file defines the Quote model, which represents direct quotations from individuals
 in the UtahNewsData system. Quotes can be associated with articles, news events, and other
 content types, providing attribution and context for statements.
 
 ## Key Features:
 
 1. Core content (text of the quote)
 2. Attribution (speaker, source)
 3. Contextual information (date, location, topic)
 4. Related entities
 
 ## Usage:
 
 ```swift
 // Create a basic quote
 let basicQuote = Quote(
     text: "We're committed to improving Utah's water infrastructure.",
     speaker: governor // Person entity
 )
 
 // Create a detailed quote with context
 let detailedQuote = Quote(
     text: "The new legislation represents a significant step forward in addressing our state's water conservation needs.",
     speaker: waterDirector, // Person entity
     source: pressConference, // NewsEvent entity
     date: Date(),
     context: "Statement made during press conference announcing new water conservation bill",
     topics: ["Water Conservation", "Legislation", "Infrastructure"],
     location: capitolBuilding // Location entity
 )
 
 // Associate quote with an article
 let article = Article(
     title: "Utah Passes Water Conservation Bill",
     body: ["The Utah Legislature passed a comprehensive water conservation bill on Monday..."]
 )
 
 // Create relationship between quote and article
 let relationship = Relationship(
     fromEntity: detailedQuote,
     toEntity: article,
     type: .quotedIn
 )
 
 detailedQuote.relationships.append(relationship)
 article.relationships.append(relationship)
 ```
 
 The Quote model implements EntityDetailsProvider, allowing it to generate
 rich text descriptions for RAG (Retrieval Augmented Generation) systems.
 */

import Foundation

/// Represents a direct quotation from an individual in the UtahNewsData system.
/// Quotes can be associated with articles, news events, and other content types,
/// providing attribution and context for statements.
public struct Quote: Identifiable, EntityDetailsProvider {
    /// Unique identifier for the quote
    public var id: String = UUID().uuidString
    
    /// The name property required by the BaseEntity protocol
    public var name: String {
        return text.count > 50 ? String(text.prefix(47)) + "..." : text
    }
    
    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []
    
    /// The actual text of the quotation
    public var text: String
    
    /// The person who made the statement
    public var speaker: Person?
    
    /// The event, article, or other source where the quote originated
    public var source: (any EntityDetailsProvider)?
    
    /// When the statement was made
    public var date: Date?
    
    /// Additional information about the circumstances of the quote
    public var context: String?
    
    /// Subject areas or keywords related to the quote
    public var topics: [String]?
    
    /// Where the statement was made
    public var location: Location?
    
    /// Creates a new Quote with the specified properties.
    ///
    /// - Parameters:
    ///   - text: The actual text of the quotation
    ///   - speaker: The person who made the statement
    ///   - source: The event, article, or other source where the quote originated
    ///   - date: When the statement was made
    ///   - context: Additional information about the circumstances of the quote
    ///   - topics: Subject areas or keywords related to the quote
    ///   - location: Where the statement was made
    public init(
        text: String,
        speaker: Person? = nil,
        source: (any EntityDetailsProvider)? = nil,
        date: Date? = nil,
        context: String? = nil,
        topics: [String]? = nil,
        location: Location? = nil
    ) {
        self.text = text
        self.speaker = speaker
        self.source = source
        self.date = date
        self.context = context
        self.topics = topics
        self.location = location
    }
    
    /// Generates a detailed text description of the quote for use in RAG systems.
    /// The description includes the quote text, speaker, source, and contextual information.
    ///
    /// - Returns: A formatted string containing the quote's details
    public func getDetailedDescription() -> String {
        var description = "QUOTE: \"\(text)\""
        
        if let speaker = speaker {
            description += "\nSpeaker: \(speaker.name)"
        }
        
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            description += "\nDate: \(formatter.string(from: date))"
        }
        
        if let context = context {
            description += "\nContext: \(context)"
        }
        
        if let location = location {
            description += "\nLocation: \(location.name)"
        }
        
        if let topics = topics, !topics.isEmpty {
            description += "\nTopics: \(topics.joined(separator: ", "))"
        }
        
        return description
    }
}

// MARK: - Equatable & Hashable
extension Quote: Equatable, Hashable {
    public static func == (lhs: Quote, rhs: Quote) -> Bool {
        lhs.id == rhs.id &&
        lhs.text == rhs.text &&
        lhs.speaker == rhs.speaker &&
        lhs.date == rhs.date &&
        lhs.context == rhs.context &&
        lhs.topics == rhs.topics &&
        lhs.location == rhs.location
        // Note: source is not compared as it's an EntityDetailsProvider which doesn't conform to Equatable
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(text)
        hasher.combine(speaker)
        hasher.combine(date)
        hasher.combine(context)
        hasher.combine(topics)
        hasher.combine(location)
        // Note: source is not hashed as it's an EntityDetailsProvider which doesn't conform to Hashable
    }
}

// MARK: - Codable
extension Quote: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, relationships, text, speaker, date, context, topics, location
        // Note: source is excluded as it's an EntityDetailsProvider which doesn't conform to Codable
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        relationships = try container.decode([Relationship].self, forKey: .relationships)
        text = try container.decode(String.self, forKey: .text)
        speaker = try container.decodeIfPresent(Person.self, forKey: .speaker)
        date = try container.decodeIfPresent(Date.self, forKey: .date)
        context = try container.decodeIfPresent(String.self, forKey: .context)
        topics = try container.decodeIfPresent([String].self, forKey: .topics)
        location = try container.decodeIfPresent(Location.self, forKey: .location)
        source = nil // Cannot decode EntityDetailsProvider
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(relationships, forKey: .relationships)
        try container.encode(text, forKey: .text)
        try container.encode(speaker, forKey: .speaker)
        try container.encode(date, forKey: .date)
        try container.encode(context, forKey: .context)
        try container.encode(topics, forKey: .topics)
        try container.encode(location, forKey: .location)
        // source is not encoded as it's an EntityDetailsProvider which doesn't conform to Codable
    }
}
