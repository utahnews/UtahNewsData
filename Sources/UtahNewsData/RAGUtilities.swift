import Foundation

/// Utilities for working with RAG (Retrieval-Augmented Generation) systems
public class RAGUtilities {
    
    // MARK: - Context Generation
    
    /// Generates a comprehensive context document for an entity and its relationships
    /// This is useful for creating rich context for RAG systems
    public static func generateEntityContext<T: AssociatedData>(_ entity: T, includeRelationships: Bool = true) -> String {
        let entityType = String(describing: type(of: entity))
        var context = "# \(entityType): \(entity.name)\n\n"
        context += "ID: \(entity.id)\n\n"
        
        // Add entity-specific details if available
        if let detailsProvider = entity as? EntityDetailsProvider {
            context += "## Details\n\n"
            context += detailsProvider.getDetailedDescription()
            context += "\n\n"
        }
        
        // Add relationships if requested
        if includeRelationships && !entity.relationships.isEmpty {
            context += "## Relationships\n\n"
            
            // Group relationships by type
            let groupedRelationships = Dictionary(grouping: entity.relationships) { $0.type }
            
            for (type, relationships) in groupedRelationships {
                context += "### \(type.singularName.capitalized)s\n\n"
                
                for relationship in relationships {
                    context += "- **\(relationship.displayName ?? "Unnamed \(type.singularName)")**"
                    context += " (ID: \(relationship.id))"
                    
                    if let relationContext = relationship.context {
                        context += ": \(relationContext)"
                    }
                    
                    context += "\n"
                }
                
                context += "\n"
            }
        }
        
        return context
    }
    
    /// Generates a knowledge graph representation of an entity and its relationships
    public static func generateKnowledgeGraph<T: AssociatedData>(_ entities: [T]) -> KnowledgeGraph {
        var graph = KnowledgeGraph()
        
        // Add all entities as nodes
        for entity in entities {
            let node = KnowledgeNode(
                id: entity.id,
                type: String(describing: type(of: entity)),
                name: entity.name
            )
            graph.addNode(node)
            
            // Add relationships as edges
            for relationship in entity.relationships {
                let edge = KnowledgeEdge(
                    sourceId: entity.id,
                    targetId: relationship.id,
                    type: relationship.type.rawValue,
                    properties: [
                        "displayName": relationship.displayName as Any,
                        "confidence": relationship.confidence,
                        "createdAt": relationship.createdAt,
                        "context": relationship.context as Any
                    ]
                )
                graph.addEdge(edge)
            }
        }
        
        return graph
    }
    
    // MARK: - Vector Preparation
    
    /// Prepares a batch of entities for vector embedding
    public static func prepareEntitiesForEmbedding<T: AssociatedData>(_ entities: [T]) -> [VectorRecord] {
        var records: [VectorRecord] = []
        
        // Create entity records
        for entity in entities {
            records.append(DataExporter.generateVectorRecord(entity))
            
            // Add relationship records
            records.append(contentsOf: DataExporter.generateRelationshipVectorRecords(entity))
        }
        
        return records
    }
    
    /// Generates a combined context document from multiple entities
    public static func generateCombinedContext<T: AssociatedData>(_ entities: [T], maxLength: Int = 8000) -> String {
        var combinedContext = ""
        
        for entity in entities {
            let entityContext = generateEntityContext(entity)
            
            // Check if adding this entity would exceed the max length
            if combinedContext.count + entityContext.count > maxLength {
                // If we already have some context, stop adding more
                if !combinedContext.isEmpty {
                    break
                }
                
                // If this is the first entity and it's too long, truncate it
                combinedContext = String(entityContext.prefix(maxLength))
                break
            }
            
            // Add a separator between entities
            if !combinedContext.isEmpty {
                combinedContext += "\n\n---\n\n"
            }
            
            combinedContext += entityContext
        }
        
        return combinedContext
    }
}

// MARK: - Helper Protocols

/// Protocol for entities that can provide detailed descriptions for RAG
public protocol EntityDetailsProvider {
    /// Returns a detailed description of the entity for RAG context
    func getDetailedDescription() -> String
}

// MARK: - Knowledge Graph Models

/// Represents a knowledge graph for RAG systems
public struct KnowledgeGraph: Codable {
    public var nodes: [KnowledgeNode]
    public var edges: [KnowledgeEdge]
    
    public init() {
        self.nodes = []
        self.edges = []
    }
    
    public mutating func addNode(_ node: KnowledgeNode) {
        // Avoid duplicates
        if !nodes.contains(where: { $0.id == node.id }) {
            nodes.append(node)
        }
    }
    
    public mutating func addEdge(_ edge: KnowledgeEdge) {
        // Avoid duplicates
        if !edges.contains(where: { $0.id == edge.id }) {
            edges.append(edge)
        }
    }
    
    /// Export the knowledge graph to a JSON string
    public func toJSON() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

/// Represents a node in the knowledge graph
public struct KnowledgeNode: Codable, Identifiable {
    public let id: String
    public let type: String
    public let name: String
    public var properties: [String: String]?
    
    public init(id: String, type: String, name: String, properties: [String: String]? = nil) {
        self.id = id
        self.type = type
        self.name = name
        self.properties = properties
    }
}

/// Represents an edge in the knowledge graph
public struct KnowledgeEdge: Codable, Identifiable {
    public let id: String
    public let sourceId: String
    public let targetId: String
    public let type: String
    public var properties: [String: Any]?
    
    public init(sourceId: String, targetId: String, type: String, properties: [String: Any]? = nil) {
        self.id = UUID().uuidString
        self.sourceId = sourceId
        self.targetId = targetId
        self.type = type
        self.properties = properties
    }
    
    // Custom coding keys to handle the properties dictionary
    private enum CodingKeys: String, CodingKey {
        case id, sourceId, targetId, type, properties
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        sourceId = try container.decode(String.self, forKey: .sourceId)
        targetId = try container.decode(String.self, forKey: .targetId)
        type = try container.decode(String.self, forKey: .type)
        
        // Decode properties as a JSON string and convert to dictionary
        if let propertiesString = try container.decodeIfPresent(String.self, forKey: .properties),
           let data = propertiesString.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            properties = dict
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(sourceId, forKey: .sourceId)
        try container.encode(targetId, forKey: .targetId)
        try container.encode(type, forKey: .type)
        
        // Encode properties as a JSON string
        if let props = properties,
           let data = try? JSONSerialization.data(withJSONObject: props, options: []),
           let jsonString = String(data: data, encoding: .utf8) {
            try container.encode(jsonString, forKey: .properties)
        }
    }
} 