//
//  AssociatedData.swift
//  UtahNewsData
//
//  Created by Mark Evans on 11/26/24.
//

/*
 # Entity Model Foundation
 
 This file defines the core protocols and relationship model for the UtahNewsData package.
 It provides the foundation for all entity models and their relationships.
 
 ## Key Components:
 
 1. BaseEntity Protocol: The foundation protocol for all entities
 2. AssociatedData Protocol: Extends BaseEntity with relationship capabilities
 3. Relationship Struct: Defines connections between entities
 4. RelationshipSource Enum: Tracks the origin of relationship information
 5. EntityType Enum: Defines all supported entity types
 
 ## Usage:
 
 All entity models in the system implement at least the BaseEntity protocol,
 and most implement the AssociatedData protocol for relationship tracking:
 
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
     context: "Senior reporter since 2020"
 )
 
 // Add the relationship to the person
 var updatedPerson = person
 updatedPerson.relationships.append(relationship)
 ```
 */

import SwiftUI
import Foundation

/// The foundation protocol for all entities in the system.
/// Provides consistent identification and naming.
public protocol BaseEntity: Identifiable, Codable, Hashable {
    /// Unique identifier for the entity
    var id: String { get }
    
    /// The name or title of the entity, used for display and embedding generation
    var name: String { get }
}

/// The core protocol that all relational entity models in the system implement.
/// Extends BaseEntity with relationship tracking capabilities.
public protocol AssociatedData: BaseEntity {
    /// Array of relationships to other entities
    var relationships: [Relationship] { get set }
}

/// Extension to provide default implementations for AssociatedData
public extension AssociatedData {
    /// Generates text suitable for creating vector embeddings for RAG systems.
    /// This text includes the entity's basic information and its relationships.
    /// 
    /// - Returns: A string representation of the entity for embedding
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
public struct Relationship: BaseEntity, Codable, Hashable {
    /// Unique identifier for the relationship
    public var id: String = UUID().uuidString
    
    /// The name or description of this relationship
    public var name: String {
        return displayName ?? "Relationship to \(type.rawValue) \(id)"
    }
    
    /// Unique identifier of the target entity
    public let targetId: String
    
    /// Type of the target entity
    public let type: EntityType
    
    /// Optional display name for the relationship (e.g., "Works at", "Located in")
    public var displayName: String?
    
    /// When the relationship was created
    public let createdAt: Date
    
    /// Optional additional context about the relationship
    public var context: String?
    
    /// Creates a new relationship between entities.
    ///
    /// - Parameters:
    ///   - id: Unique identifier of the target entity
    ///   - type: Type of the target entity
    ///   - displayName: Optional display name for the relationship
    ///   - context: Optional additional context about the relationship
    public init(id: String, type: EntityType, displayName: String? = nil, context: String? = nil) {
        self.targetId = id
        self.type = type
        self.displayName = displayName
        self.context = context
        self.createdAt = Date()
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
public enum EntityType: String, Codable {
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

// For backward compatibility
public typealias AssociatedDataType = EntityType

