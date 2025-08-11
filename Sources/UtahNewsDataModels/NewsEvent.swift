//
//  NewsEvent.swift
//  UtahNewsDataModels
//
//  Created by Mark Evans on 01/29/25
//
//  Summary: Defines the NewsEvent model which represents significant events covered in the news
//           in the UtahNewsDataModels system. Lightweight version without heavy dependencies.

import Foundation

/// Represents a significant event covered in the news in the UtahNewsDataModels system.
/// NewsEvents can be associated with articles, people, organizations, and locations,
/// providing a way to track and organize coverage of specific occurrences.
public struct NewsEvent: Codable, Identifiable, Hashable, Equatable, AssociatedData, Sendable, JSONSchemaProvider {
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

    /// Direct quotations related to the event (simplified - storing IDs instead of objects)
    public var quoteIds: [String] = []

    /// Verified facts related to the event (simplified - storing IDs instead of objects)
    public var factIds: [String] = []

    /// Statistical data points related to the event (simplified - storing IDs instead of objects)
    public var statisticalDataIds: [String] = []

    /// Categories that the event belongs to (simplified - storing IDs instead of objects)
    public var categoryIds: [String] = []

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

    /// Related events (storing IDs instead of full objects)
    public var relatedEventIds: [String]?

    /// Creates a new NewsEvent with the specified properties.
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
        relatedEventIds: [String]? = nil,
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
        self.relatedEventIds = relatedEventIds
        self.relationships = relationships
    }

    /// JSON schema for LLM responses
    public static var jsonSchema: String {
        """
        {
            "type": "object",
            "properties": {
                "id": { "type": "string", "format": "uuid" },
                "title": { "type": "string" },
                "description": { "type": "string" },
                "startDate": { "type": "string", "format": "date-time" },
                "endDate": { "type": "string", "format": "date-time" },
                "location": { "$ref": "#/definitions/Location" },
                "organizer": { "$ref": "#/definitions/Organization" },
                "participants": {
                    "type": "array",
                    "items": { "$ref": "#/definitions/Person" }
                },
                "category": { "type": "string" },
                "tags": {
                    "type": "array",
                    "items": { "type": "string" }
                },
                "status": { "type": "string", "enum": ["scheduled", "inProgress", "completed", "cancelled"] },
                "url": { "type": "string", "format": "uri" }
            },
            "required": ["id", "title", "startDate"]
        }
        """
    }
}