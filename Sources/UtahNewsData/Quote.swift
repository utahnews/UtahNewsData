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
import SwiftSoup

/// Represents a direct quotation from an individual in the UtahNewsData system.
/// Quotes can be associated with articles, news events, and other content types,
/// providing attribution and context for statements.
public struct Quote: Identifiable, EntityDetailsProvider, JSONSchemaProvider, Sendable {
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

    /// JSON schema for LLM responses
    public static var jsonSchema: String {
        """
        {
            "type": "object",
            "properties": {
                "id": {"type": "string"},
                "text": {"type": "string"},
                "speaker": {"$ref": "#/definitions/Person"},
                "source": {"$ref": "#/definitions/NewsEvent", "optional": true},
                "date": {"type": "string", "format": "date-time", "optional": true},
                "context": {"type": "string", "optional": true},
                "topics": {
                    "type": "array",
                    "items": {"type": "string"},
                    "optional": true
                },
                "location": {"$ref": "#/definitions/Location", "optional": true},
                "sentiment": {"type": "string", "optional": true},
                "verificationStatus": {
                    "type": "string",
                    "enum": ["verified", "unverified", "disputed", "retracted"],
                    "optional": true
                },
                "metadata": {
                    "type": "object",
                    "additionalProperties": true,
                    "optional": true
                }
            },
            "required": ["id", "text", "speaker"],
            "definitions": {
                "Person": {"$ref": "Person.jsonSchema"},
                "NewsEvent": {"$ref": "NewsEvent.jsonSchema"},
                "Location": {"$ref": "Location.jsonSchema"}
            }
        }
        """
    }

    // MARK: - HTMLParsable Implementation
    
    public static func parse(from document: Document) throws -> Quote {
        let text = try extractQuoteText(from: document)
        let speaker = try extractSpeaker(from: document)
        let sourceString = try extractSource(from: document)
        var source: (any EntityDetailsProvider)?
        if let str = sourceString {
            source = NewsEvent(
                title: str,
                date: Date(),  // Use current date since we don't have a specific date from the source
                description: nil,
                startDate: nil,
                endDate: nil,
                location: nil,
                participants: nil,
                organizations: nil,
                relatedEvents: nil,
                relationships: []
            ) as any EntityDetailsProvider
        } else {
            source = nil
        }
        let date = try extractDate(from: document)
        let context = try extractContext(from: document)
        let location = try extractLocation(from: document)
        
        return Quote(
            text: text,
            speaker: speaker,
            source: source,
            date: date,
            context: context,
            topics: [],
            location: location
        )
    }
    
    // MARK: - Private Helper Methods
    
    private static func extractQuoteText(from document: Document) throws -> String {
        let textSelectors = [
            "[itemprop='text']",
            ".quote-text",
            ".quote-content",
            "blockquote"
        ]
        
        for selector in textSelectors {
            if let text = try document.select(selector).first()?.text(),
               !text.isEmpty {
                return text
            }
        }
        
        throw ParsingError.missingRequiredField("quote text")
    }
    
    private static func extractSpeaker(from document: Document) throws -> Person? {
        let speakerSelectors = [
            "[itemprop='speaker']",
            ".quote-speaker",
            ".quote-author",
            ".speaker-info"
        ]
        
        for selector in speakerSelectors {
            if let element = try document.select(selector).first() {
                let name = try element.select("[itemprop='name']").first()?.text()
                let title = try element.select("[itemprop='jobTitle']").first()?.text()
                let organization = try element.select("[itemprop='affiliation']").first()?.text()
                
                if let name = name {
                    return Person(
                        name: name,
                        details: title ?? "",
                        biography: nil,
                        birthDate: nil,
                        deathDate: nil,
                        occupation: organization,
                        nationality: nil,
                        notableAchievements: nil,
                        imageURL: nil,
                        locationString: nil,
                        locationLatitude: nil,
                        locationLongitude: nil,
                        email: nil,
                        website: nil,
                        phone: nil,
                        address: nil,
                        socialMediaHandles: nil
                    )
                }
            }
        }
        
        return nil
    }
    
    private static func extractSource(from document: Document) throws -> String? {
        let sourceSelectors = [
            "[itemprop='source']",
            ".quote-source",
            ".source-info",
            "meta[property='article:publisher']"
        ]
        
        for selector in sourceSelectors {
            if selector.contains("meta") {
                if let source = try document.select(selector).first()?.attr("content"),
                   !source.isEmpty {
                    return source
                }
            } else {
                if let source = try document.select(selector).first()?.text(),
                   !source.isEmpty {
                    return source
                }
            }
        }
        
        return nil
    }
    
    private static func extractDate(from document: Document) throws -> Date? {
        let dateSelectors = [
            "[itemprop='dateCreated']",
            ".quote-date",
            "time[datetime]",
            "meta[property='article:published_time']"
        ]
        
        for selector in dateSelectors {
            if let dateStr = try document.select(selector).first()?.attr(selector.contains("meta") ? "content" : "datetime") {
                for formatter in [DateFormatter.iso8601Full, DateFormatter.iso8601, DateFormatter.standardDate] {
                    if let date = formatter.date(from: dateStr) {
                        return date
                    }
                }
            }
        }
        
        return nil
    }
    
    private static func extractContext(from document: Document) throws -> String? {
        let contextSelectors = [
            "[itemprop='context']",
            ".quote-context",
            ".context-info",
            ".quote-background"
        ]
        
        for selector in contextSelectors {
            if let context = try document.select(selector).first()?.text(),
               !context.isEmpty {
                return context
            }
        }
        
        return nil
    }
    
    private static func extractLocation(from document: Document) throws -> Location? {
        for selector in ["[itemprop='location']", ".quote-location", ".location-info"] {
            if let element = try document.select(selector).first() {
                let address = try element.select("[itemprop='streetAddress']").first()?.text()
                let city = try element.select("[itemprop='addressLocality']").first()?.text()
                let state = try element.select("[itemprop='addressRegion']").first()?.text()
                let zipCode = try element.select("[itemprop='postalCode']").first()?.text()
                let country = try element.select("[itemprop='addressCountry']").first()?.text()
                
                if address != nil || city != nil || state != nil || zipCode != nil || country != nil {
                    return Location(
                        latitude: nil,
                        longitude: nil,
                        address: address,
                        city: city,
                        state: state,
                        zipCode: zipCode,
                        country: country,
                        relationships: []
                    )
                }
            }
        }
        
        return nil
    }
}

// MARK: - Equatable & Hashable
extension Quote: Equatable, Hashable {
    public static func == (lhs: Quote, rhs: Quote) -> Bool {
        lhs.id == rhs.id && lhs.text == rhs.text && lhs.speaker == rhs.speaker
            && lhs.date == rhs.date && lhs.context == rhs.context && lhs.topics == rhs.topics
            && lhs.location == rhs.location
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
        source = nil  // Cannot decode EntityDetailsProvider
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
