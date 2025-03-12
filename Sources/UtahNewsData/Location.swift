//
//  Location.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//
//  Summary: Defines the Location model which represents geographic locations
//           in the UtahNewsData system. Now conforms to JSONSchemaProvider to provide a static JSON schema for LLM responses.
//           Also includes the Coordinates struct with JSON schema updates.

import Foundation
import SwiftUI
import SwiftSoup

/// Represents a physical location in the UtahNewsData system
public struct Location: Codable, Identifiable, Hashable, Equatable, AssociatedData, HTMLParsable, Sendable, JSONSchemaProvider {
    /// Unique identifier for the location
    public var id: String

    /// Relationships to other entities (events, organizations, etc.)
    public var relationships: [Relationship] = []

    /// The location's name (e.g., "Salt Lake City", "Utah State Capitol")
    public var name: String

    /// Optional street address or descriptive location
    public var address: String?

    /// Optional geographic coordinates (latitude/longitude)
    public var coordinates: Coordinates?

    /// Latitude coordinate (north/south position)
    public var latitude: Double?

    /// Longitude coordinate (east/west position)
    public var longitude: Double?

    /// City of the location
    public var city: String?

    /// State of the location
    public var state: String?

    /// Zip code of the location
    public var zipCode: String?

    /// Country of the location
    public var country: String?

    /// Creates a new Location with a name.
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID string)
    ///   - name: The location's name
    public init(id: String = UUID().uuidString, name: String) {
        self.id = id
        self.name = name
    }

    /// Creates a new Location with a name and coordinates.
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID string)
    ///   - name: The location's name
    ///   - coordinates: Geographic coordinates (latitude/longitude)
    public init(id: String = UUID().uuidString, name: String, coordinates: Coordinates?) {
        self.id = id
        self.name = name
        self.coordinates = coordinates
    }

    /// Creates a new Location with additional details.
    ///
    /// - Parameters:
    ///   - latitude: Latitude coordinate
    ///   - longitude: Longitude coordinate
    ///   - address: Street address
    ///   - city: City
    ///   - state: State
    ///   - zipCode: Zip code
    ///   - country: Country
    ///   - relationships: Array of relationships to other entities
    public init(
        latitude: Double? = nil,
        longitude: Double? = nil,
        address: String? = nil,
        city: String? = nil,
        state: String? = nil,
        zipCode: String? = nil,
        country: String? = nil,
        relationships: [Relationship] = []
    ) {
        self.id = UUID().uuidString
        self.name = [city, state].compactMap { $0 }.joined(separator: ", ")
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
        self.relationships = relationships
    }

    // MARK: - JSON Schema Provider
    /// Provides the JSON schema for Location.
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
                    "name": {"type": "string"},
                    "address": {"type": ["string", "null"]},
                    "coordinates": {"type": ["object", "null"]},
                    "latitude": {"type": ["number", "null"]},
                    "longitude": {"type": ["number", "null"]},
                    "city": {"type": ["string", "null"]},
                    "state": {"type": ["string", "null"]},
                    "zipCode": {"type": ["string", "null"]},
                    "country": {"type": ["string", "null"]}
                },
                "required": ["id", "name"]
            }
            """
    }

    // MARK: - HTMLParsable Implementation
    
    public static func parse(from document: Document) throws -> Self {
        // Try to find coordinates
        let latitudeStr = try document.select("[itemprop='latitude'], meta[property='place:location:latitude']").first()?.attr("content")
        let longitudeStr = try document.select("[itemprop='longitude'], meta[property='place:location:longitude']").first()?.attr("content")
        
        let latitude = latitudeStr.flatMap { Double($0) }
        let longitude = longitudeStr.flatMap { Double($0) }
        
        // Try to find address components
        let streetAddress = try document.select("[itemprop='streetAddress']").first()?.text()
        let city = try document.select("[itemprop='addressLocality']").first()?.text()
        let state = try document.select("[itemprop='addressRegion']").first()?.text()
        let zipCode = try document.select("[itemprop='postalCode']").first()?.text()
        let country = try document.select("[itemprop='addressCountry']").first()?.text()
        
        // Try to construct full address (excluding country)
        let addressComponents = [streetAddress, city, state, zipCode].compactMap { $0 }
        let fullAddress = addressComponents.isEmpty ? nil : addressComponents.joined(separator: ", ")
        
        return Location(
            latitude: latitude,
            longitude: longitude,
            address: fullAddress,
            city: city,
            state: state,
            zipCode: zipCode,
            country: country
        )
    }
}

/// Represents geographic coordinates with latitude and longitude.
public struct Coordinates: BaseEntity, Codable, Hashable, Equatable, JSONSchemaProvider, Sendable
{  // Added JSONSchemaProvider and Sendable conformance
    /// Unique identifier for the coordinates
    public var id: String

    /// The name or description of these coordinates
    public var name: String

    /// Latitude coordinate (north/south position)
    public var latitude: Double

    /// Longitude coordinate (east/west position)
    public var longitude: Double

    /// Creates new geographic coordinates.
    /// - Parameters:
    ///   - id: Unique identifier for the coordinates
    ///   - name: Name or description of these coordinates (e.g., "Downtown SLC")
    ///   - latitude: Latitude coordinate
    ///   - longitude: Longitude coordinate
    public init(
        id: String = UUID().uuidString,
        name: String,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }

    // MARK: - JSON Schema Provider
    /// Provides the JSON schema for Coordinates.
    public static var jsonSchema: String {
        return """
            {
                "type": "object",
                "properties": {
                    "id": {"type": "string"},
                    "name": {"type": "string"},
                    "latitude": {"type": "number"},
                    "longitude": {"type": "number"}
                },
                "required": ["id", "name", "latitude", "longitude"]
            }
            """
    }
}
