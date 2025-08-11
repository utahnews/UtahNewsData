//
//  ConcurrencyComplianceTests.swift
//  UtahNewsDataModelsTests
//
//  Created by Mark Evans on 01/29/25
//
//  Summary: Tests for Swift 6 strict concurrency compliance, Sendable conformance,
//           and thread-safety of all models in the UtahNewsDataModels package.

import Foundation
import Testing
@testable import UtahNewsDataModels

@Suite("Swift 6 Concurrency Compliance Tests")
struct ConcurrencyComplianceTests {
    
    // MARK: - Sendable Conformance Tests
    
    @Test("Article Sendable compliance")
    func testArticleSendableCompliance() async throws {
        let article = TestUtilities.createSampleArticle()
        
        // Test that Article can be sent across actor boundaries
        let result = await testSendableInDetachedTask(article)
        #expect(result.id == article.id)
        #expect(result.title == article.title)
        
        // Test in concurrent context
        await testConcurrentAccess(article)
    }
    
    @Test("Video Sendable compliance")
    func testVideoSendableCompliance() async throws {
        let video = TestUtilities.createSampleVideo()
        
        let result = await testSendableInDetachedTask(video)
        #expect(result.id == video.id)
        #expect(result.title == video.title)
        
        await testConcurrentAccess(video)
    }
    
    @Test("Audio Sendable compliance")
    func testAudioSendableCompliance() async throws {
        let audio = TestUtilities.createSampleAudio()
        
        let result = await testSendableInDetachedTask(audio)
        #expect(result.id == audio.id)
        #expect(result.title == audio.title)
        
        await testConcurrentAccess(audio)
    }
    
    @Test("Person Sendable compliance")
    func testPersonSendableCompliance() async throws {
        let person = TestUtilities.createSamplePerson()
        
        let result = await testSendableInDetachedTask(person)
        #expect(result.id == person.id)
        #expect(result.name == person.name)
        
        await testConcurrentAccess(person)
    }
    
    @Test("Organization Sendable compliance")
    func testOrganizationSendableCompliance() async throws {
        let organization = TestUtilities.createSampleOrganization()
        
        let result = await testSendableInDetachedTask(organization)
        #expect(result.id == organization.id)
        #expect(result.name == organization.name)
        
        await testConcurrentAccess(organization)
    }
    
    @Test("Location Sendable compliance")
    func testLocationSendableCompliance() async throws {
        let location = TestUtilities.createSampleLocation()
        
        let result = await testSendableInDetachedTask(location)
        #expect(result.id == location.id)
        #expect(result.name == location.name)
        
        await testConcurrentAccess(location)
    }
    
    @Test("Source Sendable compliance")
    func testSourceSendableCompliance() async throws {
        let source = TestUtilities.createSampleSource()
        
        let result = await testSendableInDetachedTask(source)
        #expect(result.id == source.id)
        #expect(result.name == source.name)
        
        await testConcurrentAccess(source)
    }
    
    @Test("Supporting models Sendable compliance")
    func testSupportingModelsSendableCompliance() async throws {
        // Test ContactInfo
        let contactInfo = TestUtilities.createSampleContactInfo()
        let contactResult = await testSendableInDetachedTask(contactInfo)
        #expect(contactResult.email == contactInfo.email)
        
        // Test MediaItem
        let mediaItem = TestUtilities.createSampleMediaItem()
        let mediaResult = await testSendableInDetachedTask(mediaItem)
        #expect(mediaResult.url == mediaItem.url)
        
        // Test Quote
        let quote = TestUtilities.createSampleQuote()
        let quoteResult = await testSendableInDetachedTask(quote)
        #expect(quoteResult.text == quote.text)
        
        // Test Category
        let category = TestUtilities.createSampleCategory()
        let categoryResult = await testSendableInDetachedTask(category)
        #expect(categoryResult.id == category.id)
        
        // Test NewsEvent
        let newsEvent = TestUtilities.createSampleNewsEvent()
        let eventResult = await testSendableInDetachedTask(newsEvent)
        #expect(eventResult.id == newsEvent.id)
    }
    
    @Test("Relationship and EntityType Sendable compliance")
    func testRelationshipSendableCompliance() async throws {
        let relationship = TestUtilities.createSampleRelationship()
        let result = await testSendableInDetachedTask(relationship)
        #expect(result.id == relationship.id)
        #expect(result.targetId == relationship.targetId)
        
        // Test EntityType
        let entityType = EntityType.person
        let typeResult = await testSendableInDetachedTask(entityType)
        #expect(typeResult == entityType)
        
        // Test RelationshipSource
        let source = RelationshipSource.system
        let sourceResult = await testSendableInDetachedTask(source)
        #expect(sourceResult == source)
    }
    
    // MARK: - Concurrent Access Tests
    
    @Test("Concurrent model creation")
    func testConcurrentModelCreation() async throws {
        // Create multiple models concurrently
        async let articles = createMultipleArticlesConcurrently()
        async let videos = createMultipleVideosConcurrently()
        async let people = createMultiplePeopleConcurrently()
        
        let (createdArticles, createdVideos, createdPeople) = await (articles, videos, people)
        
        #expect(createdArticles.count == 10)
        #expect(createdVideos.count == 10)
        #expect(createdPeople.count == 10)
        
        // Verify all IDs are unique
        let allArticleIds = Set(createdArticles.map(\.id))
        #expect(allArticleIds.count == createdArticles.count)
        
        let allVideoIds = Set(createdVideos.map(\.id))
        #expect(allVideoIds.count == createdVideos.count)
        
        let allPeopleIds = Set(createdPeople.map(\.id))
        #expect(allPeopleIds.count == createdPeople.count)
    }
    
    @Test("Concurrent JSON serialization")
    func testConcurrentJSONSerialization() async throws {
        let models: [any Codable & Sendable] = [
            TestUtilities.createSampleArticle(),
            TestUtilities.createSampleVideo(),
            TestUtilities.createSampleAudio(),
            TestUtilities.createSamplePerson(),
            TestUtilities.createSampleOrganization()
        ]
        
        // Serialize all models concurrently
        let tasks = models.map { model in
            Task {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                return try encoder.encode(model)
            }
        }
        
        var results: [Data] = []
        for task in tasks {
            let data = try await task.value
            results.append(data)
            #expect(data.count > 0)
        }
        
        #expect(results.count == models.count)
    }
    
    @Test("Concurrent embedding text generation")
    func testConcurrentEmbeddingTextGeneration() async throws {
        let entities = TestDataCollections.sampleEntities
        
        // Generate embedding text concurrently
        let tasks = entities.map { entity in
            Task {
                return entity.toEmbeddingText()
            }
        }
        
        var embeddingTexts: [String] = []
        for task in tasks {
            let text = await task.value
            embeddingTexts.append(text)
            #expect(!text.isEmpty)
            #expect(text.count > 10) // Reasonable minimum length
        }
        
        #expect(embeddingTexts.count == entities.count)
    }
    
    // MARK: - Actor-Based Tests
    
    @Test("Models work with actors")
    func testModelsWithActors() async throws {
        let storage = ModelStorage()
        
        // Store models in actor
        let article = TestUtilities.createSampleArticle()
        let person = TestUtilities.createSamplePerson()
        
        await storage.store(article: article)
        await storage.store(person: person)
        
        // Retrieve models from actor
        let retrievedArticle = await storage.getArticle(id: article.id)
        let retrievedPerson = await storage.getPerson(id: person.id)
        
        #expect(retrievedArticle?.id == article.id)
        #expect(retrievedPerson?.id == person.id)
        
        // Test concurrent access to actor
        async let count1 = storage.getArticleCount()
        async let count2 = storage.getPersonCount()
        
        let (articleCount, personCount) = await (count1, count2)
        #expect(articleCount == 1)
        #expect(personCount == 1)
    }
    
    @Test("TaskGroup with models")
    func testTaskGroupWithModels() async throws {
        let results = await withTaskGroup(of: String.self, returning: [String].self) { group in
            let entities = TestDataCollections.sampleEntities.prefix(5)
            
            for entity in entities {
                group.addTask {
                    return entity.toEmbeddingText()
                }
            }
            
            var embeddingTexts: [String] = []
            for await text in group {
                embeddingTexts.append(text)
            }
            return embeddingTexts
        }
        
        #expect(results.count == 5)
        for text in results {
            #expect(!text.isEmpty)
        }
    }
    
    // MARK: - Thread Safety Tests
    
    @Test("Model immutability thread safety")
    func testModelImmutabilityThreadSafety() async throws {
        let originalArticle = TestUtilities.createSampleArticle()
        
        // Modify properties concurrently (creating new instances)
        let tasks = (0..<10).map { index in
            Task {
                var modifiedArticle = originalArticle
                modifiedArticle.relationships.append(
                    Relationship(
                        targetId: "target-\(index)",
                        type: .person,
                        displayName: "Relationship \(index)"
                    )
                )
                return modifiedArticle
            }
        }
        
        var modifiedArticles: [Article] = []
        for task in tasks {
            let article = await task.value
            modifiedArticles.append(article)
        }
        
        #expect(modifiedArticles.count == 10)
        
        // Original should be unchanged
        #expect(originalArticle.relationships.count < modifiedArticles[0].relationships.count)
        
        // Each modified version should have different relationship counts
        for (index, article) in modifiedArticles.enumerated() {
            let expectedCount = originalArticle.relationships.count + 1
            #expect(article.relationships.count == expectedCount)
        }
    }
    
    // MARK: - Helper Methods and Actor
    
    /// Test that a Sendable type can be passed to a detached task
    private func testSendableInDetachedTask<T: Sendable>(_ value: T) async -> T {
        return await Task.detached {
            return value
        }.value
    }
    
    /// Test concurrent access to a Sendable type
    private func testConcurrentAccess<T: Sendable & Equatable>(_ value: T) async {
        let tasks = (0..<5).map { _ in
            Task.detached {
                return value
            }
        }
        
        for task in tasks {
            let result = await task.value
            #expect(result == value)
        }
    }
    
    /// Create multiple articles concurrently
    private func createMultipleArticlesConcurrently() async -> [Article] {
        return await withTaskGroup(of: Article.self, returning: [Article].self) { group in
            for i in 0..<10 {
                group.addTask {
                    return TestUtilities.createSampleArticle(id: "concurrent-article-\(i)")
                }
            }
            
            var articles: [Article] = []
            for await article in group {
                articles.append(article)
            }
            return articles
        }
    }
    
    /// Create multiple videos concurrently
    private func createMultipleVideosConcurrently() async -> [Video] {
        return await withTaskGroup(of: Video.self, returning: [Video].self) { group in
            for i in 0..<10 {
                group.addTask {
                    return TestUtilities.createSampleVideo(id: "concurrent-video-\(i)")
                }
            }
            
            var videos: [Video] = []
            for await video in group {
                videos.append(video)
            }
            return videos
        }
    }
    
    /// Create multiple people concurrently
    private func createMultiplePeopleConcurrently() async -> [Person] {
        return await withTaskGroup(of: Person.self, returning: [Person].self) { group in
            for i in 0..<10 {
                group.addTask {
                    return TestUtilities.createSamplePerson(id: "concurrent-person-\(i)")
                }
            }
            
            var people: [Person] = []
            for await person in group {
                people.append(person)
            }
            return people
        }
    }
}

// MARK: - Test Actor

/// Actor for testing model storage and concurrent access
actor ModelStorage {
    private var articles: [String: Article] = [:]
    private var people: [String: Person] = [:]
    
    func store(article: Article) {
        articles[article.id] = article
    }
    
    func store(person: Person) {
        people[person.id] = person
    }
    
    func getArticle(id: String) -> Article? {
        return articles[id]
    }
    
    func getPerson(id: String) -> Person? {
        return people[id]
    }
    
    func getArticleCount() -> Int {
        return articles.count
    }
    
    func getPersonCount() -> Int {
        return people.count
    }
    
    func clear() {
        articles.removeAll()
        people.removeAll()
    }
}