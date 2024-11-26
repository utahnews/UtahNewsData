//
//  Category.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//


import SwiftUI



public struct Category: AssociatedData {
    public var id: UUID
    public var relationships: [Relationship] = []
    public var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
