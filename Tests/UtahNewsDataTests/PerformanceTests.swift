//
//  PerformanceTests.swift
//  UtahNewsDataTests
//
//  Created by Mark Evans on 01/29/25
//
//  Summary: Performance tests for large data operations, serialization, parsing,
//           and concurrent operations in the UtahNewsData package.

import Foundation
import Testing
@testable import UtahNewsData
@testable import UtahNewsDataModels

@Suite("Performance Tests")
struct PerformanceTests {
    
    // MARK: - Serialization Performance Tests
    
    @Test("Large article collection JSON serialization")
    func testLargeArticleCollectionSerialization() async throws {
        let articleCount = 1000
        let articles: [UtahNewsData.Article] = (0..<articleCount).map { index in
            TestUtilities.createSampleArticle(id: "perf-article-\(index)")
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        
        let startTime = Date()
        let data = try encoder.encode(articles)
        let encodingTime = Date().timeIntervalSince(startTime)
        
        #expect(encodingTime < 2.0, "Encoding \(articleCount) articles should complete within 2 seconds")
        #expect(data.count > 0, "Encoded data should not be empty")
        
        // Test deserialization performance
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let decodeStartTime = Date()
        let decodedArticles = try decoder.decode([UtahNewsData.Article].self, from: data)
        let decodingTime = Date().timeIntervalSince(decodeStartTime)
        
        #expect(decodingTime < 2.0, "Decoding \(articleCount) articles should complete within 2 seconds")
        #expect(decodedArticles.count == articleCount)
        
        // Verify first and last articles are correct
        #expect(decodedArticles.first?.id == "perf-article-0")
        #expect(decodedArticles.last?.id == "perf-article-\(articleCount - 1)")
    }
    
    @Test("JSON schema generation performance")
    func testJSONSchemaGenerationPerformance() throws {
        let iterations = 10000
        
        let startTime = Date()
        for _ in 0..<iterations {
            _ = Article.jsonSchema
            _ = Video.jsonSchema
            _ = Audio.jsonSchema
            _ = Person.jsonSchema
            _ = Organization.jsonSchema
        }
        let totalTime = Date().timeIntervalSince(startTime)
        
        #expect(totalTime < 1.0, "Generating schemas \(iterations) times should complete within 1 second")
        
        // Verify schemas are still valid
        try TestUtilities.validateJSONSchema(Article.jsonSchema)
        try TestUtilities.validateJSONSchema(Person.jsonSchema)
    }
    
    // MARK: - HTML Parsing Performance Tests
    
    @Test("Large HTML document parsing performance")
    func testLargeHTMLParsingPerformance() throws {
        // Generate a very large HTML document
        var largeHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Performance Test Article</title>
            <meta name="author" content="Performance Tester">
            <meta property="og:image" content="https://example.com/perf-image.jpg">
        </head>
        <body>
            <h1>Performance Test Article</h1>
            <div class="content">
        """
        
        // Add 5000 paragraphs
        for i in 0..<5000 {
            largeHTML += """
            <p>This is paragraph number \(i). It contains substantial content for performance testing. 
            The content includes various HTML elements and enough text to simulate real-world articles. 
            Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt 
            ut labore et dolore magna aliqua.</p>
            """
        }
        
        largeHTML += """
            </div>
        </body>
        </html>
        """
        
        let startTime = Date()
        let article = try Article.parse(from: largeHTML)
        let parsingTime = Date().timeIntervalSince(startTime)
        
        #expect(parsingTime < 5.0, "Parsing large HTML document should complete within 5 seconds")
        #expect(article.title == "Performance Test Article")
        #expect(article.textContent != nil)
        #expect(article.textContent!.contains("paragraph number 4999"))
        
        // Test that the parsed article can be serialized efficiently
        let encoder = JSONEncoder()
        let serializationStartTime = Date()
        let data = try encoder.encode(article)
        let serializationTime = Date().timeIntervalSince(serializationStartTime)
        
        #expect(serializationTime < 1.0, "Serializing large article should complete within 1 second")
        #expect(data.count > 0)
    }
    
    @Test("Multiple HTML parsing concurrency")
    func testMultipleHTMLParsingConcurrency() async throws {
        let htmlDocuments = (0..<50).map { index in
            """
            <!DOCTYPE html>
            <html>
            <head>
                <title>Concurrent Article \(index)</title>
                <meta name="author" content="Concurrency Tester">
            </head>
            <body>
                <h1>Concurrent Article \(index)</h1>
                <p>This is the content for article \(index) being parsed concurrently.</p>
                <p>Additional paragraph to make the parsing more realistic.</p>
            </body>
            </html>
            """
        }
        
        let startTime = Date()
        
        // Parse all documents concurrently
        let articles = await withTaskGroup(of: Article.self, returning: [Article].self) { group in
            for html in htmlDocuments {
                group.addTask {
                    try! Article.parse(from: html)
                }
            }
            
            var results: [Article] = []
            for await article in group {
                results.append(article)
            }
            return results
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        #expect(totalTime < 3.0, "Concurrent parsing of 50 articles should complete within 3 seconds")
        #expect(articles.count == 50)
        
        // Verify all articles were parsed correctly
        let uniqueTitles = Set(articles.map(\.title))
        #expect(uniqueTitles.count == 50, "All articles should have unique titles")
    }
    
    // MARK: - Relationship Processing Performance Tests
    
    @Test("Large relationship network processing")
    func testLargeRelationshipNetworkProcessing() throws {
        // Create entities with many relationships
        let entityCount = 100
        let relationshipsPerEntity = 50
        
        var entities: [any AssociatedData] = []
        
        // Create base entities
        for i in 0..<entityCount {
            let person = TestUtilities.createSamplePerson(id: "person-\(i)")
            entities.append(person)
        }
        
        // Add many relationships to each entity
        for i in 0..<entityCount {
            var entity = entities[i]
            var relationships: [Relationship] = []
            
            for j in 0..<relationshipsPerEntity {
                let targetIndex = (i + j + 1) % entityCount
                let relationship = Relationship(
                    targetId: "person-\(targetIndex)",
                    type: .person,
                    displayName: "Relationship \(j)",
                    context: "Context for relationship \(j) from entity \(i) to entity \(targetIndex)"
                )
                relationships.append(relationship)
            }
            
            entity.relationships = relationships
            entities[i] = entity
        }
        
        // Test embedding text generation performance
        let embeddingStartTime = Date()
        let embeddingTexts = entities.map { $0.toEmbeddingText() }
        let embeddingTime = Date().timeIntervalSince(embeddingStartTime)
        
        #expect(embeddingTime < 2.0, "Generating embedding text for \(entityCount) entities with \(relationshipsPerEntity) relationships each should complete within 2 seconds")
        #expect(embeddingTexts.count == entityCount)
        
        // Verify embedding texts contain relationship information
        for text in embeddingTexts {
            #expect(text.contains("relationship"))
            #expect(text.count > 500, "Embedding text should be substantial with many relationships")
        }
        
        // Test knowledge graph generation performance
        let graphStartTime = Date()
        let knowledgeGraph = RAGUtilities.generateKnowledgeGraph(entities)
        let graphTime = Date().timeIntervalSince(graphStartTime)
        
        #expect(graphTime < 3.0, "Knowledge graph generation should complete within 3 seconds")
        #expect(knowledgeGraph.nodes.count == entityCount)
        #expect(knowledgeGraph.edges.count == entityCount * relationshipsPerEntity)
    }
    
    @Test("Vector record preparation performance")
    func testVectorRecordPreparationPerformance() throws {
        let entityCount = 500
        let entities: [any AssociatedData] = (0..<entityCount).map { index in
            var article = TestUtilities.createSampleArticle(id: "vector-article-\(index)")
            
            // Add some relationships
            article.relationships = [
                Relationship(targetId: "person-\(index)", type: .person, displayName: "Author"),
                Relationship(targetId: "org-\(index)", type: .organization, displayName: "Publisher")
            ]
            
            return article
        }
        
        let startTime = Date()
        let vectorRecords = RAGUtilities.prepareEntitiesForEmbedding(entities)
        let preparationTime = Date().timeIntervalSince(startTime)
        
        #expect(preparationTime < 2.0, "Vector record preparation for \(entityCount) entities should complete within 2 seconds")
        #expect(vectorRecords.count >= entityCount, "Should have at least one record per entity")
        
        // Verify record quality
        for record in vectorRecords.prefix(10) { // Check first 10 records
            #expect(!record.content.isEmpty)
            #expect(record.content.count > 20)
            #expect(!record.entityType.isEmpty)
        }
    }
    
    // MARK: - Memory Performance Tests
    
    @Test("Memory efficiency with large collections")
    func testMemoryEfficiencyWithLargeCollections() async throws {
        let entityCount = 2000
        
        // Create a large collection
        let articles = (0..<entityCount).map { index in
            TestUtilities.createSampleArticle(id: "memory-test-\(index)")
        }
        
        // Test that we can process the collection without memory issues
        let startTime = Date()
        
        // Perform various operations
        let serializedData = try JSONEncoder().encode(articles)
        let deserializedArticles = try JSONDecoder().decode([Article].self, from: serializedData)
        
        #expect(deserializedArticles.count == entityCount)
        
        // Test concurrent processing
        let embeddingTexts = await withTaskGroup(of: String.self, returning: [String].self) { group in
            for article in articles.prefix(100) { // Process first 100 concurrently
                group.addTask {
                    return article.toEmbeddingText()
                }
            }
            
            var texts: [String] = []
            for await text in group {
                texts.append(text)
            }
            return texts
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        #expect(totalTime < 5.0, "Large collection processing should complete within 5 seconds")
        #expect(embeddingTexts.count == 100)
        #expect(serializedData.count > 0)
    }
    
    // MARK: - Concurrent Operations Performance Tests
    
    @Test("Concurrent model creation performance")
    func testConcurrentModelCreationPerformance() async throws {
        let concurrentTasks = 100
        
        let startTime = Date()
        
        let results = await withTaskGroup(of: (Article, Video, Audio, Person).self, returning: [(Article, Video, Audio, Person)].self) { group in
            for i in 0..<concurrentTasks {
                group.addTask {
                    let article = TestUtilities.createSampleArticle(id: "concurrent-\(i)")
                    let video = TestUtilities.createSampleVideo(id: "video-\(i)")
                    let audio = TestUtilities.createSampleAudio(id: "audio-\(i)")
                    let person = TestUtilities.createSamplePerson(id: "person-\(i)")
                    return (article, video, audio, person)
                }
            }
            
            var allResults: [(Article, Video, Audio, Person)] = []
            for await result in group {
                allResults.append(result)
            }
            return allResults
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        #expect(totalTime < 2.0, "Concurrent creation of \(concurrentTasks * 4) models should complete within 2 seconds")
        #expect(results.count == concurrentTasks)
        
        // Verify uniqueness
        let allArticleIds = Set(results.map { $0.0.id })
        #expect(allArticleIds.count == concurrentTasks, "All article IDs should be unique")
    }
    
    @Test("Concurrent JSON serialization performance")
    func testConcurrentJSONSerializationPerformance() async throws {
        let models: [any Codable & Sendable] = (0..<200).map { index in
            TestUtilities.createSampleArticle(id: "serial-\(index)")
        }
        
        let startTime = Date()
        
        let serializedData = await withTaskGroup(of: Data.self, returning: [Data].self) { group in
            for model in models {
                group.addTask {
                    let encoder = JSONEncoder()
                    encoder.dateEncodingStrategy = .iso8601
                    return try! encoder.encode(model)
                }
            }
            
            var allData: [Data] = []
            for await data in group {
                allData.append(data)
            }
            return allData
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        #expect(totalTime < 3.0, "Concurrent serialization of 200 models should complete within 3 seconds")
        #expect(serializedData.count == 200)
        
        // Verify all serializations produced data
        for data in serializedData {
            #expect(data.count > 0)
        }
    }
    
    // MARK: - Cross-Platform Performance Tests
    
    @Test("Cross-platform date handling performance")
    func testCrossPlatformDateHandlingPerformance() throws {
        let dateCount = 10000
        let testDates = (0..<dateCount).map { index in
            Date(timeIntervalSince1970: TimeInterval(index * 3600)) // Every hour
        }
        
        let articles = testDates.map { date in
            UtahNewsData.Article(
                title: "Date Test Article",
                url: "https://example.com/date-test",
                publishedAt: date
            )
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let startTime = Date()
        let data = try encoder.encode(articles)
        let encodingTime = Date().timeIntervalSince(startTime)
        
        #expect(encodingTime < 2.0, "Encoding \(dateCount) articles with dates should complete within 2 seconds")
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let decodeStartTime = Date()
        let decodedArticles = try decoder.decode([UtahNewsData.Article].self, from: data)
        let decodingTime = Date().timeIntervalSince(decodeStartTime)
        
        #expect(decodingTime < 2.0, "Decoding \(dateCount) articles with dates should complete within 2 seconds")
        #expect(decodedArticles.count == dateCount)
        
        // Verify date accuracy
        for (original, decoded) in zip(articles, decodedArticles) {
            let timeDifference = abs(original.publishedAt.timeIntervalSince(decoded.publishedAt))
            #expect(timeDifference < 1.0, "Date should be preserved within 1 second accuracy")
        }
    }
    
    // MARK: - Stress Tests
    
    @Test("High volume relationship processing")
    func testHighVolumeRelationshipProcessing() throws {
        // Create one entity with an extremely large number of relationships
        var organization = TestUtilities.createSampleOrganization()
        
        let relationshipCount = 5000
        organization.relationships = (0..<relationshipCount).map { index in
            Relationship(
                targetId: "target-\(index)",
                type: [EntityType.person, EntityType.organization, EntityType.location].randomElement() ?? .person,
                displayName: "Relationship \(index)",
                context: "Context for relationship number \(index) with detailed information"
            )
        }
        
        let startTime = Date()
        
        // Test embedding text generation
        let embeddingText = organization.toEmbeddingText()
        
        // Test serialization
        let encoder = JSONEncoder()
        let data = try encoder.encode(organization)
        
        // Test deserialization
        let decoder = JSONDecoder()
        let decodedOrg = try decoder.decode(Organization.self, from: data)
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        #expect(totalTime < 5.0, "Processing entity with \(relationshipCount) relationships should complete within 5 seconds")
        #expect(!embeddingText.isEmpty)
        #expect(embeddingText.contains("relationship"))
        #expect(decodedOrg.relationships.count == relationshipCount)
        #expect(data.count > 0)
    }
}