//
//  Fact.swift
//  UtahNewsData
//
//  Created by Mark Evans on 10/25/24.
//

import SwiftUI

public struct Fact: AssociatedData, Codable {
    public var id: String
    public var relationships: [Relationship] = []
    public var statement: String
    public var dateVerified: Date

    // Default initializer
    public init(
        id: String = UUID().uuidString,
        statement: String,
        dateVerified: Date
    ) {
        self.id = id
        self.statement = statement
        self.dateVerified = dateVerified
    }
    
    // Custom initializer to supply a default id if missing.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.statement = try container.decode(String.self, forKey: .statement)
        self.dateVerified = try container.decode(Date.self, forKey: .dateVerified)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.relationships = (try? container.decode([Relationship].self, forKey: .relationships)) ?? []
    }
    
    // Standard encoding implementation.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(relationships, forKey: .relationships)
        try container.encode(statement, forKey: .statement)
        try container.encode(dateVerified, forKey: .dateVerified)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case relationships
        case statement
        case dateVerified
    }
}

public enum Verification: String, CaseIterable {
    case none = "None"
    case human = "Human"
    case ai = "AI"
}
