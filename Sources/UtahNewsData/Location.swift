//
//  Location.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

import SwiftUI

public struct Location: AssociatedData, Codable, Hashable, Equatable {
    public var id: String
    public var relationships: [Relationship] = []
    public var name: String
    public var address: String?
    public var coordinates: Coordinates?

    public init(id: String = UUID().uuidString, name: String) {
        self.id = id
        self.name = name
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
