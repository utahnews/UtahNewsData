//
//  Organization.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

import SwiftUI

public struct Organization: AssociatedData, Codable, Identifiable, Hashable {
    public var id: String
    public var relationships: [Relationship] = []
    public var name: String
    public var description: String?
    public var contactInfo: [ContactInfo]? = []
    public var website: String?

    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String? = nil,
        contactInfo: [ContactInfo]? = nil,
        website: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.contactInfo = contactInfo
        self.website = website
    }
}
