//
//  ModelValidationTests.swift
//  UtahNewsDataModelsTests
//
//  Created by Mark Evans on 01/29/25
//
//  Summary: Comprehensive validation tests for all UtahNewsDataModels core models.
//           Tests Codable conformance, BaseEntity requirements, and basic functionality.

import Foundation
import Testing
@testable import UtahNewsDataModels

@Suite("Model Validation Tests")
struct ModelValidationTests {
    
    // MARK: - Article Tests
    
    @Test("Article model validation")
    func testArticleModel() throws {
        let article = TestUtilities.createSampleArticle()
        
        // Test BaseEntity conformance
        TestUtilities.validateBaseEntity(article)
        
        // Test AssociatedData conformance
        TestUtilities.validateAssociatedData(article)
        
        // Test NewsContent conformance
        TestUtilities.validateNewsContent(article)
        
        // Test Codable conformance
        try TestUtilities.validateCodableConformance(article)
        
        // Test cross-platform compatibility
        try TestUtilities.validateCrossPlatformCompatibility(article)
        
        // Test Article-specific properties
        #expect(article.determineMediaType() == .text)
        #expect(!article.title.isEmpty)
        #expect(URL(string: article.url) != nil)
    }
    
    @Test("Article with minimal data")
    func testArticleMinimalData() throws {
        let article = Article(
            title: "Minimal Article",
            url: "https://example.com/minimal"
        )
        
        TestUtilities.validateBaseEntity(article)
        TestUtilities.validateNewsContent(article)
        try TestUtilities.validateCodableConformance(article)
        
        // Verify defaults
        #expect(article.relationships.isEmpty)
        #expect(article.textContent == nil)
        #expect(article.author == nil)
        #expect(article.category == nil)
    }
    
    // MARK: - Video Tests
    
    @Test("Video model validation")
    func testVideoModel() throws {
        let video = TestUtilities.createSampleVideo()
        
        TestUtilities.validateBaseEntity(video)
        TestUtilities.validateAssociatedData(video)
        TestUtilities.validateNewsContent(video)
        try TestUtilities.validateCodableConformance(video)
        try TestUtilities.validateCrossPlatformCompatibility(video)
        
        // Test Video-specific properties
        #expect(video.determineMediaType() == .video)
        #expect(video.duration != nil)
        #expect(video.duration! > 0)
    }
    
    @Test("Video with minimal data")
    func testVideoMinimalData() throws {
        let video = Video(
            title: "Minimal Video",
            url: "https://example.com/video"
        )
        
        TestUtilities.validateBaseEntity(video)
        TestUtilities.validateNewsContent(video)
        try TestUtilities.validateCodableConformance(video)
        
        #expect(video.duration == nil)
        #expect(video.relationships.isEmpty)
    }
    
    // MARK: - Audio Tests
    
    @Test("Audio model validation")
    func testAudioModel() throws {
        let audio = TestUtilities.createSampleAudio()
        
        TestUtilities.validateBaseEntity(audio)
        TestUtilities.validateAssociatedData(audio)
        TestUtilities.validateNewsContent(audio)
        try TestUtilities.validateCodableConformance(audio)
        try TestUtilities.validateCrossPlatformCompatibility(audio)
        
        // Test Audio-specific properties
        #expect(audio.determineMediaType() == .audio)
        #expect(audio.duration != nil)
        #expect(audio.duration! > 0)
    }
    
    // MARK: - Person Tests
    
    @Test("Person model validation")
    func testPersonModel() throws {
        let person = TestUtilities.createSamplePerson()
        
        TestUtilities.validateBaseEntity(person)
        TestUtilities.validateAssociatedData(person)
        try TestUtilities.validateCodableConformance(person)
        try TestUtilities.validateCrossPlatformCompatibility(person)
        
        // Test Person-specific properties
        #expect(!person.name.isEmpty)
        #expect(person.contactInfo != nil)
        #expect(person.title != nil)
        #expect(person.bio != nil)
    }
    
    @Test("Person with minimal data")
    func testPersonMinimalData() throws {
        let person = Person(name: "John Doe")
        
        TestUtilities.validateBaseEntity(person)
        TestUtilities.validateAssociatedData(person)
        try TestUtilities.validateCodableConformance(person)
        
        #expect(person.title == nil)
        #expect(person.bio == nil)
        #expect(person.contactInfo == nil)
        #expect(person.relationships.isEmpty)
    }
    
    // MARK: - Organization Tests
    
    @Test("Organization model validation")
    func testOrganizationModel() throws {
        let organization = TestUtilities.createSampleOrganization()
        
        TestUtilities.validateBaseEntity(organization)
        TestUtilities.validateAssociatedData(organization)
        try TestUtilities.validateCodableConformance(organization)
        try TestUtilities.validateCrossPlatformCompatibility(organization)
        
        // Test Organization-specific properties
        #expect(!organization.name.isEmpty)
        #expect(organization.contactInfo != nil)
        #expect(organization.description != nil)
        #expect(organization.website != nil)
        
        if let website = organization.website {
            #expect(URL(string: website) != nil, "Organization website should be a valid URL")
        }
    }
    
    // MARK: - Location Tests
    
    @Test("Location model validation")
    func testLocationModel() throws {
        let location = TestUtilities.createSampleLocation()
        
        TestUtilities.validateBaseEntity(location)
        TestUtilities.validateAssociatedData(location)
        try TestUtilities.validateCodableConformance(location)
        try TestUtilities.validateCrossPlatformCompatibility(location)
        
        // Test Location-specific properties
        #expect(!location.name.isEmpty)
        #expect(location.latitude != nil)
        #expect(location.longitude != nil)
        
        if let lat = location.latitude, let lon = location.longitude {
            #expect(lat >= -90 && lat <= 90, "Latitude should be valid")
            #expect(lon >= -180 && lon <= 180, "Longitude should be valid")
        }
    }
    
    // MARK: - Source Tests
    
    @Test("Source model validation")
    func testSourceModel() throws {
        let source = TestUtilities.createSampleSource()
        
        TestUtilities.validateBaseEntity(source)
        TestUtilities.validateAssociatedData(source)
        try TestUtilities.validateCodableConformance(source)
        try TestUtilities.validateCrossPlatformCompatibility(source)
        
        // Test Source-specific properties
        #expect(!source.name.isEmpty)
        #expect(!source.url.isEmpty)
        #expect(URL(string: source.url) != nil, "Source URL should be valid")
        
        if let rssURL = source.rssURL {
            #expect(URL(string: rssURL) != nil, "RSS URL should be valid")
        }
    }
    
    // MARK: - Supporting Model Tests
    
    @Test("ContactInfo model validation")
    func testContactInfoModel() throws {
        let contactInfo = TestUtilities.createSampleContactInfo()
        
        try TestUtilities.validateCodableConformance(contactInfo)
        try TestUtilities.validateCrossPlatformCompatibility(contactInfo)
        
        // Test ContactInfo properties
        if let email = contactInfo.email {
            #expect(email.contains("@"), "Email should contain @ symbol")
        }
        
        if let website = contactInfo.website {
            #expect(URL(string: website) != nil, "Website should be a valid URL")
        }
    }
    
    @Test("MediaItem model validation")
    func testMediaItemModel() throws {
        let mediaItem = TestUtilities.createSampleMediaItem()
        
        try TestUtilities.validateCodableConformance(mediaItem)
        try TestUtilities.validateCrossPlatformCompatibility(mediaItem)
        
        // Test MediaItem properties
        #expect(URL(string: mediaItem.url) != nil, "Media URL should be valid")
        #expect(mediaItem.type != nil, "Media type should be specified")
    }
    
    @Test("Quote model validation")
    func testQuoteModel() throws {
        let quote = TestUtilities.createSampleQuote()
        
        try TestUtilities.validateCodableConformance(quote)
        try TestUtilities.validateCrossPlatformCompatibility(quote)
        
        // Test Quote properties
        #expect(!quote.text.isEmpty, "Quote text should not be empty")
        #expect(quote.speaker != nil, "Quote should have a speaker")
    }
    
    @Test("Category model validation")
    func testCategoryModel() throws {
        let category = TestUtilities.createSampleCategory()
        
        TestUtilities.validateBaseEntity(category)
        TestUtilities.validateAssociatedData(category)
        try TestUtilities.validateCodableConformance(category)
        try TestUtilities.validateCrossPlatformCompatibility(category)
    }
    
    @Test("NewsEvent model validation")
    func testNewsEventModel() throws {
        let newsEvent = TestUtilities.createSampleNewsEvent()
        
        TestUtilities.validateBaseEntity(newsEvent)
        TestUtilities.validateAssociatedData(newsEvent)
        try TestUtilities.validateCodableConformance(newsEvent)
        try TestUtilities.validateCrossPlatformCompatibility(newsEvent)
        
        // Test NewsEvent-specific properties
        #expect(newsEvent.startDate <= newsEvent.endDate, "Start date should be before or equal to end date")
        #expect(newsEvent.location != nil, "News event should have a location")
    }
    
    // MARK: - Relationship System Tests
    
    @Test("Relationship model validation")
    func testRelationshipModel() throws {
        let relationship = TestUtilities.createSampleRelationship()
        
        TestUtilities.validateBaseEntity(relationship)
        try TestUtilities.validateCodableConformance(relationship)
        try TestUtilities.validateCrossPlatformCompatibility(relationship)
        
        // Test Relationship-specific properties
        #expect(!relationship.targetId.isEmpty, "Relationship should have a target ID")
        #expect(relationship.type != nil, "Relationship should have a type")
        #expect(!relationship.name.isEmpty, "Relationship should have a name")
    }
    
    @Test("EntityType enumeration")
    func testEntityTypeEnumeration() throws {
        // Test all entity types have valid properties
        for entityType in TestDataCollections.allEntityTypes {
            #expect(!entityType.rawValue.isEmpty, "Entity type raw value should not be empty")
            #expect(!entityType.singularName.isEmpty, "Entity type singular name should not be empty")
            
            // Test that raw value is different from singular name (raw values are plural)
            #expect(entityType.rawValue != entityType.singularName, "Raw value should be different from singular name")
        }
        
        // Test specific entity types
        #expect(EntityType.article.singularName == "article")
        #expect(EntityType.person.singularName == "person")
        #expect(EntityType.organization.singularName == "organization")
        #expect(EntityType.location.singularName == "location")
    }
    
    // MARK: - Collection Tests
    
    @Test("Test data collections integrity")
    func testDataCollections() throws {
        // Verify sample entities collection
        #expect(!TestDataCollections.sampleEntities.isEmpty, "Sample entities should not be empty")
        #expect(!TestDataCollections.sampleNewsContent.isEmpty, "Sample news content should not be empty")
        #expect(!TestDataCollections.allEntityTypes.isEmpty, "All entity types should not be empty")
        
        // Verify each entity in collections is valid
        for entity in TestDataCollections.sampleEntities {
            TestUtilities.validateBaseEntity(entity)
            TestUtilities.validateAssociatedData(entity)
        }
        
        for content in TestDataCollections.sampleNewsContent {
            TestUtilities.validateBaseEntity(content)
            TestUtilities.validateNewsContent(content)
        }
    }
    
    // MARK: - Edge Case Tests
    
    @Test("Empty relationship arrays")
    func testEmptyRelationships() throws {
        let article = Article(
            title: "Test Article",
            url: "https://example.com/test",
            relationships: []
        )
        
        #expect(article.relationships.isEmpty)
        let embeddingText = article.toEmbeddingText()
        #expect(!embeddingText.isEmpty)
        #expect(!embeddingText.contains("relationship"))
    }
    
    @Test("UUID string format validation")
    func testUUIDStringFormats() throws {
        let article = TestUtilities.createSampleArticle()
        
        // Verify ID format (should be UUID or have valid characters)
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let idCharacterSet = CharacterSet(charactersIn: article.id)
        #expect(allowedCharacters.isSuperset(of: idCharacterSet))
        
        // Test that we can create valid UUIDs
        let uuid = UUID().uuidString
        let articleWithUUID = Article(
            id: uuid,
            title: "UUID Test",
            url: "https://example.com/uuid"
        )
        
        #expect(articleWithUUID.id == uuid)
        try TestUtilities.validateCodableConformance(articleWithUUID)
    }
    
    @Test("Date handling consistency")
    func testDateHandling() throws {
        let now = Date()
        let article = Article(
            title: "Date Test",
            url: "https://example.com/date",
            publishedAt: now
        )
        
        try TestUtilities.validateCodableConformance(article)
        
        // Test that dates survive encoding/decoding
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(article)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedArticle = try decoder.decode(Article.self, from: data)
        
        let timeDifference = abs(article.publishedAt.timeIntervalSince(decodedArticle.publishedAt))
        #expect(timeDifference < 1.0, "Date should be preserved within 1 second accuracy")
    }
}