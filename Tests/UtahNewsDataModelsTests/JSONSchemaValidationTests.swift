//
//  JSONSchemaValidationTests.swift
//  UtahNewsDataModelsTests
//
//  Created by Mark Evans on 01/29/25
//
//  Summary: Comprehensive validation tests for JSON schema generation and conformance.
//           Tests all JSONSchemaProvider conforming types for valid schema generation.

import Foundation
import Testing
@testable import UtahNewsDataModels

@Suite("JSON Schema Validation Tests")
struct JSONSchemaValidationTests {
    
    // MARK: - Core Model Schema Tests
    
    @Test("Article JSON schema validation")
    func testArticleJSONSchema() throws {
        // Validate schema structure
        try TestUtilities.validateJSONSchema(Article.jsonSchema)
        
        // Parse and validate specific schema requirements
        let schemaData = Article.jsonSchema.data(using: .utf8)!
        let schema = try JSONSerialization.jsonObject(with: schemaData) as! [String: Any]
        
        #expect(schema["type"] as? String == "object")
        
        let properties = schema["properties"] as! [String: Any]
        #expect(properties["id"] != nil, "Schema should include id property")
        #expect(properties["title"] != nil, "Schema should include title property")
        #expect(properties["url"] != nil, "Schema should include url property")
        #expect(properties["publishedAt"] != nil, "Schema should include publishedAt property")
        
        let required = schema["required"] as! [String]
        #expect(required.contains("id"), "id should be required")
        #expect(required.contains("title"), "title should be required")
        #expect(required.contains("url"), "url should be required")
        #expect(required.contains("publishedAt"), "publishedAt should be required")
    }
    
    // Note: Video and Audio in UtahNewsDataModels don't implement JSONSchemaProvider
    // They are lightweight models without schema generation capabilities
    
    @Test("Person JSON schema validation")
    func testPersonJSONSchema() throws {
        try TestUtilities.validateJSONSchema(Person.jsonSchema)
        
        let schemaData = Person.jsonSchema.data(using: .utf8)!
        let schema = try JSONSerialization.jsonObject(with: schemaData) as! [String: Any]
        
        let properties = schema["properties"] as! [String: Any]
        #expect(properties["name"] != nil, "Person schema should include name property")
        #expect(properties["title"] != nil, "Person schema should include title property")
        #expect(properties["bio"] != nil, "Person schema should include bio property")
        #expect(properties["contactInfo"] != nil, "Person schema should include contactInfo property")
    }
    
    @Test("Organization JSON schema validation")
    func testOrganizationJSONSchema() throws {
        try TestUtilities.validateJSONSchema(Organization.jsonSchema)
        
        let schemaData = Organization.jsonSchema.data(using: .utf8)!
        let schema = try JSONSerialization.jsonObject(with: schemaData) as! [String: Any]
        
        let properties = schema["properties"] as! [String: Any]
        #expect(properties["name"] != nil, "Organization schema should include name property")
        #expect(properties["description"] != nil, "Organization schema should include description property")
        #expect(properties["website"] != nil, "Organization schema should include website property")
    }
    
    @Test("Location JSON schema validation")
    func testLocationJSONSchema() throws {
        try TestUtilities.validateJSONSchema(Location.jsonSchema)
        
        let schemaData = Location.jsonSchema.data(using: .utf8)!
        let schema = try JSONSerialization.jsonObject(with: schemaData) as! [String: Any]
        
        let properties = schema["properties"] as! [String: Any]
        #expect(properties["name"] != nil, "Location schema should include name property")
        #expect(properties["latitude"] != nil, "Location schema should include latitude property")
        #expect(properties["longitude"] != nil, "Location schema should include longitude property")
        #expect(properties["address"] != nil, "Location schema should include address property")
    }
    
    @Test("Source JSON schema validation")
    func testSourceJSONSchema() throws {
        try TestUtilities.validateJSONSchema(Source.jsonSchema)
        
        let schemaData = Source.jsonSchema.data(using: .utf8)!
        let schema = try JSONSerialization.jsonObject(with: schemaData) as! [String: Any]
        
        let properties = schema["properties"] as! [String: Any]
        #expect(properties["name"] != nil, "Source schema should include name property")
        #expect(properties["url"] != nil, "Source schema should include url property")
        #expect(properties["isActive"] != nil, "Source schema should include isActive property")
    }
    
    @Test("Category JSON schema validation")
    func testCategoryJSONSchema() throws {
        try TestUtilities.validateJSONSchema(Category.jsonSchema)
        
        let schemaData = Category.jsonSchema.data(using: .utf8)!
        let schema = try JSONSerialization.jsonObject(with: schemaData) as! [String: Any]
        
        let properties = schema["properties"] as! [String: Any]
        #expect(properties["name"] != nil, "Category schema should include name property")
        #expect(properties["description"] != nil, "Category schema should include description property")
    }
    
    @Test("NewsEvent JSON schema validation")
    func testNewsEventJSONSchema() throws {
        try TestUtilities.validateJSONSchema(NewsEvent.jsonSchema)
        
        let schemaData = NewsEvent.jsonSchema.data(using: .utf8)!
        let schema = try JSONSerialization.jsonObject(with: schemaData) as! [String: Any]
        
        let properties = schema["properties"] as! [String: Any]
        #expect(properties["name"] != nil, "NewsEvent schema should include name property")
        #expect(properties["startDate"] != nil, "NewsEvent schema should include startDate property")
        #expect(properties["endDate"] != nil, "NewsEvent schema should include endDate property")
        #expect(properties["location"] != nil, "NewsEvent schema should include location property")
    }
    
    // MARK: - Schema Compliance Tests
    
    @Test("Schema matches actual model structure")
    func testSchemaModelCompliance() throws {
        // Test Article schema compliance
        let article = TestUtilities.createSampleArticle()
        try validateModelAgainstSchema(article, schema: Article.jsonSchema)
        
        // Note: Video and Audio don't implement JSONSchemaProvider in UtahNewsDataModels
        
        // Test Person schema compliance
        let person = TestUtilities.createSamplePerson()
        try validateModelAgainstSchema(person, schema: Person.jsonSchema)
        
        // Test Organization schema compliance
        let organization = TestUtilities.createSampleOrganization()
        try validateModelAgainstSchema(organization, schema: Organization.jsonSchema)
        
        // Test Location schema compliance
        let location = TestUtilities.createSampleLocation()
        try validateModelAgainstSchema(location, schema: Location.jsonSchema)
        
        // Test Source schema compliance
        let source = TestUtilities.createSampleSource()
        try validateModelAgainstSchema(source, schema: Source.jsonSchema)
        
        // Test Category schema compliance
        let category = TestUtilities.createSampleCategory()
        try validateModelAgainstSchema(category, schema: Category.jsonSchema)
        
        // Test NewsEvent schema compliance
        let newsEvent = TestUtilities.createSampleNewsEvent()
        try validateModelAgainstSchema(newsEvent, schema: NewsEvent.jsonSchema)
    }
    
    @Test("Schema required fields validation")
    func testSchemaRequiredFields() throws {
        // Test that schemas properly define required vs optional fields
        let articleSchema = try parseJSONSchema(Article.jsonSchema)
        let required = articleSchema["required"] as? [String] ?? []
        
        #expect(required.contains("id"), "Article id should be required")
        #expect(required.contains("title"), "Article title should be required")
        #expect(required.contains("url"), "Article url should be required")
        #expect(required.contains("publishedAt"), "Article publishedAt should be required")
        #expect(!required.contains("textContent"), "Article textContent should be optional")
        #expect(!required.contains("author"), "Article author should be optional")
    }
    
    @Test("Schema property types validation")
    func testSchemaPropertyTypes() throws {
        let articleSchema = try parseJSONSchema(Article.jsonSchema)
        let properties = articleSchema["properties"] as! [String: Any]
        
        // Test string properties
        let titleProperty = properties["title"] as! [String: Any]
        #expect(titleProperty["type"] as? String == "string", "title should be string type")
        
        let urlProperty = properties["url"] as! [String: Any]
        #expect(urlProperty["type"] as? String == "string", "url should be string type")
        
        // Test nullable properties
        let textContentProperty = properties["textContent"] as! [String: Any]
        if let typeArray = textContentProperty["type"] as? [String] {
            #expect(typeArray.contains("string") && typeArray.contains("null"), "textContent should be nullable string")
        }
        
        // Test date properties
        let publishedAtProperty = properties["publishedAt"] as! [String: Any]
        #expect(publishedAtProperty["type"] as? String == "string", "publishedAt should be string type")
        #expect(publishedAtProperty["format"] as? String == "date-time", "publishedAt should have date-time format")
    }
    
    @Test("Schema array properties validation")
    func testSchemaArrayProperties() throws {
        let articleSchema = try parseJSONSchema(Article.jsonSchema)
        let properties = articleSchema["properties"] as! [String: Any]
        
        // Test additionalImages array property
        if let additionalImagesProperty = properties["additionalImages"] as? [String: Any] {
            if let typeArray = additionalImagesProperty["type"] as? [String] {
                #expect(typeArray.contains("array") && typeArray.contains("null"), "additionalImages should be nullable array")
            }
            
            if let items = additionalImagesProperty["items"] as? [String: Any] {
                #expect(items["type"] as? String == "string", "additionalImages items should be strings")
            }
        }
    }
    
    // MARK: - Schema Generation Edge Cases
    
    @Test("Schema generation with minimal models")
    func testSchemaWithMinimalModels() throws {
        // Test that schemas work with models that have minimal data
        let minimalArticle = Article(title: "Test", url: "https://example.com")
        try validateModelAgainstSchema(minimalArticle, schema: Article.jsonSchema)
        
        let minimalPerson = Person(name: "Test Person", details: "Minimal person for testing")
        try validateModelAgainstSchema(minimalPerson, schema: Person.jsonSchema)
        
        let minimalOrganization = Organization(name: "Test Org")
        try validateModelAgainstSchema(minimalOrganization, schema: Organization.jsonSchema)
    }
    
    @Test("Schema JSON formatting")
    func testSchemaJSONFormatting() throws {
        // Test that all schemas are properly formatted JSON
        let schemas = [
            Article.jsonSchema,
            Person.jsonSchema,
            Organization.jsonSchema,
            Location.jsonSchema,
            Source.jsonSchema,
            Category.jsonSchema,
            NewsEvent.jsonSchema
        ]
        
        for schema in schemas {
            // Should be valid JSON
            let data = schema.data(using: .utf8)!
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            // Should be a dictionary
            #expect(jsonObject is [String: Any], "Schema should be a JSON object")
            
            // Should be re-serializable
            let reserializedData = try JSONSerialization.data(withJSONObject: jsonObject)
            let reserializedString = String(data: reserializedData, encoding: .utf8)
            #expect(reserializedString != nil, "Schema should be re-serializable")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Validates that a model's JSON representation matches its schema
    private func validateModelAgainstSchema<T: Codable & JSONSchemaProvider>(
        _ model: T,
        schema: String,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        // Encode the model to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let modelData = try encoder.encode(model)
        let modelJSON = try JSONSerialization.jsonObject(with: modelData) as! [String: Any]
        
        // Parse the schema
        let schemaDict = try parseJSONSchema(schema)
        let properties = schemaDict["properties"] as! [String: Any]
        let required = schemaDict["required"] as? [String] ?? []
        
        // Validate required fields are present
        for requiredField in required {
            #expect(modelJSON[requiredField] != nil, "Required field '\(requiredField)' should be present in model JSON")
        }
        
        // Validate that all model properties are defined in schema
        for (key, value) in modelJSON {
            #expect(properties[key] != nil, "Model property '\(key)' should be defined in schema")
            
            // Basic type checking
            if let propertySchema = properties[key] as? [String: Any] {
                try validatePropertyType(value, against: propertySchema, propertyName: key, file: file, line: line)
            }
        }
    }
    
    /// Validates a property value against its schema definition
    private func validatePropertyType(
        _ value: Any,
        against propertySchema: [String: Any],
        propertyName: String,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        if let typeString = propertySchema["type"] as? String {
            validateSingleType(value, expectedType: typeString, propertyName: propertyName, file: file, line: line)
        } else if let typeArray = propertySchema["type"] as? [String] {
            // Handle nullable types
            if value is NSNull {
                #expect(typeArray.contains("null"), "Property '\(propertyName)' should allow null values")
            } else {
                let nonNullTypes = typeArray.filter { $0 != "null" }
                let isValidType = nonNullTypes.contains { type in
                    isValueOfType(value, type: type)
                }
                #expect(isValidType, "Property '\(propertyName)' should match one of the allowed types: \(nonNullTypes)")
            }
        }
    }
    
    /// Validates a value against a single expected type
    private func validateSingleType(
        _ value: Any,
        expectedType: String,
        propertyName: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let isValid = isValueOfType(value, type: expectedType)
        #expect(isValid, "Property '\(propertyName)' should be of type '\(expectedType)'")
    }
    
    /// Checks if a value matches a JSON schema type
    private func isValueOfType(_ value: Any, type: String) -> Bool {
        switch type {
        case "string":
            return value is String
        case "number":
            return value is NSNumber && !(value is Bool)
        case "integer":
            return value is Int || (value is NSNumber && CFNumberIsFloatType(value as! CFNumber) == false)
        case "boolean":
            return value is Bool
        case "array":
            return value is [Any]
        case "object":
            return value is [String: Any]
        case "null":
            return value is NSNull
        default:
            return false
        }
    }
    
    /// Parses a JSON schema string into a dictionary
    private func parseJSONSchema(_ schema: String) throws -> [String: Any] {
        let data = schema.data(using: .utf8)!
        return try JSONSerialization.jsonObject(with: data) as! [String: Any]
    }
}