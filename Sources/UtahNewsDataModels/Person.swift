//
//  Person.swift
//  UtahNewsDataModels
//
//  Created by Mark Evans on 01/29/25
//
//  Summary: Defines the Person model which represents individuals in the UtahNewsDataModels system.
//           Lightweight version without HTML parsing capabilities.

import Foundation

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
public struct Person: AssociatedData, Codable, Identifiable, Hashable, JSONSchemaProvider, Sendable {
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