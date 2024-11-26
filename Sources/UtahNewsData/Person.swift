//
//  Person.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

import SwiftUI



public struct Person: AssociatedData {
    public var id: UUID
    public var relationships: [Relationship] = []
    public var name: String
    public var bio: String?
    public var birthDate: Date?
    public var contactInfo: ContactInfo?
    public var mediaItems: [MediaItem] = [] // For profile images, audio interviews, etc.

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

public struct ContactInfo {
    public var email: String?
    public var phone: String?
    public var address: String?
    public var socialMediaHandles: [String: String]? // e.g., ["Twitter": "@username"]
}
