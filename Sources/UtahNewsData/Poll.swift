//
//  Poll.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

import SwiftUI


class Poll: AssociatedData {
    var id: UUID
    var relationships: [Relationship] = []
    var question: String
    var options: [String]
    var responses: [PollResponse] = []
    var dateConducted: Date
    var source: Source

    init(id: UUID = UUID(), question: String, options: [String], dateConducted: Date, source: Source) {
        self.id = id
        self.question = question
        self.options = options
        self.dateConducted = dateConducted
        self.source = source
    }
}

struct PollResponse {
    var respondent: Person?
    var selectedOption: String
}
