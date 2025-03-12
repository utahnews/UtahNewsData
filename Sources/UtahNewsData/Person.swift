//
//  Person.swift
//  UtahNewsData
//
//  Created by Mark Evans on [date].
//
//  Updated to include additional properties for public interest/notability.

/*
 # Person Model

 This file defines the Person model, which represents individuals in the UtahNewsData system.
 The Person model is one of the core entity types and can be related to many other entities
 such as organizations, news stories, quotes, and more.

 ## Key Features:

 1. Core identification (id, name, details)
 2. Biographical information (biography, birth/death dates, nationality)
 3. Professional details (occupation, achievements)
 4. Contact information (email, phone, website, address)
 5. Location data (string representation and coordinates)
 6. Social media presence

 ## Usage:

 ```swift
 // Create a basic person
 let person = Person(
     name: "Jane Doe",
     details: "Reporter for Utah News Network"
 )

 // Create a person with more details
 let detailedPerson = Person(
     name: "John Smith",
     details: "Political analyst",
     biography: "John Smith is a political analyst with 15 years of experience...",
     occupation: "Political Analyst",
     nationality: "American",
     notableAchievements: ["Published 3 books", "Regular contributor to major news outlets"]
 )

 // Add a relationship to another entity
 var updatedPerson = person
 updatedPerson.relationships.append(
     Relationship(
         id: organization.id,
         type: .organization,
         displayName: "Works at",
         context: "Senior reporter since 2020"
     )
 )
 ```

 The Person model implements EntityDetailsProvider, which allows it to generate
 rich text descriptions for RAG systems.
 */

import SwiftUI
import Foundation
import SwiftSoup

/// Represents an educational qualification or degree
public struct Education: Codable, Hashable, Equatable, Sendable {
    /// Name of the educational institution
    public var institution: String
    
    /// Type of degree or qualification (e.g., "Bachelor's", "Master's", "Ph.D.")
    public var degree: String?
    
    /// Field of study
    public var field: String?
    
    /// Year the degree was awarded
    public var year: Int?
    
    /// Creates a new Education instance
    /// - Parameters:
    ///   - institution: Name of the educational institution
    ///   - degree: Type of degree or qualification
    ///   - field: Field of study
    ///   - year: Year the degree was awarded
    public init(
        institution: String,
        degree: String? = nil,
        field: String? = nil,
        year: Int? = nil
    ) {
        self.institution = institution
        self.degree = degree
        self.field = field
        self.year = year
    }
}

/// Represents a person in the news data system.
/// This can be a journalist, public figure, expert, or any individual
/// relevant to news content.
public struct Person: AssociatedData, Codable, Identifiable, Hashable, EntityDetailsProvider,
    JSONSchemaProvider, Sendable
{
    // MARK: - Core Properties

    /// Unique identifier for the person
    public var id: String

    /// Relationships to other entities (organizations, locations, etc.)
    public var relationships: [Relationship] = []

    /// The person's full name
    public var name: String

    /// Brief description or summary of the person
    public var details: String

    // MARK: - Additional Public Figure Properties

    /// Detailed biography or background information
    public var biography: String?

    /// Date of birth, if known
    public var birthDate: Date?

    /// Date of death, if applicable
    public var deathDate: Date?

    /// Professional occupation or role
    public var occupation: String?

    /// Nationality or citizenship
    public var nationality: String?

    /// List of significant achievements or contributions
    public var notableAchievements: [String]?

    /// URL to a profile image or photo
    public var imageURL: String?

    /// Text description of location (e.g., "Salt Lake City, Utah")
    public var locationString: String?

    /// Latitude coordinate for precise location
    public var locationLatitude: Double?

    /// Longitude coordinate for precise location
    public var locationLongitude: Double?

    /// Email address for contact
    public var email: String?

    /// Personal or professional website
    public var website: String?

    /// Phone number for contact
    public var phone: String?

    /// Physical address
    public var address: String?

    /// Dictionary of social media platforms and corresponding handles
    /// Example: ["Twitter": "@janedoe", "LinkedIn": "jane-doe"]
    public var socialMediaHandles: [String: String]?

    // MARK: - Initializer

    /// Creates a new Person instance with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID string)
    ///   - relationships: Array of relationships to other entities (defaults to empty)
    ///   - name: The person's full name
    ///   - details: Brief description or summary
    ///   - biography: Detailed background information
    ///   - birthDate: Date of birth
    ///   - deathDate: Date of death, if applicable
    ///   - occupation: Professional role or job title
    ///   - nationality: Citizenship or nationality
    ///   - notableAchievements: List of significant accomplishments
    ///   - imageURL: URL to a profile image
    ///   - locationString: Text description of location
    ///   - locationLatitude: Latitude coordinate
    ///   - locationLongitude: Longitude coordinate
    ///   - email: Contact email address
    ///   - website: Personal or professional website
    ///   - phone: Contact phone number
    ///   - address: Physical address
    ///   - socialMediaHandles: Dictionary of platform names and handles
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

    /// Creates a Person instance by decoding from the given decoder.
    /// Provides fallbacks for optional properties and generates a UUID if id is missing.
    ///
    /// - Parameter decoder: The decoder to read data from
    /// - Throws: An error if decoding fails
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.details = try container.decode(String.self, forKey: .details)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.relationships =
            (try? container.decode([Relationship].self, forKey: .relationships)) ?? []

        self.biography = try? container.decode(String.self, forKey: .biography)
        self.birthDate = try? container.decode(Date.self, forKey: .birthDate)
        self.deathDate = try? container.decode(Date.self, forKey: .deathDate)
        self.occupation = try? container.decode(String.self, forKey: .occupation)
        self.nationality = try? container.decode(String.self, forKey: .nationality)
        self.notableAchievements = try? container.decode(
            [String].self, forKey: .notableAchievements)

        // New properties decoding
        self.imageURL = try? container.decode(String.self, forKey: .imageURL)
        self.locationString = try? container.decode(String.self, forKey: .locationString)
        self.locationLatitude = try? container.decode(Double.self, forKey: .locationLatitude)
        self.locationLongitude = try? container.decode(Double.self, forKey: .locationLongitude)
        self.email = try? container.decode(String.self, forKey: .email)
        self.website = try? container.decode(String.self, forKey: .website)
        self.phone = try? container.decode(String.self, forKey: .phone)
        self.address = try? container.decode(String.self, forKey: .address)
        self.socialMediaHandles = try? container.decode(
            [String: String].self, forKey: .socialMediaHandles)
    }

    // MARK: - Encodable

    /// Encodes the Person instance to the given encoder.
    ///
    /// - Parameter encoder: The encoder to write data to
    /// - Throws: An error if encoding fails
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

    /// Keys used for encoding and decoding Person instances
    enum CodingKeys: String, CodingKey {
        case id, relationships, name, details
        case biography, birthDate, deathDate, occupation, nationality, notableAchievements
        // New keys added
        case imageURL, locationString, locationLatitude, locationLongitude, email, website, phone,
            address, socialMediaHandles
    }

    // MARK: - EntityDetailsProvider Implementation

    /// Generates a detailed description of the person for RAG context.
    /// This includes biographical information, professional details,
    /// achievements, location, and contact information.
    ///
    /// - Returns: A formatted string containing the person's details
    public func getDetailedDescription() -> String {
        var description = details + "\n\n"

        if let bio = biography {
            description += "**Biography**: \(bio)\n\n"
        }

        if let occupation = occupation {
            description += "**Occupation**: \(occupation)\n"
        }

        if let nationality = nationality {
            description += "**Nationality**: \(nationality)\n"
        }

        // Add birth/death dates if available
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        if let birthDate = birthDate {
            description += "**Born**: \(dateFormatter.string(from: birthDate))"
            if let deathDate = deathDate {
                description += " | **Died**: \(dateFormatter.string(from: deathDate))"
            }
            description += "\n"
        } else if let deathDate = deathDate {
            description += "**Died**: \(dateFormatter.string(from: deathDate))\n"
        }

        // Add notable achievements
        if let achievements = notableAchievements, !achievements.isEmpty {
            description += "\n**Notable Achievements**:\n"
            for achievement in achievements {
                description += "- \(achievement)\n"
            }
            description += "\n"
        }

        // Add location information
        if let location = locationString {
            description += "**Location**: \(location)\n"
        }

        // Add contact information
        var contactInfo = ""
        if let email = email {
            contactInfo += "Email: \(email) | "
        }
        if let phone = phone {
            contactInfo += "Phone: \(phone) | "
        }
        if let website = website {
            contactInfo += "Website: \(website) | "
        }

        if !contactInfo.isEmpty {
            // Remove trailing separator
            contactInfo = String(contactInfo.dropLast(3))
            description += "\n**Contact**: \(contactInfo)\n"
        }

        // Add social media handles
        if let socialMedia = socialMediaHandles, !socialMedia.isEmpty {
            description += "\n**Social Media**:\n"
            for (platform, handle) in socialMedia {
                description += "- \(platform): \(handle)\n"
            }
        }

        return description
    }

    // MARK: - JSONSchemaProvider Implementation
    
    public static var jsonSchema: String {
        """
        {
            "type": "object",
            "properties": {
                "id": { "type": "string", "format": "uuid" },
                "name": { "type": "string" },
                "title": { "type": "string" },
                "biography": { "type": "string" },
                "organization": { "$ref": "#/definitions/Organization" },
                "expertise": {
                    "type": "array",
                    "items": { "type": "string" }
                },
                "education": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "institution": { "type": "string" },
                            "degree": { "type": "string" },
                            "field": { "type": "string" },
                            "year": { "type": "integer" }
                        }
                    }
                },
                "contactInfo": { "$ref": "#/definitions/ContactInfo" },
                "socialMediaProfiles": {
                    "type": "object",
                    "additionalProperties": { "type": "string", "format": "uri" }
                },
                "imageURL": { "type": "string", "format": "uri" },
                "achievements": {
                    "type": "array",
                    "items": { "type": "string" }
                }
            },
            "required": ["id", "name"]
        }
        """
    }
}
