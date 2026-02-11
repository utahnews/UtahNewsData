import Foundation
import os

/*
 # RAG Example
 
 This file provides practical examples of how to use the RAG (Retrieval-Augmented Generation)
 utilities in the UtahNewsData package. It demonstrates the complete workflow from creating
 entities and relationships to generating context, preparing vector records, creating
 knowledge graphs, and exporting to SQL.
 
 ## Key Demonstrations:
 
 1. Entity Creation: Creating Person and Organization entities
 2. Relationship Establishment: Creating bidirectional relationships between entities
 3. Context Generation: Generating rich text context for RAG systems
 4. Vector Preparation: Preparing entities for vector embedding
 5. Knowledge Graph Creation: Building a graph representation of entities and relationships
 6. SQL Export: Generating SQL statements for relational database storage
 
 ## Usage:
 
 You can call the `prepareEntitiesForRAG()` function to see the complete workflow in action:
 
 ```swift
 RAGExample.prepareEntitiesForRAG()
 ```
 
 This example is designed to be educational and demonstrate best practices for
 working with the UtahNewsData models and RAG utilities.
 */

/// This file contains example code demonstrating how to use the RAG utilities.
/// It is not meant to be used in production, but rather as a reference.
public struct RAGExample {
    private static let logger = Logger(subsystem: "com.utahnews.data", category: "RAGExample")
    
    /// Example function showing how to prepare entities for RAG.
    /// This function demonstrates the complete workflow for working with
    /// entities, relationships, and RAG utilities.
    ///
    /// The workflow includes:
    /// 1. Creating example entities (Person and Organization)
    /// 2. Establishing bidirectional relationships between them
    /// 3. Generating context for individual entities and combined entities
    /// 4. Preparing vector records for embedding
    /// 5. Creating a knowledge graph
    /// 6. Exporting entities and relationships to SQL
    ///
    /// - Note: This is for demonstration purposes only and prints results to the console.
    public static func prepareEntitiesForRAG() {
        // MARK: - Create Example Entities
        
        // Create a Person entity with detailed information
        let person = Person(
            name: "Jane Doe",
            details: "A fictional person used for demonstration purposes.",
            biography: "Jane Doe is a software engineer with 10 years of experience in Swift development.",
            occupation: "Software Engineer",
            nationality: "American",
            notableAchievements: ["Developed the UtahNewsData framework", "Published 3 books on Swift"]
        )
        
        // Create an Organization entity
        let organization = Organization(
            name: "Utah News Network",
            orgDescription: "A fictional news organization covering Utah news.",
            website: "https://www.utahnewsnetwork.example"
        )
        
        // MARK: - Create Relationships
        
        // Create a relationship from Person to Organization
        // Note the use of context and display name
        let personToOrgRelationship = Relationship(
            id: organization.id,
            type: .organization,
            displayName: "Works at",
            context: "Jane Doe has been working at Utah News Network since 2020."
        )
        
        // Create a relationship from Organization to Person
        // This establishes a bidirectional relationship
        let orgToPersonRelationship = Relationship(
            id: person.id,
            type: .person,
            displayName: "Employs",
            context: "Utah News Network employs Jane Doe as a senior reporter."
        )
        
        // Add relationships to entities
        // Note: We create new instances because the entities are immutable
        var updatedPerson = person
        updatedPerson.relationships.append(personToOrgRelationship)
        
        var updatedOrg = organization
        updatedOrg.relationships.append(orgToPersonRelationship)
        
        // MARK: - Generate RAG Context
        
        // Generate context for multiple entities
        // This combines context from multiple entities into a single document
        let personContext = RAGUtilities.generateCombinedContext([updatedPerson])
        let orgContext = RAGUtilities.generateCombinedContext([updatedOrg])
        let combinedContext = personContext + "\n\n" + orgContext
        logger.info("Combined Context:\n\(combinedContext)")
        
        // Generate vector records for entities
        // These records can be sent to an embedding service and stored in a vector database
        let personVectorRecords = RAGUtilities.prepareEntitiesForEmbedding([updatedPerson])
        let orgVectorRecords = RAGUtilities.prepareEntitiesForEmbedding([updatedOrg])
        let vectorRecords = personVectorRecords + orgVectorRecords
        logger.info("Generated \(vectorRecords.count) vector records")
        
        // Create a knowledge graph from entities
        // This builds a graph representation with nodes (entities) and edges (relationships)
        let personGraph = RAGUtilities.generateKnowledgeGraph([updatedPerson])
        let orgGraph = RAGUtilities.generateKnowledgeGraph([updatedOrg])
        // Combine the graphs
        var graph = KnowledgeGraph()
        graph.nodes = personGraph.nodes + orgGraph.nodes
        graph.edges = personGraph.edges + orgGraph.edges
        
        logger.info("Knowledge Graph: \(graph.nodes.count) nodes, \(graph.edges.count) edges")
        
        // Export the graph to JSON
        // This can be used for visualization or import into a graph database
        do {
            let graphJSON = try graph.toJSON()
            let excerpt = String(graphJSON.prefix(200))
            logger.info("Knowledge Graph JSON (excerpt):\n\(excerpt)...")
        } catch {
            logger.error("Failed to generate graph JSON: \(error.localizedDescription)")
        }
        
        // MARK: - Export to Relational Database
        
        // Generate SQL for entities
        // This creates SQL insert statements for storing entities in a relational database
        let personSQL = DataExporter.exportEntityToSQL(updatedPerson, tableName: "persons")
        logger.info("Person SQL: \(personSQL)")
        
        // Generate SQL for relationships
        // This creates SQL insert statements for storing relationships in a relational database
        let relationshipSQL = DataExporter.exportRelationshipsToSQL(updatedPerson)
        logger.info("Relationship SQL (first statement): \(relationshipSQL.first ?? "")")
    }
} 