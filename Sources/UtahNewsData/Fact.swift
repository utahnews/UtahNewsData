//
//  Fact.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

import SwiftUI


public struct Fact: AssociatedData {
    public var id: String
    public var relationships: [Relationship] = []
    public var statement: String
//    public var source: Source
    public var dateVerified: Date

    public init(
        id: String = UUID().uuidString,
        statement: String,
//        source: Source,
        dateVerified: Date
    ) {
        self.id = id
        self.statement = statement
//        self.source = source
        self.dateVerified = dateVerified
    }
}


public enum Verification: String, CaseIterable {
    case none = "None"
    case human = "Human"
    case ai = "AI"
}
