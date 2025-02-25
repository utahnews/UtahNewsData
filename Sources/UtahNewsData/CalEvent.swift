//
//  CalEvent.swift
//  UtahNewsData
//
//  Created by Mark Evans on 2/12/25.
//

/*
 # CalEvent Model
 
 This file defines the CalEvent model, which represents calendar events
 in the UtahNewsData system. CalEvents can be used to track scheduled events
 such as press conferences, meetings, hearings, and other time-based occurrences
 relevant to news coverage.
 
 ## Key Features:
 
 1. Core event information (title, description, date/time range)
 2. Location data
 3. Organizer and attendee information
 4. Recurrence rules
 5. Related entities
 
 ## Usage:
 
 ```swift
 // Create a basic calendar event
 let basicEvent = CalEvent(
     title: "City Council Meeting",
     startDate: Date(), // March 15, 2023, 19:00
     endDate: Date().addingTimeInterval(7200) // 2 hours later
 )
 
 // Create a detailed calendar event
 let detailedEvent = CalEvent(
     title: "Public Hearing on Downtown Development",
     description: "Public hearing to discuss proposed downtown development project",
     startDate: Date(), // April 10, 2023, 18:30
     endDate: Date().addingTimeInterval(5400), // 1.5 hours later
     location: cityHall, // Location entity
     organizer: planningDepartment, // Organization entity
     attendees: [mayorOffice, developerCorp, communityCouncil], // Organization entities
     isPublic: true,
     url: "https://example.gov/hearings/downtown-dev",
     recurrenceRule: nil, // One-time event
     relatedEntities: [downtownProject] // Other entities
 )
 
 // Access event information
 let eventTitle = detailedEvent.title
 let eventDuration = Calendar.current.dateComponents([.minute], from: detailedEvent.startDate, to: detailedEvent.endDate).minute
 
 // Generate context for RAG
 let context = detailedEvent.generateContext()
 ```
 
 The CalEvent model implements EntityDetailsProvider, allowing it to generate
 rich text descriptions for RAG (Retrieval Augmented Generation) systems.
 */

import Foundation

/// Represents a recurrence rule for repeating calendar events
public struct RecurrenceRule: Codable, Hashable, Equatable {
    /// Frequency of recurrence (daily, weekly, monthly, yearly)
    public var frequency: String
    
    /// Interval between occurrences (e.g., every 2 weeks)
    public var interval: Int
    
    /// When the recurrence ends (specific date or after a number of occurrences)
    public var endDate: Date?
    
    /// Number of occurrences after which the recurrence ends
    public var occurrences: Int?
    
    /// Days of the week when the event occurs (for weekly recurrence)
    public var daysOfWeek: [Int]?
    
    /// Creates a new RecurrenceRule with the specified properties.
    ///
    /// - Parameters:
    ///   - frequency: Frequency of recurrence (daily, weekly, monthly, yearly)
    ///   - interval: Interval between occurrences (e.g., every 2 weeks)
    ///   - endDate: When the recurrence ends (specific date)
    ///   - occurrences: Number of occurrences after which the recurrence ends
    ///   - daysOfWeek: Days of the week when the event occurs (for weekly recurrence)
    public init(
        frequency: String,
        interval: Int = 1,
        endDate: Date? = nil,
        occurrences: Int? = nil,
        daysOfWeek: [Int]? = nil
    ) {
        self.frequency = frequency
        self.interval = interval
        self.endDate = endDate
        self.occurrences = occurrences
        self.daysOfWeek = daysOfWeek
    }
}

/// Represents a calendar event in the UtahNewsData system.
/// CalEvents can be used to track scheduled events such as press conferences,
/// meetings, hearings, and other time-based occurrences relevant to news coverage.
public struct CalEvent: Codable, Identifiable, Hashable, Equatable, EntityDetailsProvider {
    /// Unique identifier for the calendar event
    public var id: String = UUID().uuidString
    
    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []
    
    /// The title of the event
    public var title: String
    
    /// Detailed description of the event
    public var description: String?
    
    /// When the event begins
    public var startDate: Date
    
    /// When the event ends
    public var endDate: Date
    
    /// Where the event takes place
    public var location: Location?
    
    /// Person or organization organizing the event
    public var organizer: EntityDetailsProvider?
    
    /// People or organizations attending the event
    public var attendees: [EntityDetailsProvider]?
    
    /// Whether the event is open to the public
    public var isPublic: Bool?
    
    /// URL with more information about the event
    public var url: String?
    
    /// Rule for recurring events
    public var recurrenceRule: RecurrenceRule?
    
    /// Entities related to this event
    public var relatedEntities: [EntityDetailsProvider]?
    
    /// Creates a new CalEvent with the specified properties.
    ///
    /// - Parameters:
    ///   - title: The title of the event
    ///   - description: Detailed description of the event
    ///   - startDate: When the event begins
    ///   - endDate: When the event ends
    ///   - location: Where the event takes place
    ///   - organizer: Person or organization organizing the event
    ///   - attendees: People or organizations attending the event
    ///   - isPublic: Whether the event is open to the public
    ///   - url: URL with more information about the event
    ///   - recurrenceRule: Rule for recurring events
    ///   - relatedEntities: Entities related to this event
    public init(
        title: String,
        description: String? = nil,
        startDate: Date,
        endDate: Date,
        location: Location? = nil,
        organizer: EntityDetailsProvider? = nil,
        attendees: [EntityDetailsProvider]? = nil,
        isPublic: Bool? = nil,
        url: String? = nil,
        recurrenceRule: RecurrenceRule? = nil,
        relatedEntities: [EntityDetailsProvider]? = nil
    ) {
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.organizer = organizer
        self.attendees = attendees
        self.isPublic = isPublic
        self.url = url
        self.recurrenceRule = recurrenceRule
        self.relatedEntities = relatedEntities
    }
    
    /// Generates a detailed text description of the calendar event for use in RAG systems.
    /// The description includes the title, date/time, location, and other event details.
    ///
    /// - Returns: A formatted string containing the calendar event's details
    public func getDetailedDescription() -> String {
        var description = "CALENDAR EVENT: \(title)"
        
        if let eventDescription = self.description {
            description += "\nDescription: \(eventDescription)"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        description += "\nStart: \(dateFormatter.string(from: startDate))"
        description += "\nEnd: \(dateFormatter.string(from: endDate))"
        
        if let location = location {
            description += "\nLocation: \(location.name)"
            if let address = location.address {
                description += " (\(address))"
            }
        }
        
        if let organizer = organizer {
            if let person = organizer as? Person {
                description += "\nOrganizer: \(person.name)"
            } else if let organization = organizer as? Organization {
                description += "\nOrganizer: \(organization.name)"
            }
        }
        
        if let attendees = attendees, !attendees.isEmpty {
            description += "\nAttendees:"
            for attendee in attendees {
                if let person = attendee as? Person {
                    description += "\n- \(person.name)"
                } else if let organization = attendee as? Organization {
                    description += "\n- \(organization.name)"
                }
            }
        }
        
        if let isPublic = isPublic {
            description += "\nPublic Event: \(isPublic ? "Yes" : "No")"
        }
        
        if let url = url {
            description += "\nMore Information: \(url)"
        }
        
        if let recurrenceRule = recurrenceRule {
            description += "\nRecurrence: Every \(recurrenceRule.interval) \(recurrenceRule.frequency)"
            if let occurrences = recurrenceRule.occurrences {
                description += " for \(occurrences) occurrences"
            } else if let endDate = recurrenceRule.endDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                description += " until \(formatter.string(from: endDate))"
            }
        }
        
        return description
    }
}
