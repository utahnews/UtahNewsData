//
//  Fact.swift
//  UtahNewsData
//
//  Created by Mark Evans on 2/12/25.
//
//  Summary: Defines the Fact model which represents verified pieces of information
//           in the UtahNewsData system. Now conforms to JSONSchemaProvider to provide a static JSON schema for LLM responses.

import Foundation

/// Represents the verification status of a fact
public enum VerificationStatus: String, Codable, Sendable {
    case verified
    case unverified
    case disputed
    case retracted
}

/// Represents the confidence level in a fact's accuracy
public enum ConfidenceLevel: String, Codable, Sendable {
    case high
    case medium
    case low
}

/// Represents a verified piece of information in the UtahNewsData system.
/// Facts can be associated with articles, news events, and other content types,
/// providing verified data points with proper attribution.
public struct Fact: AssociatedData, EntityDetailsProvider, BaseEntity, JSONSchemaProvider, Sendable
{  // Added JSONSchemaProvider and Sendable conformance
    /// Unique identifier for the fact
    public var id: String = UUID().uuidString

    /// The name of the entity (required by BaseEntity)
    public var name: String {
        let truncatedStatement = statement.count > 50 ? statement.prefix(50) + "..." : statement
        return String(truncatedStatement)
    }

    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []

    /// The factual statement
    public var statement: String

    /// Organizations or persons that are the source of this fact
    public var sources: [any EntityDetailsProvider]?

    /// Current verification status of the fact
    public var verificationStatus: VerificationStatus?

    /// Confidence level in the fact's accuracy
    public var confidenceLevel: ConfidenceLevel?

    /// When the fact was established or reported
    public var date: Date?

    /// Subject areas or keywords related to the fact
    public var topics: [String]?

    /// Category ID the fact belongs to (instead of direct reference)
    public var categoryId: String?

    /// Entities (people, organizations, locations) related to this fact
    public var relatedEntities: [any EntityDetailsProvider]?

    /// Creates a new Fact with the specified properties.
    ///
    /// - Parameters:
    ///   - statement: The factual statement
    ///   - sources: Organizations or persons that are the source of this fact
    ///   - verificationStatus: Current verification status of the fact
    ///   - confidenceLevel: Confidence level in the fact's accuracy
    ///   - date: When the fact was established or reported
    ///   - topics: Subject areas or keywords related to the fact
    ///   - categoryId: ID of the category the fact belongs to
    ///   - relatedEntities: Entities (people, organizations, locations) related to this fact
    public init(
        statement: String,
        sources: [any EntityDetailsProvider]? = nil,
        verificationStatus: VerificationStatus? = nil,
        confidenceLevel: ConfidenceLevel? = nil,
        date: Date? = nil,
        topics: [String]? = nil,
        categoryId: String? = nil,
        relatedEntities: [any EntityDetailsProvider]? = nil
    ) {
        self.statement = statement
        self.sources = sources
        self.verificationStatus = verificationStatus
        self.confidenceLevel = confidenceLevel
        self.date = date
        self.topics = topics
        self.categoryId = categoryId
        self.relatedEntities = relatedEntities
    }

    /// Convenience initializer that takes a Category instance
    ///
    /// - Parameters:
    ///   - statement: The factual statement
    ///   - sources: Organizations or persons that are the source of this fact
    ///   - verificationStatus: Current verification status of the fact
    ///   - confidenceLevel: Confidence level in the fact's accuracy
    ///   - date: When the fact was established or reported
    ///   - topics: Subject areas or keywords related to the fact
    ///   - category: Category the fact belongs to
    ///   - relatedEntities: Entities (people, organizations, locations) related to this fact
    public init(
        statement: String,
        sources: [any EntityDetailsProvider]? = nil,
        verificationStatus: VerificationStatus? = nil,
        confidenceLevel: ConfidenceLevel? = nil,
        date: Date? = nil,
        topics: [String]? = nil,
        category: Category? = nil,
        relatedEntities: [any EntityDetailsProvider]? = nil
    ) {
        self.statement = statement
        self.sources = sources
        self.verificationStatus = verificationStatus
        self.confidenceLevel = confidenceLevel
        self.date = date
        self.topics = topics
        self.categoryId = category?.id
        self.relatedEntities = relatedEntities
    }

    // Implement Equatable manually since we have properties that don't conform to Equatable
    public static func == (lhs: Fact, rhs: Fact) -> Bool {
        return lhs.id == rhs.id && lhs.statement == rhs.statement
    }

    // Implement Hashable manually
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(statement)
    }

    // Implement Codable manually
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        statement = try container.decode(String.self, forKey: .statement)
        verificationStatus = try container.decodeIfPresent(
            VerificationStatus.self, forKey: .verificationStatus)
        confidenceLevel = try container.decodeIfPresent(
            ConfidenceLevel.self, forKey: .confidenceLevel)
        date = try container.decodeIfPresent(Date.self, forKey: .date)
        topics = try container.decodeIfPresent([String].self, forKey: .topics)
        categoryId = try container.decodeIfPresent(String.self, forKey: .categoryId)
        relationships =
            try container.decodeIfPresent([Relationship].self, forKey: .relationships) ?? []

        // Skip decoding sources and relatedEntities as they use protocol types
        sources = nil
        relatedEntities = nil
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(statement, forKey: .statement)
        try container.encodeIfPresent(verificationStatus, forKey: .verificationStatus)
        try container.encodeIfPresent(confidenceLevel, forKey: .confidenceLevel)
        try container.encodeIfPresent(date, forKey: .date)
        try container.encodeIfPresent(topics, forKey: .topics)
        try container.encodeIfPresent(categoryId, forKey: .categoryId)
        try container.encode(relationships, forKey: .relationships)

        // Skip encoding sources and relatedEntities as they use protocol types
    }

    private enum CodingKeys: String, CodingKey {
        case id, statement, verificationStatus, confidenceLevel, date, topics, categoryId,
            relationships
    }

    /// Generates a detailed text description of the fact for use in RAG systems.
    /// The description includes the statement, verification status, sources, and contextual information.
    ///
    /// - Returns: A formatted string containing the fact's details
    public func getDetailedDescription() -> String {
        var description = "FACT: \(statement)"

        if let verificationStatus = verificationStatus {
            description += "\nVerification Status: \(verificationStatus.rawValue)"
        }

        if let confidenceLevel = confidenceLevel {
            description += "\nConfidence Level: \(confidenceLevel.rawValue)"
        }

        if let sources = sources, !sources.isEmpty {
            description += "\nSources:"
            for source in sources {
                description += "\n- \(source.name)"
            }
        }

        if let date = date {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            description += "\nDate: \(formatter.string(from: date))"
        }

        if let categoryId = categoryId {
            description += "\nCategory ID: \(categoryId)"
        }

        if let topics = topics, !topics.isEmpty {
            description += "\nTopics: \(topics.joined(separator: ", "))"
        }

        return description
    }

    // MARK: - JSON Schema Provider
    /// Provides the JSON schema for Fact.
    public static var jsonSchema: String {
        """
        {
            "type": "object",
            "properties": {
                "id": {"type": "string"},
                "statement": {"type": "string"},
                "sources": {
                    "type": "array",
                    "items": {
                        "oneOf": [
                            {"$ref": "#/definitions/Organization"},
                            {"$ref": "#/definitions/Person"}
                        ]
                    },
                    "optional": true
                },
                "verificationStatus": {
                    "type": "string",
                    "enum": ["verified", "unverified", "disputed", "retracted"],
                    "optional": true
                },
                "confidenceLevel": {
                    "type": "string",
                    "enum": ["high", "medium", "low"],
                    "optional": true
                },
                "date": {"type": "string", "format": "date-time", "optional": true},
                "topics": {
                    "type": "array",
                    "items": {"type": "string"},
                    "optional": true
                },
                "categoryId": {"type": "string", "optional": true},
                "relatedEntities": {
                    "type": "array",
                    "items": {
                        "oneOf": [
                            {"$ref": "#/definitions/Organization"},
                            {"$ref": "#/definitions/Person"},
                            {"$ref": "#/definitions/Location"}
                        ]
                    },
                    "optional": true
                },
                "metadata": {
                    "type": "object",
                    "additionalProperties": true,
                    "optional": true
                }
            },
            "required": ["id", "statement"],
            "definitions": {
                "Organization": {"$ref": "Organization.jsonSchema"},
                "Person": {"$ref": "Person.jsonSchema"},
                "Location": {"$ref": "Location.jsonSchema"}
            }
        }
        """
    }
}
