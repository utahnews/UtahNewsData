//
//  Location.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

// Location.swift
// Summary: Defines the Location structure for the UtahNewsData module.
//          Now includes a convenience initializer to create a Location with coordinates.

import SwiftUI

public struct Location: AssociatedData, Codable, Hashable, Equatable {
    public var id: String
    public var relationships: [Relationship] = []
    public var name: String
    public var address: String?
    public var coordinates: Coordinates?
    
    // Existing initializer
    public init(id: String = UUID().uuidString, name: String) {
        self.id = id
        self.name = name
    }
    
    // New convenience initializer to include coordinates
    public init(id: String = UUID().uuidString, name: String, coordinates: Coordinates?) {
        self.id = id
        self.name = name
        self.coordinates = coordinates
    }
}

public struct Coordinates: Codable, Hashable, Equatable {
    public var latitude: Double
    public var longitude: Double
    
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
