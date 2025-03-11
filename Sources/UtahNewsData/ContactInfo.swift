//
//  ContactInfo.swift
//  UtahNewsData
//
//  Created by Mark Evans on 2/12/25.
//
//  Summary: Defines the ContactInfo model which represents contact information
//           for entities in the UtahNewsData system. Now conforms to JSONSchemaProvider
//           to provide a static JSON schema for LLM responses.

import Foundation
import SwiftUI

/// Represents contact information for entities in the news data system.
/// This can be used with various entity types, particularly with
/// Organization and Person entities.
public struct ContactInfo: BaseEntity, Codable, Hashable, Equatable, JSONSchemaProvider, Sendable
{  // Added JSONSchemaProvider and Sendable conformance
    /// Unique identifier for the contact information
    public var id: String = UUID().uuidString

    /// Name of the contact (person or department)
    public var name: String = "Contact"

    /// Email address for contact
    public var email: String? = nil

    /// Website URL
    public var website: String? = nil

    /// Phone number for contact
    public var phone: String? = nil

    /// Physical address
    public var address: String? = nil

    /// Dictionary of social media platforms and corresponding handles
    /// Example: ["Twitter": "@username", "LinkedIn": "profile-name"]
    public var socialMediaHandles: [String: String]? = [:]

    /// Creates new contact information with the specified properties.
    /// All properties are optional to allow for flexible contact representation.
    ///
    /// - Parameters:
    ///   - name: Name of the contact (person or department)
    ///   - email: Email address for contact
    ///   - website: Website URL
    ///   - phone: Phone number for contact
    ///   - address: Physical address
    ///   - socialMediaHandles: Dictionary of platform names and handles
    public init(
        name: String? = nil,
        email: String? = nil,
        website: String? = nil,
        phone: String? = nil,
        address: String? = nil,
        socialMediaHandles: [String: String]? = nil
    ) {
        if let name = name {
            self.name = name
        }
        self.email = email
        self.website = website
        self.phone = phone
        self.address = address
        self.socialMediaHandles = socialMediaHandles
    }

    // MARK: - JSON Schema Provider
    /// Provides the JSON schema for ContactInfo.
    public static var jsonSchema: String {
        return """
            {
                "type": "object",
                "properties": {
                    "id": {"type": "string"},
                    "name": {"type": "string"},
                    "email": {"type": ["string", "null"]},
                    "website": {"type": ["string", "null"]},
                    "phone": {"type": ["string", "null"]},
                    "address": {"type": ["string", "null"]},
                    "socialMediaHandles": {
                        "type": ["object", "null"],
                        "additionalProperties": {"type": "string"}
                    }
                },
                "required": ["id", "name"]
            }
            """
    }
}
