//
//  Jurisdiction.swift
//  UtahNewsData
//
//  Created by Mark Evans on 12/10/24.
//
//  Summary: Defines the Jurisdiction model which represents governmental jurisdictions
//           in the UtahNewsData system. Now conforms to JSONSchemaProvider to provide a static JSON schema for LLM responses.

import SwiftUI
import Foundation

/// Represents the type of governmental jurisdiction.
/// Used to categorize jurisdictions by their administrative level.
public enum JurisdictionType: String, Codable, CaseIterable {
    /// City or municipal government
    case city
    
    /// County government
    case county
    
    /// State government
    case state

    /// Returns a human-readable label for the jurisdiction type.
    public var label: String {
        switch self {
        case .city: return "City"
        case .county: return "County"
        case .state: return "State"
        }
    }
}

/// Represents a governmental jurisdiction such as a city, county, or state.
/// Jurisdictions are important entities for categorizing and organizing news
/// content by geographic and administrative boundaries.
public struct Jurisdiction: AssociatedData, Identifiable, Codable, JSONSchemaProvider { // Added JSONSchemaProvider conformance
    /// Unique identifier for the jurisdiction
    public var id: String
    
    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []
    
    /// Type of jurisdiction (city, county, state)
    public var type: JurisdictionType
    
    /// Name of the jurisdiction
    public var name: String
    
    /// Geographic location associated with the jurisdiction
    public var location: Location?
    
    /// Official website URL for the jurisdiction
    public var website: String?
    
    /// Creates a new jurisdiction with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the jurisdiction (defaults to a new UUID string)
    ///   - type: Type of jurisdiction (city, county, state)
    ///   - name: Name of the jurisdiction
    ///   - location: Geographic location associated with the jurisdiction
    public init(id: String = UUID().uuidString, type: JurisdictionType, name: String, location: Location? = nil) {
        self.id = id
        self.type = type
        self.name = name
        self.location = location
    }

    /// CodingKeys for custom encoding and decoding
    enum CodingKeys: String, CodingKey {
        case id
        case relationships
        case type
        case name
        case location
        case website
    }

    /// Custom decoder to handle optional location data safely.
    /// This ensures that if location data is missing or malformed in the stored data,
    /// the location property will be set to nil rather than causing a decoding error.
    ///
    /// - Parameter decoder: The decoder to read data from
    /// - Throws: DecodingError if required properties cannot be decoded
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.relationships = (try? container.decode([Relationship].self, forKey: .relationships)) ?? []
        self.type = try container.decode(JurisdictionType.self, forKey: .type)
        self.name = try container.decode(String.self, forKey: .name)
        // Use decodeIfPresent for location so it's nil if field is missing or can't decode
        self.location = try? container.decodeIfPresent(Location.self, forKey: .location)
        self.website = try? container.decodeIfPresent(String.self, forKey: .website)
    }
    
    // MARK: - JSON Schema Provider
    /// Provides the JSON schema for Jurisdiction.
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "id": {"type": "string"},
                "relationships": {
                    "type": "array",
                    "items": {"type": "object"}
                },
                "type": {"type": "string"},
                "name": {"type": "string"},
                "location": {"type": ["object", "null"]},
                "website": {"type": ["string", "null"]}
            },
            "required": ["id", "type", "name"]
        }
        """
    }
}
