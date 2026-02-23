//
//  Organization.swift
//  UtahNewsDataModels
//
//  Created by Mark Evans on 01/29/25
//
//  Summary: Defines the Organization model which represents companies, institutions,
//           government agencies, and other organizational entities in the UtahNewsDataModels system.
//           Lightweight version without HTML parsing capabilities.

import Foundation

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

/// Represents an organization in the UtahNewsDataModels system
public struct Organization: AssociatedData, Codable, Identifiable, Hashable, Equatable, JSONSchemaProvider, Sendable {
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
                "contactInfo": { "$ref": "#/definitions/ContactInfo" }
            },
            "required": ["id", "name"]
        }
        """
    }
}