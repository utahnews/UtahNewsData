//
//  Poll.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

import SwiftUI


public struct Poll: AssociatedData {
    public var id: UUID
    public var relationships: [Relationship] = []
    public var question: String
    public var options: [String]
    public var responses: [PollResponse] = []
    public var dateConducted: Date
    public var source: Source

    init(id: UUID = UUID(), question: String, options: [String], dateConducted: Date, source: Source) {
        self.id = id
        self.question = question
        self.options = options
        self.dateConducted = dateConducted
        self.source = source
    }
}

public struct PollResponse {
    public var respondent: Person?
    public var selectedOption: String
}
