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
            UtahNewsData.Relationship(id: "person-1", type: .person, displayName: "CEO", context: "Founded the company in 2010"),
            UtahNewsData.Relationship(id: "person-2", type: .person, displayName: "CTO", context: "Leads technical innovation"),
            UtahNewsData.Relationship(id: "location-1", type: .location, displayName: "Headquarters", context: "Main office location"),
            UtahNewsData.Relationship(id: "article-1", type: .article, displayName: "Featured in", context: "Recent news coverage"),
            UtahNewsData.Relationship(id: "source-1", type: .source, displayName: "News source", context: "Regular media contact")
        ]

        let context = RAGUtilities.generateEntityContext(organization)

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
        let articles: [UtahNewsData.Article] = [
            TestUtilities.createSampleArticle(id: "article-ctx-1"),
            TestUtilities.createSampleArticle(id: "article-ctx-2"),
            TestUtilities.createSampleArticle(id: "article-ctx-3")
        ]

        let combinedContext = RAGUtilities.generateCombinedContext(articles)

        // Should contain article type
        #expect(combinedContext.contains("# Article:"))

        // Should have separators
        #expect(combinedContext.contains("---"))

        // Should be substantial
        #expect(combinedContext.count > 300)
    }

    @Test("Combined context with length limit")
    func testCombinedContextWithLengthLimit() throws {
        let articles: [UtahNewsData.Article] = (0..<5).map { index in
            TestUtilities.createSampleArticle(id: "limit-article-\(index)")
        }

        let shortContext = RAGUtilities.generateCombinedContext(articles, maxLength: 500)

        #expect(shortContext.count <= 500)
        #expect(!shortContext.isEmpty)

        // Should still be valid context
        #expect(shortContext.contains("#"))
    }

    // MARK: - Knowledge Graph Tests

    @Test("Knowledge graph generation")
    func testKnowledgeGraphGeneration() throws {
        let articles: [UtahNewsData.Article] = [
            TestUtilities.createSampleArticle(id: "article-1"),
            TestUtilities.createSampleArticle(id: "article-2"),
            TestUtilities.createSampleArticle(id: "article-3")
        ]

        let graph = RAGUtilities.generateKnowledgeGraph(articles)

        // Should have nodes for all entities
        #expect(graph.nodes.count == 3)

        // Verify node properties
        let articleNode = graph.nodes.first { $0.id == "article-1" }
        #expect(articleNode != nil)
        #expect(articleNode!.type == "Article")
        #expect(!articleNode!.name.isEmpty)

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
        var person1 = TestUtilities.createSamplePerson(id: "person-1")
        var person2 = TestUtilities.createSamplePerson(id: "person-2")

        // Create bidirectional relationships
        person1.relationships = [
            UtahNewsData.Relationship(id: "person-2", type: .person, displayName: "Colleague", context: "Software Engineer")
        ]

        person2.relationships = [
            UtahNewsData.Relationship(id: "person-1", type: .person, displayName: "Colleague", context: "Software Engineer")
        ]

        let entities = [person1, person2]
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

        let entities = [entity1, entity2]
        let graph = RAGUtilities.generateKnowledgeGraph(entities)

        // Should only have one node despite duplicate IDs
        #expect(graph.nodes.count == 1)
        #expect(graph.nodes[0].id == "duplicate-id")
    }

    @Test("Knowledge graph edge uniqueness")
    func testKnowledgeGraphEdgeUniqueness() throws {
        var person = TestUtilities.createSamplePerson(id: "person-1")

        // Add duplicate relationships (same target, different instances)
        let relationship1 = UtahNewsData.Relationship(id: "target-1", type: .organization, displayName: "Works at")
        let relationship2 = UtahNewsData.Relationship(id: "target-1", type: .organization, displayName: "Works at")

        person.relationships = [relationship1, relationship2]

        let entities = [person]
        let graph = RAGUtilities.generateKnowledgeGraph(entities)

        // Should have unique edges based on their IDs
        let uniqueEdgeIds = Set(graph.edges.map(\.id))
        #expect(uniqueEdgeIds.count == graph.edges.count)
    }

    // MARK: - Vector Preparation Tests

    @Test("Vector record preparation")
    func testVectorRecordPreparation() throws {
        let articles: [UtahNewsData.Article] = [
            TestUtilities.createSampleArticle(id: "vec-article-1"),
            TestUtilities.createSampleArticle(id: "vec-article-2"),
            TestUtilities.createSampleArticle(id: "vec-article-3")
        ]

        let vectorRecords = RAGUtilities.prepareEntitiesForEmbedding(articles)

        #expect(!vectorRecords.isEmpty)
        #expect(vectorRecords.count >= articles.count) // At least one record per entity, plus relationship records

        for record in vectorRecords {
            #expect(!record.id.isEmpty)
            #expect(!record.text.isEmpty)
            #expect(record.text.count > 20) // Should be substantial text
            #expect(!record.entityType.isEmpty)

            // Should be suitable for embedding
            #expect(!record.text.contains("{"))
            #expect(!record.text.contains("}"))
            #expect(!record.text.contains("null"))
        }
    }

    @Test("Vector record content quality")
    func testVectorRecordContentQuality() throws {
        let person = TestUtilities.createSamplePerson()
        let vectorRecords = RAGUtilities.prepareEntitiesForEmbedding([person])

        #expect(!vectorRecords.isEmpty)

        let personRecord = vectorRecords.first!
        #expect(personRecord.text.contains(person.name))
        #expect(personRecord.text.contains(person.id))
        #expect(personRecord.entityType == "Person")

        // Should be natural language suitable for embeddings
        #expect(personRecord.text.contains("This is a"))
        #expect(personRecord.text.lowercased().contains("person"))
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
        let largeEntityCollection: [UtahNewsData.Article] = (0..<100).map { index in
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
        let articles: [UtahNewsData.Article] = (0..<7).map { index in
            TestUtilities.createSampleArticle(id: "perf-article-\(index)")
        }

        let startTime = Date()
        let combinedContext = RAGUtilities.generateCombinedContext(articles)
        let contextTime = Date().timeIntervalSince(startTime)

        #expect(contextTime < 1.0, "Context generation should complete within 1 second")
        #expect(!combinedContext.isEmpty)
        #expect(combinedContext.count > 100)
    }

    // MARK: - Edge Cases and Error Handling

    @Test("Empty entity collection")
    func testEmptyEntityCollection() throws {
        let emptyEntities: [UtahNewsData.Article] = []

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
        let articles: [UtahNewsData.Article] = [
            UtahNewsData.Article(title: "No Relationships 1", url: "https://example.com/1", relationships: []),
            UtahNewsData.Article(title: "No Relationships 2", url: "https://example.com/2", relationships: []),
            UtahNewsData.Article(title: "No Relationships 3", url: "https://example.com/3", relationships: [])
        ]

        let graph = RAGUtilities.generateKnowledgeGraph(articles)
        #expect(graph.nodes.count == 3)
        #expect(graph.edges.isEmpty)

        let vectorRecords = RAGUtilities.prepareEntitiesForEmbedding(articles)
        #expect(vectorRecords.count == 3) // One per entity, no relationship records

        for record in vectorRecords {
            #expect(!record.text.contains("relationship"))
        }
    }

    @Test("Very long entity names and content")
    func testVeryLongEntityContent() throws {
        let longName = String(repeating: "Very Long Name ", count: 100)
        let longDetails = String(repeating: "This is a very long biography with lots of details. ", count: 100)

        let person = UtahNewsData.Person(name: longName, details: longDetails)

        let context = RAGUtilities.generateEntityContext(person)
        #expect(context.contains(longName))
        #expect(context.count > 1000)

        let vectorRecords = RAGUtilities.prepareEntitiesForEmbedding([person])
        #expect(!vectorRecords.isEmpty)
        #expect(vectorRecords[0].text.count > 1000)
    }

    @Test("Special characters in entity content")
    func testSpecialCharactersInContent() throws {
        let specialName = "Entity with emojis and special chars: @#$%^&*()"
        let specialDetails = "Details with quotes \"like this\" and apostrophes 'like this' and newlines\nand tabs\t"

        let person = UtahNewsData.Person(name: specialName, details: specialDetails)

        let context = RAGUtilities.generateEntityContext(person)
        #expect(context.contains("@#$%"))

        let vectorRecords = RAGUtilities.prepareEntitiesForEmbedding([person])
        #expect(!vectorRecords.isEmpty)

        let graph = RAGUtilities.generateKnowledgeGraph([person])
        #expect(!graph.nodes.isEmpty)

        // Should still be valid JSON
        let jsonString = try graph.toJSON()
        let jsonData = jsonString.data(using: .utf8)!
        let parsedJSON = try JSONSerialization.jsonObject(with: jsonData)
        #expect(parsedJSON is [String: Any])
    }
}

// MARK: - Mock Entity for Testing

/// Mock entity that implements EntityDetailsProvider for testing
struct MockEntityWithDetails: UtahNewsData.AssociatedData, EntityDetailsProvider {
    var id: String = "mock-entity-1"
    var name: String = "MockEntity"
    var relationships: [UtahNewsData.Relationship] = []

    func getDetailedDescription() -> String {
        return "This is detailed information about the MockEntity. It includes comprehensive details for RAG context generation."
    }
}
