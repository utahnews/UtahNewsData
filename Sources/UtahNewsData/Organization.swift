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

/// Represents an organization in the UtahNewsData system
public struct Organization: AssociatedData, Codable, Identifiable, Hashable, Equatable, EntityDetailsProvider, HTMLParsable, Sendable {
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
    public init(
        id: String = UUID().uuidString,
        name: String,
        orgDescription: String? = nil,
        contactInfo: [ContactInfo]? = nil,
        website: String? = nil,
        logoURL: String? = nil,
        location: Location? = nil,
        type: String? = nil
    ) {
        self.id = id
        self.name = name
        self.orgDescription = orgDescription
        self.contactInfo = contactInfo
        self.website = website
        self.logoURL = logoURL
        self.location = location
        self.type = type
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
    }

    /// Keys used for encoding and decoding Organization instances
    private enum CodingKeys: String, CodingKey {
        case id, relationships, name
        case orgDescription
        case oldDescription = "description"
        case contactInfo, website, logoURL, location, type
    }

    // MARK: - EntityDetailsProvider Implementation

    /// Generates a detailed description of the organization for RAG context.
    /// This includes the organization's description, website, and contact information.
    ///
    /// - Returns: A formatted string containing the organization's details
    public func getDetailedDescription() -> String {
        var description = ""

        if let desc = orgDescription {
            description += desc + "\n\n"
        }

        if let website = website {
            description += "**Website**: \(website)\n\n"
        }

        // Add contact information
        if let contacts = contactInfo, !contacts.isEmpty {
            description += "**Contact Information**:\n\n"

            for (index, contact) in contacts.enumerated() {
                if contacts.count > 1 {
                    description += "### Contact \(index + 1)\n"
                }

                description += "**Name**: \(contact.name)\n"

                if let email = contact.email {
                    description += "**Email**: \(email)\n"
                }

                if let phone = contact.phone {
                    description += "**Phone**: \(phone)\n"
                }

                if let address = contact.address {
                    description += "**Address**: \(address)\n"
                }

                if let website = contact.website {
                    description += "**Website**: \(website)\n"
                }

                // Add social media handles
                if let socialMedia = contact.socialMediaHandles, !socialMedia.isEmpty {
                    description += "\n**Social Media**:\n"
                    for (platform, handle) in socialMedia {
                        description += "- \(platform): \(handle)\n"
                    }
                }

                description += "\n"
            }
        }

        return description
    }

    /// JSON schema for LLM responses
    public static var jsonSchema: String {
        """
        {
            "type": "object",
            "properties": {
                "id": {"type": "string"},
                "name": {"type": "string"},
                "orgDescription": {"type": "string", "optional": true},
                "website": {"type": "string", "format": "uri", "optional": true},
                "contactInfo": {
                    "type": "array",
                    "items": {
                        "$ref": "#/definitions/ContactInfo"
                    },
                    "optional": true
                },
                "logoURL": {"type": "string", "format": "uri", "optional": true},
                "location": {"$ref": "#/definitions/Location"},
                "type": {"type": "string", "optional": true}
            },
            "required": ["id", "name"],
            "definitions": {
                "ContactInfo": {
                    "type": "object",
                    "properties": {
                        "name": {"type": "string"},
                        "email": {"type": "string", "format": "email", "optional": true},
                        "phone": {"type": "string", "optional": true},
                        "address": {"type": "string", "optional": true},
                        "website": {"type": "string", "format": "uri", "optional": true},
                        "socialMediaHandles": {
                            "type": "object",
                            "additionalProperties": {"type": "string"},
                            "optional": true
                        }
                    },
                    "required": ["name"]
                },
                "Location": {
                    "type": "object",
                    "properties": {
                        "latitude": {"type": "number"},
                        "longitude": {"type": "number"},
                        "address": {"type": "string"},
                        "city": {"type": "string"},
                        "state": {"type": "string"},
                        "zipCode": {"type": "string"},
                        "country": {"type": "string"}
                    },
                    "required": ["latitude", "longitude", "address", "city", "state", "zipCode", "country"]
                }
            }
        }
        """
    }

    // MARK: - HTMLParsable Implementation
    
    public static func parse(from document: Document) throws -> Self {
        // Try to find the organization name
        let nameOpt = try document.select("[itemprop='name'], .org-name, .organization-name").first()?.text()
            ?? document.select("meta[property='og:site_name']").first()?.attr("content")
            ?? document.select("title").first()?.text()
        
        guard let name = nameOpt else {
            throw ParsingError.invalidHTML
        }
        
        // Try to find description
        let description = try document.select("[itemprop='description'], .org-description").first()?.text()
            ?? document.select("meta[name='description']").first()?.attr("content")
        
        // Try to find website
        let website = try document.select("[itemprop='url'], link[rel='canonical']").first()?.attr("href")
            ?? document.select("meta[property='og:url']").first()?.attr("content")
        
        // Try to find logo URL
        let logoURL = try document.select("[itemprop='logo'], img.org-logo").first()?.attr("src")
            ?? document.select("meta[property='og:image']").first()?.attr("content")
        
        // Try to find organization type
        let type = try document.select("[itemprop='organizationType'], .org-type").first()?.text()
        
        // Try to find location
        var location: Location? = nil
        if let locationElement = try document.select("[itemprop='location'], .org-location").first() {
            let locationDoc = try SwiftSoup.parse(try locationElement.html())
            location = try? Location.parse(from: locationDoc)
        }
        
        // Try to find contact info
        var contactInfo: [ContactInfo] = []
        let contactElements = try document.select("[itemprop='contactPoint'], .contact-info")
        for element in contactElements {
            let name = try element.select("[itemprop='name'], .contact-name").first()?.text() ?? "Main Contact"
            let email = try element.select("[itemprop='email']").first()?.text()
            let phone = try element.select("[itemprop='telephone']").first()?.text()
            let address = try element.select("[itemprop='address']").first()?.text()
            
            contactInfo.append(ContactInfo(
                name: name,
                email: email,
                phone: phone,
                address: address
            ))
        }
        
        return Organization(
            id: UUID().uuidString,
            name: name,
            orgDescription: description,
            contactInfo: contactInfo.isEmpty ? nil : contactInfo,
            website: website,
            logoURL: logoURL,
            location: location,
            type: type
        )
    }
}
