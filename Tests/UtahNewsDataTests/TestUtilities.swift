//
//  TestUtilities.swift
//  UtahNewsDataTests
//
//  Created by Mark Evans on 01/29/25
//
//  Summary: Shared test utilities for the UtahNewsData target tests.

import Foundation
import Testing
@testable import UtahNewsData
@testable import UtahNewsDataModels

/// Shared utilities for testing UtahNewsData models
struct TestUtilities {
    
    // MARK: - Mock Data Generation
    
    /// Generates a sample Article for testing
    static func createSampleArticle(id: String = "test-article-\(UUID().uuidString)") -> UtahNewsData.Article {
        UtahNewsData.Article(
            id: id,
            title: "Sample Test Article",
            url: "https://example.com/article",
            urlToImage: "https://example.com/image.jpg",
            additionalImages: ["https://example.com/image2.jpg"],
            publishedAt: Date(),
            textContent: "This is sample article content for testing purposes.",
            author: "Test Author",
            category: "News",
            videoURL: "https://example.com/video.mp4",
            location: createSampleLocation(),
            relationships: [createSampleRelationship()]
        )
    }
    
    /// Generates a sample Video for testing
    static func createSampleVideo(id: String = "test-video-\(UUID().uuidString)") -> UtahNewsData.Video {
        UtahNewsData.Video(
            id: id,
            title: "Sample Test Video",
            url: "https://example.com/video",
            urlToImage: "https://example.com/video-thumb.jpg",
            publishedAt: Date(),
            textContent: "This is sample video description for testing.",
            author: "Test Video Creator",
            category: "Video News",
            duration: 300,
            relationships: [createSampleRelationship()]
        )
    }
    
    /// Generates a sample Audio for testing
    static func createSampleAudio(id: String = "test-audio-\(UUID().uuidString)") -> UtahNewsData.Audio {
        UtahNewsData.Audio(
            id: id,
            title: "Sample Test Audio",
            url: "https://example.com/audio",
            urlToImage: "https://example.com/audio-thumb.jpg",
            publishedAt: Date(),
            textContent: "This is sample audio description for testing.",
            author: "Test Audio Creator",
            category: "Podcast",
            duration: 1800,
            relationships: [createSampleRelationship()]
        )
    }
    
    /// Generates a sample Person for testing
    static func createSamplePerson(id: String = "test-person-\(UUID().uuidString)") -> UtahNewsData.Person {
        UtahNewsData.Person(
            id: id,
            name: "John Test Doe",
            title: "Test Manager",
            bio: "This is a test person for unit testing.",
            profileImageURL: "https://example.com/profile.jpg",
            contactInfo: createSampleContactInfo(),
            relationships: [createSampleRelationship()]
        )
    }
    
    /// Generates a sample Organization for testing
    static func createSampleOrganization(id: String = "test-org-\(UUID().uuidString)") -> UtahNewsData.Organization {
        UtahNewsData.Organization(
            id: id,
            name: "Test Organization Inc.",
            description: "A test organization for unit testing purposes.",
            website: "https://test-org.example.com",
            logoURL: "https://example.com/logo.png",
            contactInfo: createSampleContactInfo(),
            relationships: [createSampleRelationship()]
        )
    }
    
    /// Generates a sample Location for testing
    static func createSampleLocation(id: String = "test-location-\(UUID().uuidString)") -> UtahNewsData.Location {
        UtahNewsData.Location(
            id: id,
            name: "Test City",
            address: "123 Test Street, Test City, UT 84000",
            latitude: 40.7608,
            longitude: -111.8910,
            relationships: [createSampleRelationship()]
        )
    }
    
    /// Generates a sample Source for testing
    static func createSampleSource(id: String = "test-source-\(UUID().uuidString)") -> UtahNewsData.Source {
        UtahNewsData.Source(
            id: id,
            name: "Test News Source",
            url: "https://testnews.example.com",
            description: "A test news source for unit testing.",
            logoURL: "https://example.com/source-logo.png",
            rssURL: "https://testnews.example.com/rss",
            isActive: true,
            relationships: [createSampleRelationship()]
        )
    }
    
    /// Generates a sample ContactInfo for testing
    static func createSampleContactInfo() -> ContactInfo {
        ContactInfo(
            email: "test@example.com",
            phone: "+1-555-123-4567",
            website: "https://example.com",
            socialMedia: [
                "twitter": "@testuser",
                "linkedin": "testuser"
            ]
        )
    }
    
    /// Generates a sample MediaItem for testing
    static func createSampleMediaItem() -> MediaItem {
        MediaItem(
            url: "https://example.com/media.jpg",
            type: .image,
            caption: "Test media item caption",
            altText: "Alt text for test media"
        )
    }
    
    /// Generates a sample Quote for testing
    static func createSampleQuote() -> Quote {
        Quote(
            text: "This is a test quote for unit testing purposes.",
            speaker: "Test Speaker",
            context: "Test context for the quote"
        )
    }
    
    /// Generates a sample Category for testing
    static func createSampleCategory(id: String = "test-category-\(UUID().uuidString)") -> Category {
        Category(
            id: id,
            name: "Test Category",
            description: "A test category for unit testing.",
            relationships: [createSampleRelationship()]
        )
    }
    
    /// Generates a sample NewsEvent for testing
    static func createSampleNewsEvent(id: String = "test-event-\(UUID().uuidString)") -> NewsEvent {
        NewsEvent(
            id: id,
            name: "Test News Event",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: createSampleLocation(),
            description: "This is a test news event for unit testing.",
            relationships: [createSampleRelationship()]
        )
    }
    
    /// Generates a sample Relationship for testing
    static func createSampleRelationship() -> Relationship {
        Relationship(
            targetId: "test-target-\(UUID().uuidString)",
            type: .person,
            displayName: "Test Relationship",
            context: "This is a test relationship context."
        )
    }
    
    // MARK: - Validation Utilities
    
    /// Validates that a model conforms to Codable correctly
    static func validateCodableConformance<T: Codable & Equatable>(
        _ model: T,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        // Test encoding
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encodedData = try encoder.encode(model)
        
        // Verify data is not empty
        #expect(encodedData.count > 0, "Encoded data should not be empty")
        
        // Test decoding
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedModel = try decoder.decode(T.self, from: encodedData)
        
        // Verify round-trip equality
        #expect(model == decodedModel, "Model should equal its decoded version")
    }
    
    /// Validates that a BaseEntity implementation has required properties
    static func validateBaseEntity<T: UtahNewsData.BaseEntity>(
        _ entity: T,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // Verify ID is not empty
        #expect(!entity.id.isEmpty, "Entity ID should not be empty")
        
        // Verify name is not empty
        #expect(!entity.name.isEmpty, "Entity name should not be empty")
        
        // Verify ID is a valid string (contains only allowed characters)
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let idCharacterSet = CharacterSet(charactersIn: entity.id)
        #expect(allowedCharacters.isSuperset(of: idCharacterSet), "Entity ID should contain only alphanumeric characters, hyphens, and underscores")
    }
    
    /// Validates that a NewsContent implementation works correctly
    static func validateNewsContent<T: UtahNewsData.NewsContent>(
        _ content: T,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // Validate BaseEntity conformance
        validateBaseEntity(content, file: file, line: line)
        
        // Verify required NewsContent properties
        #expect(!content.title.isEmpty, "News content title should not be empty")
        #expect(!content.url.isEmpty, "News content URL should not be empty")
        
        // Verify URL format
        #expect(URL(string: content.url) != nil, "News content URL should be valid")
        
        // Verify publishedAt is reasonable (not in the far future)
        let now = Date()
        let futureLimit = now.addingTimeInterval(86400) // 1 day in the future
        #expect(content.publishedAt <= futureLimit, "Published date should not be more than 1 day in the future")
        
        // Test media type determination
        let mediaType = content.determineMediaType()
        #expect(mediaType != nil, "Media type should be determinable")
    }
    
    /// Validates that models work correctly across all supported platforms
    static func validateCrossPlatformCompatibility<T: Codable & Equatable>(
        _ model: T,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        // Test JSON serialization consistency across platforms
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys] // Ensure consistent output
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(model)
        let jsonString = String(data: data, encoding: .utf8)
        
        #expect(jsonString != nil, "Model should serialize to valid UTF-8 JSON")
        #expect(!jsonString!.isEmpty, "Serialized JSON should not be empty")
        
        // Test that the JSON can be parsed back on any platform
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let recreatedModel = try decoder.decode(T.self, from: data)
        #expect(model == recreatedModel, "Model should deserialize identically across platforms")
    }
}

// MARK: - Test Data Collections

/// Collections of test data for comprehensive testing
struct TestDataCollections {
    
    /// Collection of sample entities for relationship testing
    static let sampleEntities: [any AssociatedData] = [
        TestUtilities.createSampleArticle(),
        TestUtilities.createSampleVideo(),
        TestUtilities.createSampleAudio(),
        TestUtilities.createSamplePerson(),
        TestUtilities.createSampleOrganization(),
        TestUtilities.createSampleLocation(),
        TestUtilities.createSampleSource(),
        TestUtilities.createSampleCategory(),
        TestUtilities.createSampleNewsEvent()
    ]
    
    /// Collection of sample news content for content-specific testing
    static let sampleNewsContent: [any NewsContent] = [
        TestUtilities.createSampleArticle(),
        TestUtilities.createSampleVideo(),
        TestUtilities.createSampleAudio()
    ]
    
    /// Collection of all entity types for comprehensive EntityType testing
    static let allEntityTypes: [EntityType] = [
        .article, .person, .organization, .location, .category, .source,
        .mediaItem, .newsEvent, .newsStory, .quote, .fact, .statisticalData,
        .calendarEvent, .legalDocument, .socialMediaPost, .expertAnalysis,
        .poll, .alert, .jurisdiction, .userSubmission, .discussionCategory,
        .discussionThread, .discussionPost
    ]
}