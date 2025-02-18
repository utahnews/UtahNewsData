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
    public var biography: String?
    public var birthDate: Date?
    public var deathDate: Date?
    public var occupation: String?
    public var nationality: String?
    public var notableAchievements: [String]?
    public var imageURL: String?
    public var locationString: String?
    public var locationLatitude: Double?
    public var locationLongitude: Double?
    public var email: String?
    public var website: String?
    public var phone: String?
    public var address: String?
    public var socialMediaHandles: [String: String]?

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
        notableAchievements: [String]? = nil,
        imageURL: String? = nil,
        locationString: String? = nil,
        locationLatitude: Double? = nil,
        locationLongitude: Double? = nil,
        email: String? = nil,
        website: String? = nil,
        phone: String? = nil,
        address: String? = nil,
        socialMediaHandles: [String: String]? = [:]
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

        self.imageURL = imageURL
        self.locationString = locationString
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        self.email = email
        self.website = website
        self.phone = phone
        self.address = address
        self.socialMediaHandles = socialMediaHandles
    }
    
    // MARK: - Decodable
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.details = try container.decode(String.self, forKey: .details)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.relationships = (try? container.decode([Relationship].self, forKey: .relationships)) ?? []
        
        self.biography = try? container.decode(String.self, forKey: .biography)
        self.birthDate = try? container.decode(Date.self, forKey: .birthDate)
        self.deathDate = try? container.decode(Date.self, forKey: .deathDate)
        self.occupation = try? container.decode(String.self, forKey: .occupation)
        self.nationality = try? container.decode(String.self, forKey: .nationality)
        self.notableAchievements = try? container.decode([String].self, forKey: .notableAchievements)

        // New properties decoding
        self.imageURL = try? container.decode(String.self, forKey: .imageURL)
        self.locationString = try? container.decode(String.self, forKey: .locationString)
        self.locationLatitude = try? container.decode(Double.self, forKey: .locationLatitude)
        self.locationLongitude = try? container.decode(Double.self, forKey: .locationLongitude)
        self.email = try? container.decode(String.self, forKey: .email)
        self.website = try? container.decode(String.self, forKey: .website)
        self.phone = try? container.decode(String.self, forKey: .phone)
        self.address = try? container.decode(String.self, forKey: .address)
        self.socialMediaHandles = try? container.decode([String: String].self, forKey: .socialMediaHandles)
    }
    
    // MARK: - Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(relationships, forKey: .relationships)
        try container.encode(name, forKey: .name)
        try container.encode(details, forKey: .details)
        
        try container.encode(biography, forKey: .biography)
        try container.encode(birthDate, forKey: .birthDate)
        try container.encode(deathDate, forKey: .deathDate)
        try container.encode(occupation, forKey: .occupation)
        try container.encode(nationality, forKey: .nationality)
        try container.encode(notableAchievements, forKey: .notableAchievements)
        
        // New properties encoding
        try container.encode(imageURL, forKey: .imageURL)
        try container.encode(locationString, forKey: .locationString)
        try container.encode(locationLatitude, forKey: .locationLatitude)
        try container.encode(locationLongitude, forKey: .locationLongitude)
        try container.encode(email, forKey: .email)
        try container.encode(website, forKey: .website)
        try container.encode(phone, forKey: .phone)
        try container.encode(address, forKey: .address)
        try container.encode(socialMediaHandles, forKey: .socialMediaHandles)
    }
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id, relationships, name, details
        case biography, birthDate, deathDate, occupation, nationality, notableAchievements
        // New keys added
        case imageURL, locationString, locationLatitude, locationLongitude, email, website, phone, address, socialMediaHandles
    }
}
