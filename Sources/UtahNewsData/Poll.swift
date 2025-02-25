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

/// Represents an opinion poll or survey in the news system.
/// Polls capture public opinion on various topics and issues,
/// providing valuable data for news reporting and analysis.
public struct Poll: AssociatedData {
    /// Unique identifier for the poll
    public var id: String
    
    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []
    
    /// Question being asked in the poll
    public var question: String
    
    /// Possible answer options for the poll
    public var options: [String]
    
    /// Collected responses to the poll
    public var responses: [PollResponse] = []
    
    /// When the poll was conducted
    public var dateConducted: Date
    
    /// Organization or entity that conducted the poll
    public var source: Source
    
    /// The name property required by the AssociatedData protocol.
    /// Returns the question of the poll.
    public var name: String {
        return question
    }
    
    /// Margin of error for the poll results (as a percentage)
    public var marginOfError: Double?
    
    /// Size of the sample population
    public var sampleSize: Int?
    
    /// Demographic information about the poll respondents
    public var demographics: String?
    
    /// Creates a new poll with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the poll (defaults to a new UUID string)
    ///   - question: Question being asked in the poll
    ///   - options: Possible answer options for the poll
    ///   - dateConducted: When the poll was conducted
    ///   - source: Organization or entity that conducted the poll
    ///   - marginOfError: Margin of error for the poll results (as a percentage)
    ///   - sampleSize: Size of the sample population
    ///   - demographics: Demographic information about the poll respondents
    public init(
        id: String = UUID().uuidString,
        question: String,
        options: [String],
        dateConducted: Date,
        source: Source,
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
            results[option] = 0
        }
        
        // Count responses for each option
        for response in responses {
            if let count = results[response.selectedOption] {
                results[response.selectedOption] = count + 1
            }
        }
        
        return results
    }
}

/// Represents a single response to a poll.
/// Each response captures the selected option and optionally
/// the person who responded.
public struct PollResponse: BaseEntity, Codable, Hashable {
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
    ///   - respondent: Person who responded to the poll (optional for anonymous polls)
    ///   - selectedOption: The option selected by the respondent
    public init(respondent: Person? = nil, selectedOption: String) {
        self.respondent = respondent
        self.selectedOption = selectedOption
    }
}
