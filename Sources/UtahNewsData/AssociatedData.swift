//
//  AssociatedData.swift
//  UtahNewsData
//
//  Created by Mark Evans on 11/26/24.
//

/*
 # AssociatedData Protocol and Relationship Model
 
 This file defines the core protocol and relationship model for the UtahNewsData package.
 It provides the foundation for all entity models and their relationships.
 
 ## Key Components:
 
 1. AssociatedData Protocol: The base protocol that all entity models implement
 2. Relationship Struct: Defines connections between entities
 3. RelationshipSource Enum: Tracks the origin of relationship information
 4. AssociatedDataType Enum: Defines all supported entity types
 
 ## Usage:
 
 All entity models in the system implement the AssociatedData protocol, which enables:
 - Consistent identification via the `id` property
 - Relationship tracking via the `relationships` array
 - Text generation for vector embeddings via the `toEmbeddingText()` method
 
 Relationships between entities are bidirectional and can include:
 - Human-readable display names
 - Confidence scores
 - Context information
 - Source attribution
 
 ## Example:
 
 ```swift
 // Create a person entity
 let person = Person(name: "Jane Doe", details: "Reporter")
 
 // Create an organization entity
 let org = Organization(name: "Utah News Network")
 
 // Create a relationship from person to organization
 let relationship = Relationship(
     id: org.id,
     type: .organization,
     displayName: "Works at",
     context: "Senior reporter since 2020",
     confidence: 0.95,
     source: .userInput
 )
 
 // Add the relationship to the person
 var updatedPerson = person
 updatedPerson.relationships.append(relationship)
 ```
 */

import SwiftUI
import Foundation

/// The core protocol that all entity models in the system implement.
/// Provides consistent identification, relationship tracking, and text generation capabilities.
public protocol AssociatedData {
    /// Unique identifier for the entity
    var id: String { get }
    
    /// Array of relationships to other entities
    var relationships: [Relationship] { get set }
    
    /// The name or title of the entity, used for display and embedding generation
    var name: String { get }
}

/// Extension to provide default implementations for AssociatedData
public extension AssociatedData {
    /// Generates text suitable for creating vector embeddings for RAG systems.
    /// This text includes the entity's basic information and its relationships.
    /// 
    /// - Returns: A string representation of the entity for embedding
    /// 
    /// - Example:
    ///   ```swift
    ///   let embeddingText = person.toEmbeddingText()
    ///   // Use this text for creating vector embeddings
    ///   ```
    func toEmbeddingText() -> String {
        let entityType = String(describing: type(of: self))
        var text = "This is a \(entityType) with ID \(id) named \(name)."
        
        // Add relationship information
        if !relationships.isEmpty {
            text += " It has the following relationships: "
            for relationship in relationships {
                text += "A relationship of type \(relationship.type.rawValue) with entity ID \(relationship.id)"
                if let displayName = relationship.displayName {
                    text += " (\(displayName))"
                }
                if let context = relationship.context {
                    text += ". \(context)"
                }
                text += ". "
            }
        }
        
        return text
    }
}

/// Represents a relationship between two entities in the system.
/// Relationships are directional but typically created in pairs to represent bidirectional connections.
public struct Relationship: Codable, Hashable {
    /// Unique identifier of the target entity
    public let id: String
    
    /// Type of the target entity
    public let type: AssociatedDataType
    
    /// Optional display name for the relationship (e.g., "Works at", "Located in")
    public var displayName: String?
    
    /// When the relationship was created
    public let createdAt: Date
    
    /// Confidence score for the relationship (0.0 to 1.0)
    /// Higher values indicate greater confidence in the relationship's accuracy
    public let confidence: Float
    
    /// Additional context about the relationship
    /// This can include details about how entities are related
    public let context: String?
    
    /// Source of this relationship information
    /// Tracks where the relationship data originated from
    public let source: RelationshipSource
    
    /// Standard initializer with all fields
    /// 
    /// - Parameters:
    ///   - id: Unique identifier of the target entity
    ///   - type: Type of the target entity
    ///   - displayName: Optional human-readable description of the relationship
    ///   - createdAt: When the relationship was created (defaults to current date)
    ///   - confidence: Confidence score from 0.0 to 1.0 (defaults to 1.0)
    ///   - context: Additional information about the relationship
    ///   - source: Origin of the relationship information (defaults to .system)
    public init(
        id: String,
        type: AssociatedDataType,
        displayName: String? = nil,
        createdAt: Date = Date(),
        confidence: Float = 1.0,
        context: String? = nil,
        source: RelationshipSource = .system
    ) {
        self.id = id
        self.type = type
        self.displayName = displayName
        self.createdAt = createdAt
        self.confidence = confidence
        self.context = context
        self.source = source
    }
    
    /// Simplified initializer for backward compatibility
    /// 
    /// - Parameters:
    ///   - id: Unique identifier of the target entity
    ///   - type: Type of the target entity
    ///   - displayName: Optional human-readable description of the relationship
    public init(id: String, type: AssociatedDataType, displayName: String?) {
        self.id = id
        self.type = type
        self.displayName = displayName
        self.createdAt = Date()
        self.confidence = 1.0
        self.context = nil
        self.source = .system
    }
    
    /// Generates text representation of this relationship for embedding
    /// 
    /// - Parameters:
    ///   - sourceEntityName: Name of the entity that has this relationship
    ///   - sourceEntityType: Type of the entity that has this relationship
    /// - Returns: A string representation of the relationship for embedding
    public func toEmbeddingText(sourceEntityName: String, sourceEntityType: String) -> String {
        var text = "The \(sourceEntityType) '\(sourceEntityName)' has a relationship with entity ID \(id) of type \(type.rawValue)."
        
        if let displayName = displayName {
            text += " The relationship is described as: \(displayName)."
        }
        
        if let context = context {
            text += " \(context)"
        }
        
        text += " This relationship was created on \(createdAt) with a confidence of \(confidence)."
        
        return text
    }
}

/// Source of relationship information
/// Tracks where relationship data originated from
public enum RelationshipSource: String, Codable {
    /// Created by the system automatically
    case system = "system"
    
    /// Entered by a human user
    case userInput = "user_input"
    
    /// Inferred by an AI system
    case aiInference = "ai_inference"
    
    /// Imported from an external data source
    case dataImport = "data_import"
}

/// Defines all entity types supported in the system
/// Used to categorize entities and their relationships
public enum AssociatedDataType: String, Codable {
    case person = "persons"
    case organization = "organizations"
    case location = "locations"
    case category = "categories"
    case source = "sources"
    case mediaItem = "mediaItems"
    case newsEvent = "newsEvents"
    case newsStory = "newsStories"
    case quote = "quotes"
    case fact = "facts"
    case statisticalData = "statisticalData"
    case calendarEvent = "calendarEvents"
    case legalDocument = "legalDocuments"
    case socialMediaPost = "socialMediaPosts"
    case expertAnalysis = "expertAnalyses"
    case poll = "polls"
    case alert = "alerts"
    case jurisdiction = "jurisdictions"
    case userSubmission = "userSubmissions"
    // Add other types as needed
    
    /// Returns the singular name of this entity type
    /// Useful for display and text generation
    public var singularName: String {
        switch self {
        case .person: return "person"
        case .organization: return "organization"
        case .location: return "location"
        case .category: return "category"
        case .source: return "source"
        case .mediaItem: return "media item"
        case .newsEvent: return "news event"
        case .newsStory: return "news story"
        case .quote: return "quote"
        case .fact: return "fact"
        case .statisticalData: return "statistical data"
        case .calendarEvent: return "calendar event"
        case .legalDocument: return "legal document"
        case .socialMediaPost: return "social media post"
        case .expertAnalysis: return "expert analysis"
        case .poll: return "poll"
        case .alert: return "alert"
        case .jurisdiction: return "jurisdiction"
        case .userSubmission: return "user submission"
        }
    }
}

