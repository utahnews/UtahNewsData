//
//  Person.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

import SwiftUI



public struct Person: AssociatedData, Codable, Identifiable, Hashable {
    public var id: String
    public var relationships: [Relationship] = []
    public var name: String
    public var bio: String?
    public var birthDate: Date?
    public var contactInfo: ContactInfo?
 // For profile images, audio interviews, etc.

    public init(id: String = UUID().uuidString, name: String) {
        self.id = id
        self.name = name
    }
}

public struct ContactInfo: Codable, Identifiable, Hashable, Equatable {
    public var id: String = UUID().uuidString
    public var name: String? = nil
    public var email: String? = nil
    public var website: String? = nil
    public var phone: String? = nil
    public var address: String? = nil
    public var socialMediaHandles: [String: String]? = [:]  // e.g., ["Twitter": "@username"]
    
    public init( name: String? = nil, email: String? = nil, website: String? = nil, phone: String? = nil, address: String? = nil, socialMediaHandles: [String: String]? = [:]) {
        self.name = name
        self.email = email
        self.website = website
        self.phone = phone
        self.address = address
        self.socialMediaHandles = socialMediaHandles
        
    }
}
