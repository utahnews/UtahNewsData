//
//  AssociatedData.swift
//  UtahNewsData
//
//  Created by Mark Evans on 11/26/24.
//


import SwiftUI
import Foundation

public protocol AssociatedData {
    var id: String { get }
    var relationships: [Relationship] { get set }
    
    /// The name or title of the entity, used for display and embedding generation
    var name: String { get }
}

/// Extension to provide default implementations for AssociatedData
public extension AssociatedData {
    /// Generates text suitable for creating vector embeddings for RAG systems
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

public struct Relationship: Codable, Hashable {
    /// Unique identifier of the target entity
    public let id: String
    
    /// Type of the target entity
    public let type: AssociatedDataType
    
    /// Optional display name for the relationship
    public var displayName: String?
    
    /// When the relationship was created
    public let createdAt: Date
    
    /// Confidence score for the relationship (0.0 to 1.0)
    public let confidence: Float
    
    /// Additional context about the relationship
    public let context: String?
    
    /// Source of this relationship information
    public let source: RelationshipSource
    
    /// Standard initializer with all fields
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
public enum RelationshipSource: String, Codable {
    case system = "system"
    case userInput = "user_input"
    case aiInference = "ai_inference"
    case dataImport = "data_import"
}

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
    // Add other types as needed
    
    /// Returns the singular name of this entity type
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
        }
    }
}

