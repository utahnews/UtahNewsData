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
import SwiftSoup

/// Represents the type of governmental jurisdiction.
/// Used to categorize jurisdictions by their administrative level.
public enum JurisdictionType: String, Codable, CaseIterable, Sendable {
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
public struct Jurisdiction: AssociatedData, Identifiable, Codable, JSONSchemaProvider, HTMLParsable, Sendable {
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

    // MARK: - HTMLParsable Implementation
    
    public static func parse(from document: Document) throws -> Self {
        // Try to find the jurisdiction name
        let nameOpt = try document.select(".jurisdiction h2[itemprop='name']").first()?.text()
            ?? document.select("[itemprop='name'], .jurisdiction-name").first()?.text()
            ?? document.select("meta[property='og:site_name']").first()?.attr("content")
            ?? document.select("title").first()?.text()
        
        guard let name = nameOpt else {
            throw ParsingError.invalidHTML
        }
        
        // Try to find jurisdiction type
        let typeStr = try document.select("[itemprop='jurisdictionType'], .jurisdiction-type").first()?.text()
            ?? document.select("meta[name='jurisdiction-type']").first()?.attr("content")
        
        let type: JurisdictionType
        switch typeStr?.lowercased() {
        case let str where str?.contains("city") ?? false:
            type = .city
        case let str where str?.contains("county") ?? false:
            type = .county
        case let str where str?.contains("state") ?? false:
            type = .state
        default:
            // Default to city if type can't be determined
            type = .city
        }
        
        // Try to find website
        let website = try document.select(".jurisdiction a[itemprop='url']").first()?.attr("href")
            ?? document.select("[itemprop='url']").first()?.attr("href")
            ?? document.select("meta[property='og:url']").first()?.attr("content")
        
        // Try to find location
        var location: Location? = nil
        if let locationElement = try document.select("[itemprop='location'], .jurisdiction-location").first() {
            let locationDoc = try SwiftSoup.parse(try locationElement.html())
            location = try? Location.parse(from: locationDoc)
        }
        
        var jurisdiction = Jurisdiction(
            id: UUID().uuidString,
            type: type,
            name: name,
            location: location
        )
        jurisdiction.website = website
        
        return jurisdiction
    }
}
