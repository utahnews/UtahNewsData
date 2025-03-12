//
//  NewsAlert.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//
//  Summary: Defines the NewsAlert model which represents time-sensitive alerts and notifications
//           in the UtahNewsData system. Now conforms to JSONSchemaProvider to provide a static JSON schema for LLM responses.

import SwiftUI
import Foundation
import SwiftSoup

/// Represents a time-sensitive alert or notification in the news system.
/// News alerts can include breaking news, emergency notifications, weather
/// alerts, and other time-critical information.
public struct NewsAlert: AssociatedData, JSONSchemaProvider, Sendable {
    /// Unique identifier for the alert
    public var id: String
    
    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []
    
    /// Title or headline of the alert
    public var title: String
    
    /// Detailed message or content of the alert
    public var content: String
    
    /// Type of alert (e.g., "Breaking News", "Weather Alert", etc.)
    public var alertType: String
    
    /// Severity level of the alert
    public var severity: AlertSeverity
    
    /// When the alert was published
    public var publishedAt: Date
    
    /// Source or issuer of the alert
    public var source: String?
    
    /// When the alert expires or is no longer relevant
    public var expirationDate: Date?
    
    /// The name property required by the AssociatedData protocol.
    /// Returns the title of the alert.
    public var name: String {
        return title
    }
    
    /// Creates a new news alert with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the alert (defaults to a new UUID string)
    ///   - title: Title or headline of the alert
    ///   - content: Detailed content of the alert
    ///   - alertType: Type of the alert
    ///   - severity: Severity level of the alert
    ///   - publishedAt: When the alert was published
    ///   - source: Source or issuer of the alert
    public init(
        id: String = UUID().uuidString,
        title: String,
        content: String,
        alertType: String,
        severity: AlertSeverity,
        publishedAt: Date,
        source: String? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.alertType = alertType
        self.severity = severity
        self.publishedAt = publishedAt
        self.source = source
    }
    
    // MARK: - JSONSchemaProvider Implementation
    
    public static var jsonSchema: String {
        """
        {
            "type": "object",
            "properties": {
                "id": { "type": "string", "format": "uuid" },
                "title": { "type": "string" },
                "content": { "type": "string" },
                "urgencyLevel": { "type": "string", "enum": ["low", "medium", "high", "critical"] },
                "category": { "type": "string" },
                "location": { "$ref": "#/definitions/Location" },
                "timestamp": { "type": "string", "format": "date-time" },
                "source": { "type": "string" }
            },
            "required": ["id", "title", "content"]
        }
        """
    }
}

/// Represents the severity level of a news alert.
/// Used to categorize alerts by their urgency and significance.
public enum AlertSeverity: String, Codable, CaseIterable, Sendable {
    /// Low priority or informational alert
    case low
    
    /// Medium priority alert with moderate importance
    case medium
    
    /// High priority alert requiring immediate attention
    case high
    
    /// Returns a human-readable description of the alert severity
    public var description: String {
        switch self {
        case .low:
            return "Low Priority"
        case .medium:
            return "Medium Priority"
        case .high:
            return "High Priority"
        }
    }
    
    /// Returns a color associated with this alert severity for UI display
    public var color: String {
        switch self {
        case .low:
            return "blue"
        case .medium:
            return "yellow"
        case .high:
            return "orange"
        }
    }
}

/// Represents the urgency level of a news alert
public enum UrgencyLevel: String, Codable, CaseIterable, Sendable {
    /// Immediate attention required
    case immediate
    /// High priority but not immediate
    case high
    /// Medium priority
    case medium
    /// Low priority
    case low
    
    /// Returns a human-readable description of the urgency level
    public var description: String {
        switch self {
        case .immediate:
            return "Immediate"
        case .high:
            return "High"
        case .medium:
            return "Medium"
        case .low:
            return "Low"
        }
    }
    
    /// Returns a color associated with this urgency level for UI display
    public var color: String {
        switch self {
        case .immediate:
            return "red"
        case .high:
            return "orange"
        case .medium:
            return "yellow"
        case .low:
            return "blue"
        }
    }
}
