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
    public var dateVerified: Date?  // Made optional to handle empty date strings

    // Default initializer
    public init(
        id: String = UUID().uuidString,
        statement: String,
        dateVerified: Date? = nil
    ) {
        self.id = id
        self.statement = statement
        self.dateVerified = dateVerified
    }
    
    // Custom initializer to supply a default id if missing
    // and to decode the dateVerified string, setting it to nil if empty.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.statement = try container.decode(String.self, forKey: .statement)
        
        // Decode the date string and convert it to a Date.
        let dateString = try container.decode(String.self, forKey: .dateVerified)
        if dateString.isEmpty {
            self.dateVerified = nil
        } else {
            let formatter = ISO8601DateFormatter()
            self.dateVerified = formatter.date(from: dateString)
        }
        
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.relationships = (try? container.decode([Relationship].self, forKey: .relationships)) ?? []
    }
    
    // Standard encoding implementation.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(relationships, forKey: .relationships)
        try container.encode(statement, forKey: .statement)
        
        // When encoding, if dateVerified is not nil, encode it as an ISO8601 string; otherwise encode an empty string.
        if let date = dateVerified {
            let formatter = ISO8601DateFormatter()
            let dateString = formatter.string(from: date)
            try container.encode(dateString, forKey: .dateVerified)
        } else {
            try container.encode("", forKey: .dateVerified)
        }
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
