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

    var label: String {
        switch self {
        case .city: return "City"
        case .county: return "County"
        case .state: return "State"
        }
    }
}


public struct Jurisdiction: AssociatedData, Identifiable, Codable {
    public var id: String
    public var relationships: [Relationship] = []
    public var type: JurisdictionType
    public var name: String
    public var location: Location?
    
    public init(id: String = UUID().uuidString, type: JurisdictionType, name: String, location: Location? = nil) {
        self.id = id
        self.type = type
        self.name = name
        self.location = location
    }
}
