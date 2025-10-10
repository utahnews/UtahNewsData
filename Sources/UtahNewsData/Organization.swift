//
//  Organization.swift
//  UtahNewsData
//
//  Created by Mark Evans on 10/25/24.
//

/*
 # Organization Model

 This file defines the Organization model, which represents companies, institutions,
 government agencies, and other organizational entities in the UtahNewsData system.
 The Organization model is one of the core entity types and can be related to many
 other entities such as people, locations, news stories, and more.

 ## Key Features:

 1. Core identification (id, name)
 2. Organizational description
 3. Contact information
 4. Web presence

 ## Usage:

 ```swift
 // Create a basic organization
 let organization = Organization(
     name: "Utah News Network",
     orgDescription: "A news organization covering Utah news"
 )

 // Create an organization with contact information
 let detailedOrg = Organization(
     name: "Utah Tech Association",
     orgDescription: "Industry association for technology companies in Utah",
     contactInfo: [
         ContactInfo(
             name: "Media Relations",
             email: "media@utatech.org",
             phone: "801-555-1234"
         )
     ],
     website: "https://utatech.org"
 )

 // Add a relationship to another entity
 var updatedOrg = organization
 updatedOrg.relationships.append(
     Relationship(
         id: person.id,
         type: .person,
         displayName: "Employs",
         context: "Chief Executive Officer"
     )
 )
 ```

 The Organization model implements EntityDetailsProvider, which allows it to generate
 rich text descriptions for RAG systems.
 */

import SwiftUI
import Foundation
import SwiftSoup

/// Represents the type of organization
public enum OrganizationType: String, Codable, CaseIterable, Sendable {
    /// For-profit corporation
    case corporation
    /// Non-profit organization
    case nonProfit
    /// Government agency or department
    case government
    /// Educational institution
    case educational
    /// Media outlet or news organization
    case mediaOutlet
    
    /// Returns a human-readable label for the organization type
    public var label: String {
        switch self {
        case .corporation:
            return "Corporation"
        case .nonProfit:
            return "Non-Profit Organization"
        case .government:
            return "Government Agency"
        case .educational:
            return "Educational Institution"
        case .mediaOutlet:
            return "Media Outlet"
        }
    }
}

/// Represents an organization in the UtahNewsData system
public struct Organization: AssociatedData, Codable, Identifiable, Hashable, Equatable, EntityDetailsProvider, Sendable {
    /// Unique identifier for the organization
    public var id: String

    /// Relationships to other entities (people, locations, etc.)
    public var relationships: [Relationship] = []

    /// The organization's name
    public var name: String

    /// Description of the organization
    /// Note: This is stored as `orgDescription` internally to avoid conflicts with Swift's `description`
    public var orgDescription: String?

    /// Array of contact information entries
    public var contactInfo: [ContactInfo]? = []

    /// Organization's website URL
    public var website: String?

    /// Organization's logo URL
    public var logoURL: String?

    /// Organization's location
    public var location: Location?

    /// Organization's type
    public var type: String?

    /// Content URLs (feeds/pages) for the organization
    public var contentUrls: [String]?

    /// Creates a new Organization instance with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID string)
    ///   - name: The organization's name
    ///   - orgDescription: Description of the organization
    ///   - contactInfo: Array of contact information entries
    ///   - website: Organization's website URL
    ///   - logoURL: Organization's logo URL
    ///   - location: Organization's location
    ///   - type: Organization's type
    ///   - contentUrls: Content URLs (feeds/pages) for the organization
    public init(
        id: String = UUID().uuidString,
        name: String,
        orgDescription: String? = nil,
        contactInfo: [ContactInfo]? = nil,
        website: String? = nil,
        logoURL: String? = nil,
        location: Location? = nil,
        type: String? = nil,
        contentUrls: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.orgDescription = orgDescription
        self.contactInfo = contactInfo
        self.website = website
        self.logoURL = logoURL
        self.location = location
        self.type = type
        self.contentUrls = contentUrls
    }

    /// Creates an Organization instance by decoding from the given decoder.
    /// Handles backward compatibility with the legacy "description" field.
    ///
    /// - Parameter decoder: The decoder to read data from
    /// - Throws: An error if decoding fails
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Use decodeIfPresent for id and fall back to a new UUID if missing.
        self.id = (try? container.decodeIfPresent(String.self, forKey: .id)) ?? UUID().uuidString
        self.relationships =
            (try? container.decode([Relationship].self, forKey: .relationships)) ?? []
        self.name = try container.decode(String.self, forKey: .name)
        // First try the new key "orgDescription", then fall back to the legacy key "description"
        let decodedDesc =
            (try? container.decodeIfPresent(String.self, forKey: .orgDescription))
            ?? (try? container.decodeIfPresent(String.self, forKey: .oldDescription))
        self.orgDescription = (decodedDesc?.isEmpty ?? true) ? nil : decodedDesc
        self.contactInfo = try? container.decode([ContactInfo].self, forKey: .contactInfo)
        self.website = try? container.decode(String.self, forKey: .website)
        self.logoURL = try? container.decode(String.self, forKey: .logoURL)
        self.location = try? container.decode(Location.self, forKey: .location)
        self.type = try? container.decode(String.self, forKey: .type)
        self.contentUrls = try? container.decode([String].self, forKey: .contentUrls)
    }

    /// Encodes the Organization instance to the given encoder.
    /// Maintains backward compatibility by encoding to both the new and legacy description fields.
    ///
    /// - Parameter encoder: The encoder to write data to
    /// - Throws: An error if encoding fails
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(relationships, forKey: .relationships)
        try container.encode(name, forKey: .name)
        // Always encode using the legacy key "description" for backward compatibility.
        try container.encode(orgDescription, forKey: .oldDescription)
        try container.encode(contactInfo, forKey: .contactInfo)
        try container.encode(website, forKey: .website)
        try container.encode(logoURL, forKey: .logoURL)
        try container.encode(location, forKey: .location)
        try container.encode(type, forKey: .type)
        try container.encode(contentUrls, forKey: .contentUrls)
    }

    /// Keys used for encoding and decoding Organization instances
    private enum CodingKeys: String, CodingKey {
        case id, relationships, name
        case orgDescription
        case oldDescription = "description"
        case contactInfo, website, logoURL, location, type, contentUrls
    }

    // MARK: - JSONSchemaProvider Implementation
    
    public static var jsonSchema: String {
        """
        {
            "type": "object",
            "properties": {
                "id": { "type": "string", "format": "uuid" },
                "name": { "type": "string" },
                "type": { "type": "string", "enum": ["corporation", "nonProfit", "government", "educational", "mediaOutlet"] },
                "description": { "type": "string" },
                "website": { "type": "string", "format": "uri" },
                "location": { "$ref": "#/definitions/Location" },
                "foundingDate": { "type": "string", "format": "date-time" },
                "employees": { "type": "integer", "minimum": 0 },
                "industry": { "type": "string" },
                "socialMediaProfiles": {
                    "type": "object",
                    "additionalProperties": { "type": "string", "format": "uri" }
                },
                "contactInfo": { "$ref": "#/definitions/ContactInfo" },
                "contentUrls": {
                    "type": "array",
                    "items": { "type": "string", "format": "uri" }
                }
            },
            "required": ["id", "name", "type"]
        }
        """
    }
    
    // MARK: - EntityDetailsProvider Implementation
    
    public var entityType: EntityType {
        .organization
    }
    
    public var entityName: String {
        name
    }
    
    public var entityDescription: String? {
        orgDescription
    }
    
    public var entityLocation: Location? {
        location
    }
    
    public var entityURL: URL? {
        if let websiteStr = website {
            return URL(string: websiteStr)
        }
        return nil
    }
    
    public var entityImageURL: URL? {
        nil // Organizations don't have a direct image URL in the current model
    }
    
    public var entityIdentifier: String {
        id
    }
    
    public var entityMetadata: [String: String] {
        var metadata: [String: String] = [
            "type": type ?? "Unknown"
        ]
        return metadata
    }

    public func getDetailedDescription() -> String {
        var description = "\(name)"
        
        if let desc = orgDescription {
            description += "\n\n\(desc)"
        }
        
        if let type = type {
            description += "\nType: \(type)"
        }
        
        if let website = website {
            description += "\nWebsite: \(website)"
        }
        
        if let location = location {
            description += "\nLocation: \(location.name)"
        }
        
        if let contacts = contactInfo, !contacts.isEmpty {
            description += "\n\nContact Information:"
            for contact in contacts {
                if let email = contact.email {
                    description += "\nEmail: \(email)"
                }
                if let phone = contact.phone {
                    description += "\nPhone: \(phone)"
                }
            }
        }
        
        return description
    }
}
