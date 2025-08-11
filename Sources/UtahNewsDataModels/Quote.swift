//
//  Quote.swift
//  UtahNewsDataModels
//
//  Created by Mark Evans on 01/29/25
//
//  Summary: Defines the Quote model which represents direct quotations from individuals
//           in the UtahNewsDataModels system. Lightweight version without HTML parsing.

import Foundation

/// Represents a direct quotation from an individual in the UtahNewsDataModels system.
/// Quotes can be associated with articles, news events, and other content types,
/// providing attribution and context for statements.
public struct Quote: Identifiable, JSONSchemaProvider, Sendable {
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

    /// Optional source identifier (simplified from complex EntityDetailsProvider)
    public var sourceId: String?

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
    ///   - sourceId: Optional identifier for the source where the quote originated
    ///   - date: When the statement was made
    ///   - context: Additional information about the circumstances of the quote
    ///   - topics: Subject areas or keywords related to the quote
    ///   - location: Where the statement was made
    public init(
        text: String,
        speaker: Person? = nil,
        sourceId: String? = nil,
        date: Date? = nil,
        context: String? = nil,
        topics: [String]? = nil,
        location: Location? = nil
    ) {
        self.text = text
        self.speaker = speaker
        self.sourceId = sourceId
        self.date = date
        self.context = context
        self.topics = topics
        self.location = location
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
                "sourceId": {"type": "string", "optional": true},
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
                "Location": {"$ref": "Location.jsonSchema"}
            }
        }
        """
    }
}

// MARK: - Equatable & Hashable
extension Quote: Equatable, Hashable {
    public static func == (lhs: Quote, rhs: Quote) -> Bool {
        lhs.id == rhs.id && lhs.text == rhs.text && lhs.speaker == rhs.speaker
            && lhs.date == rhs.date && lhs.context == rhs.context && lhs.topics == rhs.topics
            && lhs.location == rhs.location && lhs.sourceId == rhs.sourceId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(text)
        hasher.combine(speaker)
        hasher.combine(date)
        hasher.combine(context)
        hasher.combine(topics)
        hasher.combine(location)
        hasher.combine(sourceId)
    }
}

// MARK: - Codable
extension Quote: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, relationships, text, speaker, sourceId, date, context, topics, location
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        relationships = try container.decode([Relationship].self, forKey: .relationships)
        text = try container.decode(String.self, forKey: .text)
        speaker = try container.decodeIfPresent(Person.self, forKey: .speaker)
        sourceId = try container.decodeIfPresent(String.self, forKey: .sourceId)
        date = try container.decodeIfPresent(Date.self, forKey: .date)
        context = try container.decodeIfPresent(String.self, forKey: .context)
        topics = try container.decodeIfPresent([String].self, forKey: .topics)
        location = try container.decodeIfPresent(Location.self, forKey: .location)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(relationships, forKey: .relationships)
        try container.encode(text, forKey: .text)
        try container.encode(speaker, forKey: .speaker)
        try container.encode(sourceId, forKey: .sourceId)
        try container.encode(date, forKey: .date)
        try container.encode(context, forKey: .context)
        try container.encode(topics, forKey: .topics)
        try container.encode(location, forKey: .location)
    }
}