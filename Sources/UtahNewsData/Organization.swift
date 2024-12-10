//
//  Organization.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

import SwiftUI

public struct Organization: AssociatedData {
    public var id: String
    public var relationships: [Relationship] = []
    public var name: String
    public var description: String?
    public var contactInfo: ContactInfo?
    public var mediaItems: [MediaItem] = [] // For logos, promotional videos, etc.

    init(id: String = UUID().uuidString, name: String) {
        self.id = id
        self.name = name
    }
}
