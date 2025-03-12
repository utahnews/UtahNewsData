//
//  Poll.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

/*
 # Poll Model

 This file defines the Poll model, which represents opinion polls and surveys
 in the UtahNewsData system. Polls capture public opinion on various topics
 and issues, providing valuable data for news reporting and analysis.

 ## Key Features:

 1. Poll content (question, options)
 2. Response tracking
 3. Source attribution
 4. Timing information (dateConducted)
 5. Relationship tracking with other entities

 ## Usage:

 ```swift
 // Create a poll
 let pollster = Source(name: "Utah Opinion Research", url: "https://example.com")

 let poll = Poll(
     question: "Do you support the proposed water conservation bill?",
     options: ["Yes", "No", "Undecided"],
     dateConducted: Date(),
     source: pollster
 )

 // Add responses
 poll.responses = [
     PollResponse(selectedOption: "Yes"),
     PollResponse(selectedOption: "Yes"),
     PollResponse(selectedOption: "No"),
     PollResponse(selectedOption: "Undecided")
 ]

 // Associate with related entities
 let topicRelationship = Relationship(
     id: waterConservationCategory.id,
     type: .category,
     displayName: "Related to"
 )
 poll.relationships.append(topicRelationship)

 let billRelationship = Relationship(
     id: senateBill101.id,
     type: .legalDocument,
     displayName: "About"
 )
 poll.relationships.append(billRelationship)
 ```

 The Poll model implements AssociatedData, allowing it to maintain
 relationships with other entities in the system, such as categories,
 legal documents, and news stories.
 */

import SwiftUI
import Foundation
import SwiftSoup

/// Represents an option in a poll that users can vote for.
public struct PollOption: Codable, Hashable, Equatable, Sendable {
    /// The text of the poll option
    public var text: String
    
    /// The number of votes this option has received
    public var votes: Int
    
    /// Creates a new poll option.
    ///
    /// - Parameters:
    ///   - text: The text of the poll option
    ///   - votes: The number of votes this option has received
    public init(text: String, votes: Int = 0) {
        self.text = text
        self.votes = votes
    }
}

/// Represents a poll or survey in the news system.
/// Polls capture public opinion on various topics and issues,
/// providing valuable data for news reporting and analysis.
public struct Poll: AssociatedData, JSONSchemaProvider, HTMLParsable, Codable, Identifiable, Hashable, Equatable, Sendable {
    /// Unique identifier for the poll
    public var id: String
    
    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []
    
    /// The question being asked in the poll
    public var question: String
    
    /// Possible answer options for the poll
    public var options: [PollOption]
    
    /// Collected responses to the poll
    public var responses: [PollResponse] = []
    
    /// When the poll was conducted
    public var dateConducted: Date
    
    /// Organization or entity that conducted the poll
    public var source: String
    
    /// Statistical margin of error for the poll results
    public var marginOfError: Double?
    
    /// Number of people who participated in the poll
    public var sampleSize: Int?
    
    /// Description of the demographic groups included in the poll
    public var demographics: String?
    
    /// The name property required by the AssociatedData protocol.
    /// Returns the poll question.
    public var name: String {
        return question
    }
    
    /// Creates a new poll with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the poll (defaults to a new UUID string)
    ///   - question: The question being asked in the poll
    ///   - options: Possible answer options for the poll
    ///   - dateConducted: When the poll was conducted
    ///   - source: Organization or entity that conducted the poll
    ///   - marginOfError: Statistical margin of error for the poll results
    ///   - sampleSize: Number of people who participated in the poll
    ///   - demographics: Description of the demographic groups included in the poll
    public init(
        id: String = UUID().uuidString,
        question: String,
        options: [PollOption],
        dateConducted: Date,
        source: String,
        marginOfError: Double? = nil,
        sampleSize: Int? = nil,
        demographics: String? = nil
    ) {
        self.id = id
        self.question = question
        self.options = options
        self.dateConducted = dateConducted
        self.source = source
        self.marginOfError = marginOfError
        self.sampleSize = sampleSize
        self.demographics = demographics
    }
    
    /// Returns the count of responses for each option.
    ///
    /// - Returns: A dictionary mapping option strings to response counts
    public func getResults() -> [String: Int] {
        var results: [String: Int] = [:]

        // Initialize all options with zero responses
        for option in options {
            results[option.text] = 0
        }

        // Count responses for each option
        for response in responses {
            if let count = results[response.selectedOption] {
                results[response.selectedOption] = count + 1
            }
        }

        return results
    }

    /// Provides the JSON schema for Poll.
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "id": {"type": "string"},
                "relationships": {
                    "type": "array",
                    "items": {"type": "object"}
                },
                "question": {"type": "string"},
                "options": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "text": {"type": "string"},
                            "votes": {"type": "integer"}
                        },
                        "required": ["text", "votes"]
                    }
                },
                "responses": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "selectedOption": {"type": "string"},
                            "timestamp": {"type": "string", "format": "date-time", "optional": true},
                            "respondentId": {"type": "string", "optional": true},
                            "metadata": {
                                "type": "object",
                                "additionalProperties": true,
                                "optional": true
                            }
                        },
                        "required": ["selectedOption"]
                    }
                },
                "dateConducted": {"type": "string", "format": "date-time"},
                "source": {"type": "string"},
                "marginOfError": {"type": ["number", "null"]},
                "sampleSize": {"type": ["integer", "null"]},
                "demographics": {"type": ["string", "null"]}
            },
            "required": ["id", "question", "options", "dateConducted", "source"]
        }
        """
    }

    // MARK: - HTMLParsable Implementation
    
    public static func parse(from document: Document) throws -> Self {
        // Try to find the poll question
        let questionOpt = try document.select("[itemprop='question'], .poll-question").first()?.text()
            ?? document.select("meta[property='og:title']").first()?.attr("content")
            ?? document.select("title").first()?.text()
        
        guard let question = questionOpt else {
            throw ParsingError.invalidHTML
        }
        
        // Try to find poll options
        var options: [PollOption] = []
        let optionElements = try document.select("[itemprop='option'], .poll-option")
        for element in optionElements {
            let text = try element.text()
            let votes = Int(try element.attr("data-votes")) ?? 0
            options.append(PollOption(text: text, votes: votes))
        }
        
        // If no options found, try looking for list items
        if options.isEmpty {
            let listItems = try document.select("ul.poll-options li, ol.poll-options li")
            for item in listItems {
                options.append(PollOption(text: try item.text(), votes: 0))
            }
        }
        
        // Try to find source
        let source = try document.select("[itemprop='sourceOrganization'], .poll-source").first()?.text()
            ?? document.select("meta[property='og:site_name']").first()?.attr("content")
            ?? "Unknown Source"
        
        // Try to find date
        let dateStr = try document.select("[itemprop='datePublished']").first()?.attr("datetime")
            ?? document.select("meta[property='article:published_time']").first()?.attr("content")
        
        let dateConducted = dateStr.flatMap { DateFormatter.iso8601Full.date(from: $0) } ?? Date()
        
        // Try to find margin of error
        let marginOfError = try Double(document.select(".margin-of-error").first()?.text().replacingOccurrences(of: "%", with: "") ?? "")
        
        // Try to find sample size
        let sampleSize = try Int(document.select(".sample-size").first()?.text() ?? "")
        
        // Try to find demographics
        let demographics = try document.select(".demographics").first()?.text()
        
        return Poll(
            id: UUID().uuidString,
            question: question,
            options: options,
            dateConducted: dateConducted,
            source: source,
            marginOfError: marginOfError,
            sampleSize: sampleSize,
            demographics: demographics
        )
    }
}

/// Represents a single response to a poll.
/// Each response captures the selected option and optionally
/// the person who responded.
public struct PollResponse: BaseEntity, Codable, Hashable, Sendable {
    /// Unique identifier for the poll response
    public var id: String

    /// The name or description of this poll response
    public var name: String {
        return "Response to poll: \(selectedOption)"
    }

    /// Person who responded to the poll (optional for anonymous polls)
    public var respondent: Person?

    /// The option selected by the respondent
    public var selectedOption: String

    /// Creates a new poll response with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the poll response (defaults to a new UUID string)
    ///   - respondent: Person who responded to the poll (optional for anonymous polls)
    ///   - selectedOption: The option selected by the respondent
    public init(id: String = UUID().uuidString, respondent: Person? = nil, selectedOption: String) {
        self.id = id
        self.respondent = respondent
        self.selectedOption = selectedOption
    }
}
