import Foundation

/// This file contains example code demonstrating how to use the RAG utilities.
/// It is not meant to be used in production, but rather as a reference.
public struct RAGExample {
    
    /// Example function showing how to prepare entities for RAG
    public static func prepareEntitiesForRAG() {
        // Create some example entities
        let person = Person(
            name: "Jane Doe",
            details: "A fictional person used for demonstration purposes.",
            biography: "Jane Doe is a software engineer with 10 years of experience in Swift development.",
            occupation: "Software Engineer",
            nationality: "American",
            notableAchievements: ["Developed the UtahNewsData framework", "Published 3 books on Swift"]
        )
        
        let organization = Organization(
            name: "Utah News Network",
            orgDescription: "A fictional news organization covering Utah news.",
            website: "https://www.utahnewsnetwork.example"
        )
        
        // Create relationships between entities
        let personToOrgRelationship = Relationship(
            id: organization.id,
            type: .organization,
            displayName: "Works at",
            context: "Jane Doe has been working at Utah News Network since 2020.",
            confidence: 0.95,
            source: .userInput
        )
        
        let orgToPersonRelationship = Relationship(
            id: person.id,
            type: .person,
            displayName: "Employs",
            context: "Utah News Network employs Jane Doe as a senior reporter.",
            confidence: 0.95,
            source: .userInput
        )
        
        // Add relationships to entities
        var updatedPerson = person
        updatedPerson.relationships.append(personToOrgRelationship)
        
        var updatedOrg = organization
        updatedOrg.relationships.append(orgToPersonRelationship)
        
        // MARK: - Generate RAG Context
        
        // Generate context for a single entity
        let personContext = RAGUtilities.generateEntityContext(updatedPerson)
        print("Person Context:\n\(personContext)\n")
        
        // Generate context for multiple entities
        let combinedContext = RAGUtilities.generateCombinedContext([updatedPerson, updatedOrg])
        print("Combined Context:\n\(combinedContext)\n")
        
        // MARK: - Prepare for Vector Storage
        
        // Generate vector records for entities
        let vectorRecords = RAGUtilities.prepareEntitiesForEmbedding([updatedPerson, updatedOrg])
        print("Generated \(vectorRecords.count) vector records")
        
        // Example of what a vector record looks like
        if let firstRecord = vectorRecords.first {
            print("Example Vector Record:")
            print("ID: \(firstRecord.id)")
            print("Entity Type: \(firstRecord.entityType)")
            print("Text for Embedding: \(firstRecord.text)")
            print("Metadata: \(firstRecord.metadata)")
        }
        
        // MARK: - Generate Knowledge Graph
        
        // Create a knowledge graph from entities
        let graph = RAGUtilities.generateKnowledgeGraph([updatedPerson, updatedOrg])
        print("Knowledge Graph: \(graph.nodes.count) nodes, \(graph.edges.count) edges")
        
        // Export the graph to JSON
        do {
            let graphJSON = try graph.toJSON()
            print("Knowledge Graph JSON (excerpt):")
            if let excerpt = String(graphJSON.prefix(200)) {
                print("\(excerpt)...")
            }
        } catch {
            print("Error generating graph JSON: \(error)")
        }
        
        // MARK: - Export to Relational Database
        
        // Generate SQL for entities
        let personSQL = DataExporter.exportEntityToSQL(updatedPerson, tableName: "persons")
        print("Person SQL: \(personSQL)")
        
        // Generate SQL for relationships
        let relationshipSQL = DataExporter.exportRelationshipsToSQL(updatedPerson)
        print("Relationship SQL (first statement): \(relationshipSQL.first ?? "")")
    }
} 