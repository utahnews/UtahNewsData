//
//  NewsAlert.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

/*
 # NewsAlert Model
 
 This file defines the NewsAlert model, which represents time-sensitive alerts and
 notifications in the UtahNewsData system. News alerts can include breaking news,
 emergency notifications, weather alerts, and other time-critical information.
 
 ## Key Features:
 
 1. Alert content (title, message)
 2. Severity classification (level)
 3. Timing information (dateIssued)
 4. Relationship tracking with other entities
 
 ## Usage:
 
 ```swift
 // Create a high-priority news alert
 let alert = NewsAlert(
     title: "Flash Flood Warning",
     message: "The National Weather Service has issued a flash flood warning for Salt Lake County until 8:00 PM.",
     dateIssued: Date(),
     level: .high
 )
 
 // Associate with related entities
 let locationRelationship = Relationship(
     id: saltLakeCounty.id,
     type: .jurisdiction,
     displayName: "Affects"
 )
 alert.relationships.append(locationRelationship)
 
 // Publish the alert
 alertService.publishAlert(alert)
 ```
 
 The NewsAlert model implements AssociatedData, allowing it to maintain
 relationships with other entities in the system, such as locations, events,
 or categories.
 */

import SwiftUI

/// Represents a time-sensitive alert or notification in the news system.
/// News alerts can include breaking news, emergency notifications, weather
/// alerts, and other time-critical information.
public struct NewsAlert: AssociatedData {
    /// Unique identifier for the alert
    public var id: String
    
    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []
    
    /// Title or headline of the alert
    public var title: String
    
    /// Detailed message or content of the alert
    public var message: String
    
    /// When the alert was issued
    public var dateIssued: Date
    
    /// Severity or importance level of the alert
    public var level: AlertLevel
    
    /// The name property required by the AssociatedData protocol.
    /// Returns the title of the alert.
    public var name: String {
        return title
    }
    
    /// Source or issuer of the alert
    public var source: String?
    
    /// When the alert expires or is no longer relevant
    public var expirationDate: Date?
    
    /// Creates a new news alert with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the alert (defaults to a new UUID string)
    ///   - title: Title or headline of the alert
    ///   - message: Detailed message or content of the alert
    ///   - dateIssued: When the alert was issued
    ///   - level: Severity or importance level of the alert
    ///   - source: Source or issuer of the alert
    ///   - expirationDate: When the alert expires or is no longer relevant
    public init(
        id: String = UUID().uuidString,
        title: String,
        message: String,
        dateIssued: Date,
        level: AlertLevel,
        source: String? = nil,
        expirationDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.dateIssued = dateIssued
        self.level = level
        self.source = source
        self.expirationDate = expirationDate
    }
}

/// Represents the severity or importance level of a news alert.
/// Used to categorize alerts by their urgency and significance.
public enum AlertLevel: String, Codable, CaseIterable {
    /// Low priority or informational alert
    case low
    
    /// Medium priority alert with moderate importance
    case medium
    
    /// High priority alert requiring attention
    case high
    
    /// Critical alert requiring immediate attention
    case critical
    
    /// Returns a human-readable description of the alert level
    public var description: String {
        switch self {
        case .low:
            return "Low Priority"
        case .medium:
            return "Medium Priority"
        case .high:
            return "High Priority"
        case .critical:
            return "Critical Priority"
        }
    }
    
    /// Returns a color associated with this alert level for UI display
    public var color: String {
        switch self {
        case .low:
            return "blue"
        case .medium:
            return "yellow"
        case .high:
            return "orange"
        case .critical:
            return "red"
        }
    }
}
