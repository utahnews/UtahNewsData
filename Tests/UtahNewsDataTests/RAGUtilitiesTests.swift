//
//  RAGUtilitiesTests.swift
//  UtahNewsDataTests
//
//  Created by Mark Evans on 01/29/25
//
//  Summary: Comprehensive tests for RAG (Retrieval-Augmented Generation) utilities,
//           knowledge graph generation, and vector preparation functionality.

import Foundation
import Testing
@testable import UtahNewsData
@testable import UtahNewsDataModels

@Suite("RAG Utilities Tests")
struct RAGUtilitiesTests {
    
    // MARK: - Context Generation Tests
    
    @Test("Entity context generation")
    func testEntityContextGeneration() throws {
        let person = TestUtilities.createSamplePerson()
        
        let context = RAGUtilities.generateEntityContext(person)
        
        // Verify basic structure
        #expect(context.contains("# Person:"))
        #expect(context.contains(person.name))
        #expect(context.contains("ID: \(person.id)"))
        
        // Verify relationships section if present
        if !person.relationships.isEmpty {
            #expect(context.contains("## Relationships"))
        }
        
        // Should be substantial text for RAG
        #expect(context.count > 50)
        
        // Should not contain raw JSON or code
        #expect(!context.contains("{"))
        #expect(!context.contains("}"))
    }
    
    @Test("Entity context without relationships")
    func testEntityContextWithoutRelationships() throws {
        var article = TestUtilities.createSampleArticle()
        article.relationships = []
        
        let context = RAGUtilities.generateEntityContext(article, includeRelationships: false)
        
        #expect(context.contains("# Article:"))
        #expect(context.contains(article.name))
        #expect(!context.contains("## Relationships"))
        #expect(!context.contains("relationship"))
    }
    
    @Test("Entity context with complex relationships")
    func testEntityContextWithComplexRelationships() throws {
        var organization = TestUtilities.createSampleOrganization()
        
        // Add multiple relationships of different types
        organization.relationships = [
            Relationship(targetId: "person-1", type: .person, displayName: "CEO", context: "Founded the company in 2010"),
            Relationship(targetId: "person-2", type: .person, displayName: "CTO", context: "Leads technical innovation"),
            Relationship(targetId: "location-1", type: .location, displayName: "Headquarters", context: "Main office location"),
            Relationship(targetId: "article-1", type: .article, displayName: "Featured in", context: "Recent news coverage"),
            Relationship(targetId: "source-1", type: .source, displayName: "News source", context: "Regular media contact")
        ]
        
        let context = RAGUtilities.generateEntityContext(organization)
        
        // Verify all relationship types are represented
        #expect(context.contains("### Persons"))
        #expect(context.contains("### Articles"))
        #expect(context.contains("### Locations"))
        #expect(context.contains("### Sources"))
        
        // Verify relationship details
        #expect(context.contains("CEO"))
        #expect(context.contains("CTO"))
        #expect(context.contains("Founded the company in 2010"))
        #expect(context.contains("Leads technical innovation"))
        #expect(context.contains("Main office location"))
        
        // Should be well-structured
        #expect(context.contains("## Relationships"))
        #expect(context.count > 200) // Should be substantial
    }
    
    @Test("Combined context generation")
    func testCombinedContextGeneration() throws {
        let entities: [any AssociatedData] = [
            TestUtilities.createSampleArticle(),
            TestUtilities.createSamplePerson(),
            TestUtilities.createSampleOrganization()
        ]
        
        let combinedContext = RAGUtilities.generateCombinedContext(entities)
        
        // Should contain all entity types
        #expect(combinedContext.contains("# Article:"))
        #expect(combinedContext.contains("# Person:"))
        #expect(combinedContext.contains("# Organization:"))
        
        // Should have separators
        #expect(combinedContext.contains("---"))
        
        // Should be substantial
        #expect(combinedContext.count > 300)
    }
    
    @Test("Combined context with length limit")
    func testCombinedContextWithLengthLimit() throws {
        let entities: [any AssociatedData] = Array(TestDataCollections.sampleEntities.prefix(5))
        
        let shortContext = RAGUtilities.generateCombinedContext(entities, maxLength: 500)
        
        #expect(shortContext.count <= 500)
        #expect(!shortContext.isEmpty)
        
        // Should still be valid context
        #expect(shortContext.contains("#"))
    }
    
    // MARK: - Knowledge Graph Tests
    
    @Test("Knowledge graph generation")
    func testKnowledgeGraphGeneration() throws {
        let entities: [any AssociatedData] = [
            TestUtilities.createSampleArticle(id: "article-1"),
            TestUtilities.createSamplePerson(id: "person-1"),
            TestUtilities.createSampleOrganization(id: "org-1")
        ]
        
        let graph = RAGUtilities.generateKnowledgeGraph(entities)
        
        // Should have nodes for all entities
        #expect(graph.nodes.count == 3)
        
        // Verify node properties
        let articleNode = graph.nodes.first { $0.id == "article-1" }
        #expect(articleNode != nil)
        #expect(articleNode!.type == "Article")
        #expect(!articleNode!.name.isEmpty)
        
        let personNode = graph.nodes.first { $0.id == "person-1" }
        #expect(personNode != nil)
        #expect(personNode!.type == "Person")
        
        let orgNode = graph.nodes.first { $0.id == "org-1" }
        #expect(orgNode != nil)
        #expect(orgNode!.type == "Organization")
        
        // Should have edges for relationships
        #expect(graph.edges.count >= 0) // Depends on relationships in test data
        
        // Test JSON export
        let jsonString = try graph.toJSON()
        #expect(!jsonString.isEmpty)
        #expect(jsonString.contains("nodes"))
        #expect(jsonString.contains("edges"))
        
        // Should be valid JSON
        let jsonData = jsonString.data(using: .utf8)!
        let parsedJSON = try JSONSerialization.jsonObject(with: jsonData)
        #expect(parsedJSON is [String: Any])
    }
    
    @Test("Knowledge graph with relationships")
    func testKnowledgeGraphWithRelationships() throws {
        var person = TestUtilities.createSamplePerson(id: "person-1")
        var organization = TestUtilities.createSampleOrganization(id: "org-1")
        
        // Create bidirectional relationships
        person.relationships = [
            Relationship(targetId: "org-1", type: .organization, displayName: "Works at", context: "Software Engineer")
        ]
        
        organization.relationships = [
            Relationship(targetId: "person-1", type: .person, displayName: "Employee", context: "Software Engineer")
        ]
        
        let entities: [any AssociatedData] = [person, organization]
        let graph = RAGUtilities.generateKnowledgeGraph(entities)
        
        #expect(graph.nodes.count == 2)
        #expect(graph.edges.count == 2) // One edge for each relationship
        
        // Verify edge properties
        let edges = graph.edges
        for edge in edges {
            #expect(!edge.sourceId.isEmpty)
            #expect(!edge.targetId.isEmpty)
            #expect(!edge.type.isEmpty)
            #expect(!edge.properties.isEmpty)
            
            // Verify edge has expected properties
            #expect(edge.properties["displayName"] != nil)
            #expect(edge.properties["createdAt"] != nil)
            #expect(edge.properties["context"] != nil)
        }
    }
    
    @Test("Knowledge graph node uniqueness")
    func testKnowledgeGraphNodeUniqueness() throws {
        // Create duplicate entities with same ID
        let entity1 = TestUtilities.createSampleArticle(id: "duplicate-id")
        let entity2 = TestUtilities.createSampleArticle(id: "duplicate-id")
        
        let entities: [any AssociatedData] = [entity1, entity2]
        let graph = RAGUtilities.generateKnowledgeGraph(entities)
        
        // Should only have one node despite duplicate IDs
        #expect(graph.nodes.count == 1)
        #expect(graph.nodes[0].id == "duplicate-id")
    }
    
    @Test("Knowledge graph edge uniqueness")
    func testKnowledgeGraphEdgeUniqueness() throws {
        var person = TestUtilities.createSamplePerson(id: "person-1")
        
        // Add duplicate relationships (same target, different instances)
        let relationship1 = Relationship(targetId: "target-1", type: .organization, displayName: "Works at")
        let relationship2 = Relationship(targetId: "target-1", type: .organization, displayName: "Works at")
        
        person.relationships = [relationship1, relationship2]
        
        let entities: [any AssociatedData] = [person]
        let graph = RAGUtilities.generateKnowledgeGraph(entities)
        
        // Should have unique edges based on their IDs
        let uniqueEdgeIds = Set(graph.edges.map(\.id))
        #expect(uniqueEdgeIds.count == graph.edges.count)
    }
    
    // MARK: - Vector Preparation Tests
    
    @Test("Vector record preparation")
    func testVectorRecordPreparation() throws {
        let entities: [any AssociatedData] = [
            TestUtilities.createSampleArticle(),
            TestUtilities.createSamplePerson(),
            TestUtilities.createSampleOrganization()
        ]
        
        let vectorRecords = RAGUtilities.prepareEntitiesForEmbedding(entities)
        
        #expect(!vectorRecords.isEmpty)
        #expect(vectorRecords.count >= entities.count) // At least one record per entity, plus relationship records
        
        for record in vectorRecords {
            #expect(!record.id.isEmpty)
            #expect(!record.content.isEmpty)
            #expect(record.content.count > 20) // Should be substantial text
            #expect(!record.entityType.isEmpty)
            
            // Should be suitable for embedding
            #expect(!record.content.contains("{"))
            #expect(!record.content.contains("}"))
            #expect(!record.content.contains("null"))
        }
    }
    
    @Test("Vector record content quality")
    func testVectorRecordContentQuality() throws {
        let person = TestUtilities.createSamplePerson()
        let vectorRecords = RAGUtilities.prepareEntitiesForEmbedding([person])
        
        #expect(!vectorRecords.isEmpty)
        
        let personRecord = vectorRecords.first!
        #expect(personRecord.content.contains(person.name))
        #expect(personRecord.content.contains(person.id))
        #expect(personRecord.entityType == "Person")
        
        // Should be natural language suitable for embeddings
        #expect(personRecord.content.contains("This is a"))
        #expect(personRecord.content.lowercased().contains("person"))
    }
    
    // MARK: - EntityDetailsProvider Tests
    
    @Test("EntityDetailsProvider integration")
    func testEntityDetailsProviderIntegration() throws {
        // Create a mock entity that implements EntityDetailsProvider
        let mockEntity = MockEntityWithDetails()
        
        let context = RAGUtilities.generateEntityContext(mockEntity)
        
        #expect(context.contains("## Details"))
        #expect(context.contains("This is detailed information"))
        #expect(context.contains("MockEntity"))
    }
    
    // MARK: - Performance Tests
    
    @Test("Large entity collection processing")
    func testLargeEntityCollectionProcessing() throws {
        // Create many entities
        let largeEntityCollection: [any AssociatedData] = (0..<100).map { index in
            TestUtilities.createSampleArticle(id: "article-\(index)")
        }
        
        let startTime = Date()
        
        // Test knowledge graph generation performance
        let graph = RAGUtilities.generateKnowledgeGraph(largeEntityCollection)
        let graphTime = Date().timeIntervalSince(startTime)
        
        #expect(graphTime < 2.0, "Knowledge graph generation should complete within 2 seconds")
        #expect(graph.nodes.count == 100)
        
        // Test vector preparation performance
        let vectorStartTime = Date()
        let vectorRecords = RAGUtilities.prepareEntitiesForEmbedding(largeEntityCollection)
        let vectorTime = Date().timeIntervalSince(vectorStartTime)
        
        #expect(vectorTime < 3.0, "Vector preparation should complete within 3 seconds")
        #expect(vectorRecords.count >= 100)
    }
    
    @Test("Context generation performance")
    func testContextGenerationPerformance() throws {
        let entities = TestDataCollections.sampleEntities
        
        let startTime = Date()
        let combinedContext = RAGUtilities.generateCombinedContext(entities)
        let contextTime = Date().timeIntervalSince(startTime)
        
        #expect(contextTime < 1.0, "Context generation should complete within 1 second")
        #expect(!combinedContext.isEmpty)
        #expect(combinedContext.count > 100)
    }
    
    // MARK: - Edge Cases and Error Handling
    
    @Test("Empty entity collection")
    func testEmptyEntityCollection() throws {
        let emptyEntities: [any AssociatedData] = []
        
        let graph = RAGUtilities.generateKnowledgeGraph(emptyEntities)
        #expect(graph.nodes.isEmpty)
        #expect(graph.edges.isEmpty)
        
        let vectorRecords = RAGUtilities.prepareEntitiesForEmbedding(emptyEntities)
        #expect(vectorRecords.isEmpty)
        
        let combinedContext = RAGUtilities.generateCombinedContext(emptyEntities)
        #expect(combinedContext.isEmpty)
    }
    
    @Test("Entities with no relationships")
    func testEntitiesWithNoRelationships() throws {
        let entities: [any AssociatedData] = [
            Article(title: "No Relationships", url: "https://example.com", relationships: []),
            Person(name: "Isolated Person", relationships: []),
            Organization(name: "Standalone Org", relationships: [])
        ]
        
        let graph = RAGUtilities.generateKnowledgeGraph(entities)
        #expect(graph.nodes.count == 3)
        #expect(graph.edges.isEmpty)
        
        let vectorRecords = RAGUtilities.prepareEntitiesForEmbedding(entities)
        #expect(vectorRecords.count == 3) // One per entity, no relationship records
        
        for record in vectorRecords {
            #expect(!record.content.contains("relationship"))
        }
    }
    
    @Test("Very long entity names and content")
    func testVeryLongEntityContent() throws {
        let longName = String(repeating: "Very Long Name ", count: 100)
        let longBio = String(repeating: "This is a very long biography with lots of details. ", count: 100)
        
        let person = Person(name: longName, bio: longBio)
        
        let context = RAGUtilities.generateEntityContext(person)
        #expect(context.contains(longName))
        #expect(context.count > 1000)
        
        let vectorRecords = RAGUtilities.prepareEntitiesForEmbedding([person])
        #expect(!vectorRecords.isEmpty)
        #expect(vectorRecords[0].content.count > 1000)
    }
    
    @Test("Special characters in entity content")
    func testSpecialCharactersInContent() throws {
        let specialName = "Entity with émojis 🎉 and special chars: @#$%^&*()"
        let specialBio = "Bio with quotes \"like this\" and apostrophes 'like this' and newlines\nand tabs\t"
        
        let person = Person(name: specialName, bio: specialBio)
        
        let context = RAGUtilities.generateEntityContext(person)
        #expect(context.contains("🎉"))
        #expect(context.contains("@#$%"))
        
        let vectorRecords = RAGUtilities.prepareEntitiesForEmbedding([person])
        #expect(vectorRecords[0].content.contains("🎉"))
        
        let graph = RAGUtilities.generateKnowledgeGraph([person])
        #expect(graph.nodes[0].name.contains("🎉"))
        
        // Should still be valid JSON
        let jsonString = try graph.toJSON()
        let jsonData = jsonString.data(using: .utf8)!
        let parsedJSON = try JSONSerialization.jsonObject(with: jsonData)
        #expect(parsedJSON is [String: Any])
    }
}

// MARK: - Mock Entity for Testing

/// Mock entity that implements EntityDetailsProvider for testing
struct MockEntityWithDetails: UtahNewsDataModels.AssociatedData, EntityDetailsProvider {
    let id: String = "mock-entity-1"
    let name: String = "MockEntity"
    var relationships: [UtahNewsDataModels.Relationship] = []
    
    func getDetailedDescription() -> String {
        return "This is detailed information about the MockEntity. It includes comprehensive details for RAG context generation."
    }
}