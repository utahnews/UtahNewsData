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
public struct RecurrenceRule: BaseEntity, Codable, Hashable, Equatable {
    /// Unique identifier for the recurrence rule
    public var id: String
    
    /// The name or description of this recurrence rule
    public var name: String
    
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
    ///   - id: Unique identifier for the recurrence rule (defaults to a new UUID string)
    ///   - name: The name or description of this recurrence rule
    ///   - frequency: Frequency of recurrence (daily, weekly, monthly, yearly)
    ///   - interval: Interval between occurrences (e.g., every 2 weeks)
    ///   - endDate: When the recurrence ends (specific date)
    ///   - occurrences: Number of occurrences after which the recurrence ends
    ///   - daysOfWeek: Days of the week when the event occurs (for weekly recurrence)
    public init(
        id: String = UUID().uuidString,
        name: String? = nil,
        frequency: String,
        interval: Int = 1,
        endDate: Date? = nil,
        occurrences: Int? = nil,
        daysOfWeek: [Int]? = nil
    ) {
        self.id = id
        self.name = name ?? "\(frequency) (every \(interval))"
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
public struct CalEvent: AssociatedData, EntityDetailsProvider, BaseEntity {
    /// Unique identifier for the calendar event
    public var id: String = UUID().uuidString
    
    /// The name of the entity (required by BaseEntity)
    public var name: String { title }
    
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
    public var organizer: (any EntityDetailsProvider)?
    
    /// People or organizations attending the event
    public var attendees: [any EntityDetailsProvider]?
    
    /// Whether the event is open to the public
    public var isPublic: Bool?
    
    /// URL with more information about the event
    public var url: String?
    
    /// Rule for recurring events
    public var recurrenceRule: RecurrenceRule?
    
    /// Entities related to this event
    public var relatedEntities: [any EntityDetailsProvider]?
    
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
        organizer: (any EntityDetailsProvider)? = nil,
        attendees: [any EntityDetailsProvider]? = nil,
        isPublic: Bool? = nil,
        url: String? = nil,
        recurrenceRule: RecurrenceRule? = nil,
        relatedEntities: [any EntityDetailsProvider]? = nil
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
    
    // Implement Equatable manually since we have properties that don't conform to Equatable
    public static func == (lhs: CalEvent, rhs: CalEvent) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.startDate == rhs.startDate &&
               lhs.endDate == rhs.endDate
    }
    
    // Implement Hashable manually
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(startDate)
        hasher.combine(endDate)
    }
    
    // Implement Codable manually
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        location = try container.decodeIfPresent(Location.self, forKey: .location)
        isPublic = try container.decodeIfPresent(Bool.self, forKey: .isPublic)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        recurrenceRule = try container.decodeIfPresent(RecurrenceRule.self, forKey: .recurrenceRule)
        relationships = try container.decodeIfPresent([Relationship].self, forKey: .relationships) ?? []
        
        // Skip decoding organizer, attendees, and relatedEntities as they use protocol types
        organizer = nil
        attendees = nil
        relatedEntities = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(isPublic, forKey: .isPublic)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(recurrenceRule, forKey: .recurrenceRule)
        try container.encode(relationships, forKey: .relationships)
        
        // Skip encoding organizer, attendees, and relatedEntities as they use protocol types
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, title, description, startDate, endDate, location, isPublic, url, recurrenceRule, relationships
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
