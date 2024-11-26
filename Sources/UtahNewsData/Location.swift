//
//  Location.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

import SwiftUI

public struct Location: AssociatedData, Codable, Hashable, Equatable {
    public var id: UUID
    public var relationships: [Relationship] = []
    public var name: String
    public var address: String?
    public var coordinates: Coordinates?

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

public struct Coordinates: Codable, Hashable, Equatable {
    public var latitude: Double
    public var longitude: Double
}
