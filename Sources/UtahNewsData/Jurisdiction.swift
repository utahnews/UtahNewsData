//
//  File.swift
//  UtahNewsData
//
//  Created by Mark Evans on 12/10/24.
//

import SwiftUI


public enum JurisdictionType: String, Codable, CaseIterable {
    case city
    case county
    case state

    public var label: String {
        switch self {
        case .city: return "City"
        case .county: return "County"
        case .state: return "State"
        }
    }
}


// If a previously location-less Jurisdiction now includes a location (or vice versa),
// decoding might fail if the structure of the Firestore document differs from what
// the Codable synthesis expects. For example, Firestore might omit the "location" field entirely
// if there is no location set, or it could store partial data that doesn't map cleanly.
//
// To fix this, you can make the decoding of `location` more resilient. Since location is optional,
// you can use `decodeIfPresent` so that if location data is missing or malformed, `location` will
// simply be nil rather than causing a decoding error.
//
// Here's how you can update your Jurisdiction object definition to safely handle both cases:
// Jurisdictions with and without Locations will decode properly.
//
// In your Jurisdiction definition, add CodingKeys and a custom initializer to decode
// `location` using `try?` or `decodeIfPresent`:

public struct Jurisdiction: AssociatedData, Identifiable, Codable {
    public var id: String
    public var relationships: [Relationship] = []
    public var type: JurisdictionType
    public var name: String
    public var location: Location?   // This remains optional
    public var website: String?

    // Existing initializer
    public init(id: String = UUID().uuidString, type: JurisdictionType, name: String, location: Location? = nil) {
        self.id = id
        self.type = type
        self.name = name
        self.location = location
    }

    // Add CodingKeys to handle decoding more gracefully
    enum CodingKeys: String, CodingKey {
        case id
        case relationships
        case type
        case name
        case location
        case website
    }

    // Implement a custom init(from:) to safely decode the optional location
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.relationships = (try? container.decode([Relationship].self, forKey: .relationships)) ?? []
        self.type = try container.decode(JurisdictionType.self, forKey: .type)
        self.name = try container.decode(String.self, forKey: .name)
        // Use decodeIfPresent for location so it's nil if field is missing or can't decode
        self.location = try? container.decodeIfPresent(Location.self, forKey: .location)
        self.website = try? container.decodeIfPresent(String.self, forKey: .website)
    }

    // The default synthesized encode(to:) should still work fine.
}
