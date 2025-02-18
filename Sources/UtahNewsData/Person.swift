//
//  Person.swift
//  UtahNewsData
//
//  Created by Mark Evans on [date].
//
//  Updated to include additional properties for public interest/notability.

import SwiftUI

public struct Person: AssociatedData, Codable, Identifiable, Hashable {
    // MARK: - Core Properties
    public var id: String
    public var relationships: [Relationship] = []
    public var name: String
    public var details: String

    // MARK: - Additional Public Figure Properties
    public var biography: String?                // Optional detailed biography
    public var birthDate: Date?                  // Optional birth date
    public var deathDate: Date?                  // Optional death date, if applicable
    public var occupation: String?               // Optional occupation
    public var nationality: String?              // Optional nationality
    public var notableAchievements: [String]?    // Optional list of notable achievements

    // MARK: - Initializer
    public init(
        id: String = UUID().uuidString,
        relationships: [Relationship] = [],
        name: String,
        details: String,
        biography: String? = nil,
        birthDate: Date? = nil,
        deathDate: Date? = nil,
        occupation: String? = nil,
        nationality: String? = nil,
        notableAchievements: [String]? = nil
    ) {
        self.id = id
        self.relationships = relationships
        self.name = name
        self.details = details
        self.biography = biography
        self.birthDate = birthDate
        self.deathDate = deathDate
        self.occupation = occupation
        self.nationality = nationality
        self.notableAchievements = notableAchievements
    }
    
    // MARK: - Decodable
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.details = try container.decode(String.self, forKey: .details)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.relationships = (try? container.decode([Relationship].self, forKey: .relationships)) ?? []
        
        // Decode additional properties
        self.biography = try? container.decode(String.self, forKey: .biography)
        self.birthDate = try? container.decode(Date.self, forKey: .birthDate)
        self.deathDate = try? container.decode(Date.self, forKey: .deathDate)
        self.occupation = try? container.decode(String.self, forKey: .occupation)
        self.nationality = try? container.decode(String.self, forKey: .nationality)
        self.notableAchievements = try? container.decode([String].self, forKey: .notableAchievements)
    }
    
    // MARK: - Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(relationships, forKey: .relationships)
        try container.encode(name, forKey: .name)
        try container.encode(details, forKey: .details)
        
        // Encode additional properties
        try container.encode(biography, forKey: .biography)
        try container.encode(birthDate, forKey: .birthDate)
        try container.encode(deathDate, forKey: .deathDate)
        try container.encode(occupation, forKey: .occupation)
        try container.encode(nationality, forKey: .nationality)
        try container.encode(notableAchievements, forKey: .notableAchievements)
    }
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id, relationships, name, details
        case biography, birthDate, deathDate, occupation, nationality, notableAchievements
    }
}
