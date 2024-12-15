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

    init(id: String = UUID().uuidString, name: String) {
        self.id = id
        self.name = name
    }
}

public struct ContactInfo: Codable, Identifiable, Hashable, Equatable {
    public var id: String = UUID().uuidString
    public var name: String?
    public var email: String?
    public var website: String?
    public var phone: String?
    public var address: String?
    public var socialMediaHandles: [String: String]? // e.g., ["Twitter": "@username"]
}
