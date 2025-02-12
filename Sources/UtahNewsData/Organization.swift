//
//  Organization.swift
//  UtahNewsData
//
//  Created by Mark Evans on 10/25/24.
//

import SwiftUI

public struct Organization: AssociatedData, Codable, Identifiable, Hashable {
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
        self.id = try container.decode(String.self, forKey: .id)
        self.relationships = (try? container.decode([Relationship].self, forKey: .relationships)) ?? []
        self.name = try container.decode(String.self, forKey: .name)
        // Wrap decoding with try? to allow fallback
        self.orgDescription = (try? container.decodeIfPresent(String.self, forKey: .orgDescription))
            ?? (try? container.decodeIfPresent(String.self, forKey: .oldDescription))
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
}
