import Foundation

/*
 # RAG Utilities

 This file provides utilities for working with Retrieval-Augmented Generation (RAG) systems.
 It includes functionality for generating context documents, creating knowledge graphs,
 and preparing entities for vector embedding.

 ## Key Components:

 1. Context Generation: Create rich text context from entities and their relationships
 2. Knowledge Graph: Build graph representations of entities and their connections
 3. Vector Preparation: Prepare entities for embedding in vector databases

 ## Usage:

 The RAGUtilities class provides static methods that can be used with any entity
 that implements the AssociatedData protocol:

 ```swift
 // Generate context for a single entity
 let personContext = RAGUtilities.generateEntityContext(person)

 // Generate context for multiple entities
 let combinedContext = RAGUtilities.generateCombinedContext([person, organization])

 // Create a knowledge graph
 let graph = RAGUtilities.generateKnowledgeGraph([person, organization])

 // Prepare entities for vector embedding
 let vectorRecords = RAGUtilities.prepareEntitiesForEmbedding([person, organization])
 ```

 These utilities help bridge the gap between structured data models and
 natural language processing systems, enabling more effective retrieval
 and generation of content.
 */

/// Utilities for working with RAG (Retrieval-Augmented Generation) systems
public class RAGUtilities {

    // MARK: - Context Generation

    /// Generates a comprehensive context document for an entity and its relationships.
    /// This is useful for creating rich context for RAG systems, enabling more accurate
    /// and relevant content generation.
    ///
    /// The generated context includes:
    /// - Basic entity information (ID, name)
    /// - Detailed description (if the entity implements EntityDetailsProvider)
    /// - Relationships grouped by type
    ///
    /// - Parameters:
    ///   - entity: The entity to generate context for
    ///   - includeRelationships: Whether to include relationship information (default: true)
    /// - Returns: A formatted string containing the entity context
    ///
    /// - Example:
    ///   ```swift
    ///   let personContext = RAGUtilities.generateEntityContext(person)
    ///   // Use this context in a RAG system prompt
    ///   ```
    public static func generateEntityContext<T: AssociatedData>(
        _ entity: T, includeRelationships: Bool = true
    ) -> String {
        let entityType = String(describing: type(of: entity))
        var context = "# \(entityType): \(entity.name)\n\n"
        context += "ID: \(entity.id)\n\n"

        // Add entity-specific details if available
        if let detailsProvider = entity as? any EntityDetailsProvider {
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

    /// Generates a knowledge graph representation of entities and their relationships.
    /// This creates a structured graph that can be used for visualization, analysis,
    /// or export to graph databases.
    ///
    /// - Parameter entities: Array of entities to include in the graph
    /// - Returns: A KnowledgeGraph containing nodes (entities) and edges (relationships)
    ///
    /// - Example:
    ///   ```swift
    ///   let graph = RAGUtilities.generateKnowledgeGraph([person, organization])
    ///   let jsonGraph = try graph.toJSON()
    ///   ```
    public static func generateKnowledgeGraph<T: AssociatedData>(_ entities: [T]) -> KnowledgeGraph
    {
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
                        "displayName": relationship.displayName ?? "",
                        "createdAt": relationship.createdAt.ISO8601Format(),
                        "context": relationship.context ?? "",
                    ]
                )
                graph.addEdge(edge)
            }
        }

        return graph
    }

    // MARK: - Vector Preparation

    /// Prepares a batch of entities for vector embedding.
    /// This creates vector records that can be used with vector databases
    /// and embedding services.
    ///
    /// For each entity, it generates:
    /// - A vector record for the entity itself
    /// - Vector records for each of the entity's relationships
    ///
    /// - Parameter entities: Array of entities to prepare for embedding
    /// - Returns: Array of VectorRecord objects ready for embedding
    ///
    /// - Example:
    ///   ```swift
    ///   let vectorRecords = RAGUtilities.prepareEntitiesForEmbedding([person, organization])
    ///   // Send these records to an embedding service
    ///   ```
    public static func prepareEntitiesForEmbedding<T: AssociatedData>(_ entities: [T])
        -> [VectorRecord]
    {
        var records: [VectorRecord] = []

        // Create entity records
        for entity in entities {
            records.append(DataExporter.generateVectorRecord(entity))

            // Add relationship records
            records.append(contentsOf: DataExporter.generateRelationshipVectorRecords(entity))
        }

        return records
    }

    /// Generates a combined context document from multiple entities.
    /// This is useful when you need context from several related entities
    /// in a single document, with an optional maximum length limit.
    ///
    /// - Parameters:
    ///   - entities: Array of entities to include in the context
    ///   - maxLength: Maximum length of the combined context (default: 8000)
    /// - Returns: A string containing the combined context
    ///
    /// - Example:
    ///   ```swift
    ///   let combinedContext = RAGUtilities.generateCombinedContext([person, organization])
    ///   // Use this combined context in a RAG system prompt
    ///   ```
    public static func generateCombinedContext<T: AssociatedData>(
        _ entities: [T], maxLength: Int = 8000
    ) -> String {
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

/// Protocol for entities that can provide detailed descriptions for RAG.
/// Implementing this protocol allows an entity to provide rich, structured
/// information about itself for context generation.
public protocol EntityDetailsProvider: BaseEntity, Sendable {
    /// Returns a detailed description of the entity for RAG context.
    /// This should include all relevant information about the entity
    /// in a format suitable for inclusion in RAG prompts.
    func getDetailedDescription() -> String
}

// MARK: - Knowledge Graph Models

/// Represents a knowledge graph for RAG systems.
/// A knowledge graph consists of nodes (entities) and edges (relationships)
/// that can be used for visualization, analysis, or export to graph databases.
public struct KnowledgeGraph: Codable, Sendable {
    /// Nodes in the graph, representing entities
    public var nodes: [KnowledgeNode]

    /// Edges in the graph, representing relationships between entities
    public var edges: [KnowledgeEdge]

    /// Creates an empty knowledge graph
    public init(nodes: [KnowledgeNode] = [], edges: [KnowledgeEdge] = []) {
        self.nodes = nodes
        self.edges = edges
    }

    /// Adds a node to the graph, avoiding duplicates
    /// - Parameter node: The node to add
    public mutating func addNode(_ node: KnowledgeNode) {
        // Avoid duplicates
        if !nodes.contains(where: { $0.id == node.id }) {
            nodes.append(node)
        }
    }

    /// Adds an edge to the graph, avoiding duplicates
    /// - Parameter edge: The edge to add
    public mutating func addEdge(_ edge: KnowledgeEdge) {
        // Avoid duplicates
        if !edges.contains(where: { $0.id == edge.id }) {
            edges.append(edge)
        }
    }

    /// Export the knowledge graph to a JSON string
    /// - Returns: A JSON string representation of the graph
    /// - Throws: An error if encoding fails
    public func toJSON() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

/// Represents a node in a knowledge graph.
/// Each node corresponds to an entity in the system.
public struct KnowledgeNode: Codable, Identifiable, Hashable, Sendable {
    /// Unique identifier for the node
    public let id: String

    /// Type of entity this node represents
    public let type: String

    /// Name or title of the entity
    public let name: String

    /// Additional properties of the entity
    public let properties: [String: String]

    /// Creates a new knowledge graph node
    public init(id: String, type: String, name: String, properties: [String: String] = [:]) {
        self.id = id
        self.type = type
        self.name = name
        self.properties = properties
    }
}

/// Represents an edge in the knowledge graph.
/// Edges correspond to relationships between entities.
public struct KnowledgeEdge: Codable, Identifiable, Hashable, Sendable {
    /// Unique identifier for the edge
    public let id: String

    /// ID of the source node (entity)
    public let sourceId: String

    /// ID of the target node (entity)
    public let targetId: String

    /// Type of the relationship
    public let type: String

    /// Additional properties for the edge
    public let properties: [String: String]

    /// Creates a new knowledge graph edge
    public init(
        id: String = UUID().uuidString, sourceId: String, targetId: String, type: String,
        properties: [String: String] = [:]
    ) {
        self.id = id
        self.sourceId = sourceId
        self.targetId = targetId
        self.type = type
        self.properties = properties
    }
}
