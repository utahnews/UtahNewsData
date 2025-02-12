//
//  Person.swift
//  UtahNewsData
//
//  Created by Mark Evans on [date].
//

import SwiftUI

public struct Person: AssociatedData, Codable, Identifiable, Hashable {
    
    public var id: String
    public var relationships: [Relationship] = []
    public var name: String
    public var details: String

    public init(
        id: String = UUID().uuidString,
        relationships: [Relationship] = [],
        name: String,
        details: String
    ) {
        self.id = id
        self.relationships = relationships
        self.name = name
        self.details = details
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.details = try container.decode(String.self, forKey: .details)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(details, forKey: .details)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, details
    }
}
