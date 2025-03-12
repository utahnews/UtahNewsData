//
//  NewsEvent.swift
//  UtahNewsData
//
//  Created by Mark Evans on 2/12/25.
//

/*
 # NewsEvent Model

 This file defines the NewsEvent model, which represents significant events covered in the news
 in the UtahNewsData system. NewsEvents can be associated with articles, people, organizations,
 and locations, providing a way to track and organize coverage of specific occurrences.

 ## Key Features:

 1. Core event information (title, date)
 2. Associated content (quotes, facts, statistical data)
 3. Categorization
 4. Relationships to other entities

 ## Usage:

 ```swift
 // Create a basic news event
 let basicEvent = NewsEvent(
     title: "Utah State Fair",
     date: Date() // September 5, 2023
 )

 // Create a detailed news event with associated content
 let detailedEvent = NewsEvent(
     title: "Utah Legislative Session 2023",
     date: Date() // January 17, 2023
 )

 // Add quotes to the event
 let governorQuote = Quote(
     text: "This legislative session will focus on water conservation and education funding.",
     speaker: governor // Person entity
 )
 detailedEvent.quotes.append(governorQuote)

 // Add facts to the event
 let budgetFact = Fact(
     statement: "The proposed state budget includes $200 million for water infrastructure."
 )
 detailedEvent.facts.append(budgetFact)

 // Add statistical data to the event
 let educationStat = StatisticalData(
     title: "Education Funding",
     value: "7.8",
     unit: "billion dollars"
 )
 detailedEvent.statisticalData.append(educationStat)

 // Add categories to the event
 let politicsCategory = Category(name: "Politics")
 let budgetCategory = Category(name: "Budget")
 detailedEvent.categories = [politicsCategory, budgetCategory]

 // Create relationships with other entities
 let articleRelationship = Relationship(
     fromEntity: detailedEvent,
     toEntity: legislativeArticle, // Article entity
     type: .describes
 )
 detailedEvent.relationships.append(articleRelationship)
 ```

 The NewsEvent model implements AssociatedData, allowing it to be linked with
 other entities in the UtahNewsData system through relationships.
 */

import Foundation
import SwiftSoup

/// Represents a significant event covered in the news in the UtahNewsData system.
/// NewsEvents can be associated with articles, people, organizations, and locations,
/// providing a way to track and organize coverage of specific occurrences.
public struct NewsEvent: Codable, Identifiable, Hashable, Equatable, AssociatedData, HTMLParsable, Sendable,
    JSONSchemaProvider
{
    /// Unique identifier for the news event
    public var id: String

    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []

    /// The name or headline of the event
    public var title: String

    /// The name property required by the BaseEntity protocol
    public var name: String {
        return title
    }

    /// When the event occurred
    public var date: Date

    /// Direct quotations related to the event
    public var quotes: [Quote] = []

    /// Verified facts related to the event
    public var facts: [Fact] = []

    /// Statistical data points related to the event
    public var statisticalData: [StatisticalData] = []

    /// Categories that the event belongs to
    public var categories: [Category] = []

    /// Description of the event
    public var description: String?

    /// Start date of the event
    public var startDate: Date?

    /// End date of the event
    public var endDate: Date?

    /// Location of the event
    public var location: Location?

    /// Participants in the event
    public var participants: [Person]?

    /// Organizations involved in the event
    public var organizations: [Organization]?

    /// Related events
    public var relatedEvents: [String]?

    /// Creates a new NewsEvent with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the news event (defaults to a new UUID string)
    ///   - title: The name or headline of the event
    ///   - date: When the event occurred
    ///   - description: Description of the event
    ///   - startDate: Start date of the event
    ///   - endDate: End date of the event
    ///   - location: Location of the event
    ///   - participants: Participants in the event
    ///   - organizations: Organizations involved in the event
    ///   - relatedEvents: Related events
    ///   - relationships: Relationships to other entities
    public init(
        id: String = UUID().uuidString,
        title: String,
        date: Date,
        description: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        location: Location? = nil,
        participants: [Person]? = nil,
        organizations: [Organization]? = nil,
        relatedEvents: [String]? = nil,
        relationships: [Relationship] = []
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.participants = participants
        self.organizations = organizations
        self.relatedEvents = relatedEvents
        self.relationships = relationships
    }

    /// JSON schema for LLM responses
    public static var jsonSchema: String {
        """
        {
            "type": "object",
            "properties": {
                "id": {"type": "string"},
                "title": {"type": "string"},
                "date": {"type": "string", "format": "date-time"},
                "quotes": {
                    "type": "array",
                    "items": {"$ref": "#/definitions/Quote"},
                    "optional": true
                },
                "facts": {
                    "type": "array",
                    "items": {"$ref": "#/definitions/Fact"},
                    "optional": true
                },
                "statisticalData": {
                    "type": "array",
                    "items": {"$ref": "#/definitions/StatisticalData"},
                    "optional": true
                },
                "categories": {
                    "type": "array",
                    "items": {"$ref": "#/definitions/Category"},
                    "optional": true
                },
                "metadata": {
                    "type": "object",
                    "additionalProperties": true,
                    "optional": true
                }
            },
            "required": ["id", "title", "date"],
            "definitions": {
                "Quote": {"$ref": "Quote.jsonSchema"},
                "Fact": {"$ref": "Fact.jsonSchema"},
                "StatisticalData": {"$ref": "StatisticalData.jsonSchema"},
                "Category": {"$ref": "Category.jsonSchema"}
            }
        }
        """
    }

    // MARK: - HTMLParsable Implementation
    
    public static func parse(from document: Document) throws -> Self {
        // Try to find the event title
        let titleOpt = try document.select("[itemprop='name'], .event-title, h1").first()?.text()
            ?? document.select("meta[property='og:title']").first()?.attr("content")
            ?? document.select("title").first()?.text()
        
        guard let title = titleOpt else {
            throw ParsingError.invalidHTML
        }
        
        // Try to find description
        let description = try document.select("[itemprop='description'], .event-description").first()?.text()
            ?? document.select("meta[name='description']").first()?.attr("content")
        
        // Try to find dates
        let startDateStr = try document.select("[itemprop='startDate'], .event-start-date").first()?.attr("datetime")
            ?? document.select("time").first()?.attr("datetime")
        
        let endDateStr = try document.select("[itemprop='endDate'], .event-end-date").first()?.attr("datetime")
        
        let dateFormatter = ISO8601DateFormatter()
        let startDate = startDateStr.flatMap { dateFormatter.date(from: $0) }
        let endDate = endDateStr.flatMap { dateFormatter.date(from: $0) }
        
        // Try to find location
        var location: Location? = nil
        if let locationElement = try document.select("[itemprop='location'], .event-location").first() {
            let locationDoc = try SwiftSoup.parse(try locationElement.html())
            location = try Location.parse(from: locationDoc)
        }
        
        // Try to find participants
        var participants: [Person] = []
        let participantElements = try document.select("[itemprop='performer'], .event-participant")
        for element in participantElements {
            let personDoc = try SwiftSoup.parse(try element.html())
            if let person = try? Person.parse(from: personDoc) {
                participants.append(person)
            }
        }
        
        // Try to find organizations
        var organizations: [Organization] = []
        let organizationElements = try document.select("[itemprop='organizer'], .event-organizer")
        for element in organizationElements {
            let orgDoc = try SwiftSoup.parse(try element.html())
            if let org = try? Organization.parse(from: orgDoc) {
                organizations.append(org)
            }
        }
        
        return NewsEvent(
            title: title,
            date: startDate ?? Date(),
            description: description,
            startDate: startDate,
            endDate: endDate,
            location: location,
            participants: participants.isEmpty ? nil : participants,
            organizations: organizations.isEmpty ? nil : organizations
        )
    }
}
