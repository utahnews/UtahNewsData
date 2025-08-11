//
//  CrossPlatformCompatibilityTests.swift
//  UtahNewsDataModelsTests
//
//  Created by Mark Evans on 01/29/25
//
//  Summary: Tests for cross-platform compatibility across iOS 18+, macOS 15+, tvOS, and watchOS.
//           Ensures models work consistently across all supported Apple platforms.

import Foundation
import Testing
@testable import UtahNewsDataModels

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

#if canImport(WatchKit)
import WatchKit
#endif

@Suite("Cross-Platform Compatibility Tests")
struct CrossPlatformCompatibilityTests {
    
    // MARK: - Platform Detection Tests
    
    @Test("Platform availability validation")
    func testPlatformAvailability() throws {
        // Test that we're running on a supported platform
        #if os(iOS)
        if #available(iOS 18.0, *) {
            #expect(true, "Running on supported iOS version")
        } else {
            Issue.record("iOS version should be 18.0 or later")
        }
        #elseif os(macOS)
        if #available(macOS 15.0, *) {
            #expect(true, "Running on supported macOS version")
        } else {
            Issue.record("macOS version should be 15.0 or later")
        }
        #elseif os(tvOS)
        if #available(tvOS 18.0, *) {
            #expect(true, "Running on supported tvOS version")
        } else {
            Issue.record("tvOS version should be 18.0 or later")
        }
        #elseif os(watchOS)
        if #available(watchOS 11.0, *) {
            #expect(true, "Running on supported watchOS version")
        } else {
            Issue.record("watchOS version should be 11.0 or later")
        }
        #endif
    }
    
    // MARK: - Foundation Framework Compatibility
    
    @Test("Foundation types cross-platform compatibility")
    func testFoundationCompatibility() throws {
        let models: [any Codable] = [
            TestUtilities.createSampleArticle(),
            TestUtilities.createSampleVideo(),
            TestUtilities.createSampleAudio(),
            TestUtilities.createSamplePerson(),
            TestUtilities.createSampleOrganization(),
            TestUtilities.createSampleLocation(),
            TestUtilities.createSampleSource()
        ]
        
        for model in models {
            // Test JSONEncoder/JSONDecoder compatibility
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            let data = try encoder.encode(model)
            #expect(data.count > 0, "Model should encode to non-empty data")
            
            // Test that encoded data is consistent across platforms
            let jsonString = String(data: data, encoding: .utf8)
            #expect(jsonString != nil, "Encoded data should be valid UTF-8")
            
            // Test that we can parse the JSON as a dictionary
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            #expect(jsonObject is [String: Any], "JSON should deserialize to dictionary")
        }
    }
    
    @Test("Date handling cross-platform consistency")
    func testDateHandlingConsistency() throws {
        let testDates = [
            Date(), // Current date
            Date(timeIntervalSince1970: 0), // Unix epoch
            Date(timeIntervalSince1970: 1640995200), // 2022-01-01
            Date.distantPast,
            Date.distantFuture
        ]
        
        for testDate in testDates {
            let article = Article(
                title: "Date Test Article",
                url: "https://example.com/date-test",
                publishedAt: testDate
            )
            
            // Test ISO8601 encoding/decoding
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(article)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decodedArticle = try decoder.decode(Article.self, from: data)
            
            // Allow for small rounding differences due to encoding precision
            let timeDifference = abs(article.publishedAt.timeIntervalSince(decodedArticle.publishedAt))
            #expect(timeDifference < 1.0, "Date should be preserved within 1 second accuracy")
        }
    }
    
    @Test("UUID generation cross-platform consistency")
    func testUUIDConsistency() throws {
        // Generate multiple UUIDs and verify they're valid across platforms
        let uuids = (0..<100).map { _ in UUID().uuidString }
        
        for uuid in uuids {
            // Test UUID format
            #expect(uuid.count == 36, "UUID should be 36 characters long")
            #expect(uuid.filter { $0 == "-" }.count == 4, "UUID should have 4 hyphens")
            
            // Test that UUID can be used as model ID
            let article = Article(
                id: uuid,
                title: "UUID Test",
                url: "https://example.com/uuid"
            )
            
            try TestUtilities.validateCodableConformance(article)
        }
        
        // Verify all UUIDs are unique
        let uniqueUUIDs = Set(uuids)
        #expect(uniqueUUIDs.count == uuids.count, "All UUIDs should be unique")
    }
    
    // MARK: - String Handling Cross-Platform
    
    @Test("Unicode string handling")
    func testUnicodeStringHandling() throws {
        let unicodeStrings = [
            "Hello, 世界", // Chinese
            "Привет, мир", // Russian
            "مرحبا بالعالم", // Arabic
            "🌍🌎🌏", // Emojis
            "Iñtërnâtiônàlizætiøn", // Various accents
            "\u{1F1FA}\u{1F1F8}", // Flag emoji (compound)
            "Test\nwith\nnewlines\tand\ttabs"
        ]
        
        for unicodeString in unicodeStrings {
            let person = Person(
                name: unicodeString,
                bio: "Bio: \(unicodeString)"
            )
            
            try TestUtilities.validateCodableConformance(person)
            
            // Test embedding text generation with unicode
            let embeddingText = person.toEmbeddingText()
            #expect(embeddingText.contains(unicodeString), "Embedding text should preserve unicode strings")
        }
    }
    
    @Test("String normalization consistency")
    func testStringNormalization() throws {
        // Test various string normalizations
        let testStrings = [
            "café", // é as single character
            "cafe\u{0301}", // e + combining acute accent
            "naïve",
            "résumé"
        ]
        
        for testString in testStrings {
            let organization = Organization(name: testString)
            
            try TestUtilities.validateCodableConformance(organization)
            
            // Verify string is preserved in JSON
            let encoder = JSONEncoder()
            let data = try encoder.encode(organization)
            let jsonString = String(data: data, encoding: .utf8)!
            
            #expect(jsonString.contains(testString) || jsonString.contains(testString.precomposedStringWithCanonicalMapping), 
                   "String should be preserved in some normalized form")
        }
    }
    
    // MARK: - Memory Management Cross-Platform
    
    @Test("Memory efficiency across platforms")
    func testMemoryEfficiency() throws {
        // Create large collections to test memory handling
        let largeArticleCollection = (0..<1000).map { index in
            TestUtilities.createSampleArticle(id: "memory-test-\(index)")
        }
        
        #expect(largeArticleCollection.count == 1000)
        
        // Test that we can encode/decode large collections
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let startTime = Date()
        let data = try encoder.encode(largeArticleCollection)
        let encodingTime = Date().timeIntervalSince(startTime)
        
        #expect(data.count > 0, "Large collection should encode successfully")
        #expect(encodingTime < 5.0, "Encoding should complete within reasonable time")
        
        // Test decoding
        let decodeStartTime = Date()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedCollection = try decoder.decode([Article].self, from: data)
        let decodingTime = Date().timeIntervalSince(decodeStartTime)
        
        #expect(decodedCollection.count == largeArticleCollection.count)
        #expect(decodingTime < 5.0, "Decoding should complete within reasonable time")
    }
    
    // MARK: - Platform-Specific Feature Tests
    
    @Test("Platform-specific availability")
    func testPlatformSpecificFeatures() throws {
        // Test features that might behave differently across platforms
        
        #if os(iOS) || os(tvOS)
        // iOS/tvOS specific tests
        let article = TestUtilities.createSampleArticle()
        try TestUtilities.validateCodableConformance(article)
        #expect(true, "iOS/tvOS models work correctly")
        
        #elseif os(macOS)
        // macOS specific tests
        let article = TestUtilities.createSampleArticle()
        try TestUtilities.validateCodableConformance(article)
        #expect(true, "macOS models work correctly")
        
        #elseif os(watchOS)
        // watchOS specific tests (might have memory constraints)
        let article = Article(title: "watchOS Test", url: "https://example.com/watch")
        try TestUtilities.validateCodableConformance(article)
        #expect(true, "watchOS models work correctly")
        #endif
    }
    
    @Test("Property list compatibility")
    func testPropertyListCompatibility() throws {
        // Test that models work with PropertyListEncoder/Decoder
        let models: [any Codable] = [
            TestUtilities.createSampleArticle(),
            TestUtilities.createSamplePerson(),
            TestUtilities.createSampleOrganization()
        ]
        
        for model in models {
            let plistEncoder = PropertyListEncoder()
            plistEncoder.outputFormat = .xml
            
            let plistData = try plistEncoder.encode(model)
            #expect(plistData.count > 0, "Model should encode to property list")
            
            // Verify it's valid XML
            let xmlString = String(data: plistData, encoding: .utf8)
            #expect(xmlString?.contains("<?xml") == true, "Should generate valid XML property list")
        }
    }
    
    // MARK: - Locale and Region Tests
    
    @Test("Locale-independent behavior")
    func testLocaleIndependentBehavior() throws {
        // Test with different locales to ensure consistent behavior
        let testLocales = [
            Locale(identifier: "en_US"),
            Locale(identifier: "fr_FR"),
            Locale(identifier: "ja_JP"),
            Locale(identifier: "ar_SA")
        ]
        
        let originalLocale = Locale.current
        
        for testLocale in testLocales {
            // Note: We can't actually change the current locale in tests,
            // but we can test that our models don't depend on locale-specific formatting
            
            let article = TestUtilities.createSampleArticle()
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            let data = try encoder.encode(article)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let decodedArticle = try decoder.decode(Article.self, from: data)
            #expect(decodedArticle.id == article.id, "Model should decode consistently regardless of locale")
        }
    }
    
    // MARK: - File System Compatibility
    
    @Test("File system path handling")
    func testFileSystemPathHandling() throws {
        // Test various URL formats that might be used across platforms
        let testURLs = [
            "https://example.com/article",
            "http://example.com/path/to/resource",
            "https://example.com/path with spaces/file.html",
            "https://example.com/path/with/unicode/世界.html",
            "file:///local/path/to/file.html"
        ]
        
        for urlString in testURLs {
            let article = Article(
                title: "URL Test",
                url: urlString
            )
            
            try TestUtilities.validateCodableConformance(article)
            
            // Verify URL can be created from string
            if !urlString.contains(" ") {
                #expect(URL(string: urlString) != nil, "URL should be valid: \(urlString)")
            }
        }
    }
    
    // MARK: - Threading Model Compatibility
    
    @Test("Thread safety across platforms")
    func testThreadSafetyAcrossPlatforms() async throws {
        // Test that models work correctly in concurrent environments
        let article = TestUtilities.createSampleArticle()
        
        // Test concurrent access
        await withTaskGroup(of: String.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let embeddingText = article.toEmbeddingText()
                    return "\(i): \(embeddingText.prefix(50))"
                }
            }
            
            var results: [String] = []
            for await result in group {
                results.append(result)
            }
            
            #expect(results.count == 10, "All concurrent tasks should complete")
        }
    }
    
    // MARK: - JSON Schema Cross-Platform
    
    @Test("JSON schema cross-platform consistency")
    func testJSONSchemaConsistency() throws {
        let schemas = [
            Article.jsonSchema,
            Video.jsonSchema,
            Audio.jsonSchema,
            Person.jsonSchema,
            Organization.jsonSchema,
            Location.jsonSchema,
            Source.jsonSchema
        ]
        
        for schema in schemas {
            // Verify schema is valid JSON on all platforms
            let data = schema.data(using: .utf8)!
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            #expect(jsonObject is [String: Any], "Schema should be valid JSON object")
            
            // Verify it can be re-serialized consistently
            let reserializedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.sortedKeys])
            let reserializedSchema = String(data: reserializedData, encoding: .utf8)
            
            #expect(reserializedSchema != nil, "Schema should re-serialize consistently")
        }
    }
}