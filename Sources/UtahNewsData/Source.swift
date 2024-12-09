//
//  Source.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

import SwiftUI


public struct Source: AssociatedData {
    public var id: UUID
    public var relationships: [Relationship] = []
    public var name: String
    public var url: URL?
    public var credibilityRating: Int? // Scale of 1-5
    public var siteMapURL: URL?

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
