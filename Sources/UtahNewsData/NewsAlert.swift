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
public struct NewsAlert: AssociatedData, JSONSchemaProvider, HTMLParsable, Sendable {
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
    
    // MARK: - JSON Schema Provider
    /// Provides the JSON schema for NewsAlert.
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
                "title": {"type": "string"},
                "message": {"type": "string"},
                "dateIssued": {"type": "string", "format": "date-time"},
                "level": {"type": "string"},
                "source": {"type": ["string", "null"]},
                "expirationDate": {"type": ["string", "null"], "format": "date-time"}
            },
            "required": ["id", "title", "message", "dateIssued", "level"]
        }
        """
    }
    
    // MARK: - HTMLParsable Implementation
    
    public static func parse(from document: Document) throws -> Self {
        // Try to find the alert title
        let titleOpt = try document.select("[itemprop='headline'], .alert-title, .breaking-news").first()?.text()
            ?? document.select("meta[property='og:title']").first()?.attr("content")
            ?? document.select("title").first()?.text()
        
        guard let title = titleOpt else {
            throw ParsingError.invalidHTML
        }
        
        // Try to find content
        let content = try document.select("[itemprop='articleBody'], .alert-content").first()?.text()
            ?? document.select("meta[name='description']").first()?.attr("content")
            ?? title
        
        // Try to find alert type
        let alertType = try document.select("[itemprop='alertType'], .alert-type").first()?.text()
            ?? "Breaking News"  // Default type
        
        // Try to find severity
        let severityStr = try document.select("[itemprop='severity'], .alert-severity").first()?.text()
        let severity: AlertSeverity
        switch severityStr?.lowercased() {
        case let str where str?.contains("high") ?? false:
            severity = .high
        case let str where str?.contains("medium") ?? false:
            severity = .medium
        default:
            severity = .low
        }
        
        // Try to find publication date
        let dateStr = try document.select("[itemprop='datePublished']").first()?.text()
            ?? document.select("[itemprop='datePublished']").first()?.attr("datetime")
            ?? document.select("[itemprop='datePublished']").first()?.attr("content")
            ?? document.select("meta[property='article:published_time']").first()?.attr("content")
        
        let publishedAt = dateStr.flatMap { DateFormatter.iso8601Full.date(from: $0) } ?? Date()
        
        // Try to find source
        let source = try document.select("[itemprop='publisher'], .alert-source").first()?.text()
            ?? document.select("meta[property='og:site_name']").first()?.attr("content")
            ?? "Unknown Source"
        
        return NewsAlert(
            id: UUID().uuidString,
            title: title,
            content: content,
            alertType: alertType,
            severity: severity,
            publishedAt: publishedAt,
            source: source
        )
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
