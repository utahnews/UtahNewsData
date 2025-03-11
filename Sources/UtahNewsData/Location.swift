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

/// Represents a geographic location in the news data system.
/// This can be a city, neighborhood, landmark, or any place
/// relevant to news content.
public struct Location: AssociatedData, Codable, Hashable, Equatable, JSONSchemaProvider, Sendable
{  // Added JSONSchemaProvider and Sendable conformance
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
                    "coordinates": {"type": ["object", "null"]}
                },
                "required": ["id", "name"]
            }
            """
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
