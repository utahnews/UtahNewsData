//
//  Location.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

/*
 # Location Model
 
 This file defines the Location model, which represents geographic locations
 in the UtahNewsData system. Locations can be cities, neighborhoods, landmarks,
 or any place relevant to news content.
 
 ## Key Features:
 
 1. Core identification (id, name)
 2. Optional address information
 3. Optional geographic coordinates
 
 ## Usage:
 
 ```swift
 // Create a basic location
 let location = Location(name: "Salt Lake City")
 
 // Create a location with coordinates
 let detailedLocation = Location(
     name: "Utah State Capitol",
     coordinates: Coordinates(latitude: 40.7767, longitude: -111.8880)
 )
 
 // Add a relationship to another entity
 var updatedLocation = location
 updatedLocation.relationships.append(
     Relationship(
         id: newsEvent.id,
         type: .newsEvent,
         displayName: "Hosted",
         context: "Location of the press conference"
     )
 )
 ```
 
 Locations can be associated with various entities such as news events,
 organizations, people, and more to provide geographic context.
 */

// Location.swift
// Summary: Defines the Location structure for the UtahNewsData module.
//          Now includes a convenience initializer to create a Location with coordinates.

import SwiftUI

/// Represents a geographic location in the news data system.
/// This can be a city, neighborhood, landmark, or any place
/// relevant to news content.
public struct Location: AssociatedData, Codable, Hashable, Equatable {
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
}

/// Represents geographic coordinates with latitude and longitude.
public struct Coordinates: BaseEntity, Codable, Hashable, Equatable {
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
    public init(id: String = UUID().uuidString, 
                name: String, 
                latitude: Double, 
                longitude: Double) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
}
