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

/// Represents an organization in the news data system.
/// This can be a company, government agency, non-profit, or any
/// organizational entity relevant to news content.
public struct Organization: AssociatedData, Codable, Identifiable, Hashable, EntityDetailsProvider,
    JSONSchemaProvider
{
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

    /// Creates a new Organization instance with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID string)
    ///   - name: The organization's name
    ///   - orgDescription: Description of the organization
    ///   - contactInfo: Array of contact information entries
    ///   - website: Organization's website URL
    public init(
        id: String = UUID().uuidString,
        name: String,
        orgDescription: String? = nil,
        contactInfo: [ContactInfo]? = nil,
        website: String? = nil
    ) {
        self.id = id
        self.name = name
        self.orgDescription = orgDescription
        self.contactInfo = contactInfo
        self.website = website
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
        self.contactInfo = (try? container.decode([ContactInfo].self, forKey: .contactInfo)) ?? []
        self.website = try? container.decode(String.self, forKey: .website)
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
    }

    /// Keys used for encoding and decoding Organization instances
    private enum CodingKeys: String, CodingKey {
        case id, relationships, name
        case orgDescription
        case oldDescription = "description"
        case contactInfo, website
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
                    "optional": true
                },
                "type": {"type": "string", "optional": true},
                "industry": {"type": "string", "optional": true},
                "foundedYear": {"type": "integer", "optional": true},
                "headquarters": {"type": "string", "optional": true}
            },
            "required": ["id", "name"]
        }
        """
    }
}
