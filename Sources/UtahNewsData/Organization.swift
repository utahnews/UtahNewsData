//
//  Organization.swift
//  UtahNewsData
//
//  Created by Mark Evans on 10/25/24.
//

import SwiftUI

public struct Organization: AssociatedData, Codable, Identifiable, Hashable, EntityDetailsProvider {
    public var id: String
    public var relationships: [Relationship] = []
    public var name: String
    public var orgDescription: String?   // Internal property name
    public var contactInfo: [ContactInfo]? = []
    public var website: String?

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
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Use decodeIfPresent for id and fall back to a new UUID if missing.
        self.id = (try? container.decodeIfPresent(String.self, forKey: .id)) ?? UUID().uuidString
        self.relationships = (try? container.decode([Relationship].self, forKey: .relationships)) ?? []
        self.name = try container.decode(String.self, forKey: .name)
        // First try the new key "orgDescription", then fall back to the legacy key "description"
        let decodedDesc = (try? container.decodeIfPresent(String.self, forKey: .orgDescription))
            ?? (try? container.decodeIfPresent(String.self, forKey: .oldDescription))
        self.orgDescription = (decodedDesc?.isEmpty ?? true) ? nil : decodedDesc
        self.contactInfo = (try? container.decode([ContactInfo].self, forKey: .contactInfo)) ?? []
        self.website = try? container.decode(String.self, forKey: .website)
    }
    
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
    
    private enum CodingKeys: String, CodingKey {
        case id, relationships, name
        case orgDescription
        case oldDescription = "description"
        case contactInfo, website
    }
    
    // MARK: - EntityDetailsProvider Implementation
    
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
                
                if let contactName = contact.name {
                    description += "**Name**: \(contactName)\n"
                }
                
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
}
