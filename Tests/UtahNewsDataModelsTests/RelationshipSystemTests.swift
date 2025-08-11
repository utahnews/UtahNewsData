//
//  RelationshipSystemTests.swift
//  UtahNewsDataModelsTests
//
//  Created by Mark Evans on 01/29/25
//
//  Summary: Comprehensive tests for the relationship system, entity associations,
//           and embedding text generation functionality.

import Foundation
import Testing
@testable import UtahNewsDataModels

@Suite("Relationship System Tests")
struct RelationshipSystemTests {
    
    // MARK: - Relationship Model Tests
    
    @Test("Relationship creation and properties")
    func testRelationshipCreation() throws {
        let targetId = "test-target-123"
        let relationship = Relationship(
            targetId: targetId,
            type: .person,
            displayName: "Works with",
            context: "Collaborated on project X"
        )
        
        #expect(relationship.targetId == targetId)
        #expect(relationship.type == .person)
        #expect(relationship.displayName == "Works with")
        #expect(relationship.context == "Collaborated on project X")
        #expect(!relationship.id.isEmpty)
        #expect(relationship.createdAt <= Date())
        
        // Test name property
        #expect(relationship.name == "Works with")
        
        try TestUtilities.validateCodableConformance(relationship)
    }
    
    @Test("Relationship without display name")
    func testRelationshipWithoutDisplayName() throws {
        let targetId = "test-target-456"
        let relationship = Relationship(
            targetId: targetId,
            type: .organization
        )
        
        #expect(relationship.displayName == nil)
        #expect(relationship.name == "Relationship to organization test-target-456")
        
        try TestUtilities.validateCodableConformance(relationship)
    }
    
    @Test("Relationship equality and hashing")
    func testRelationshipEquality() throws {
        let relationship1 = Relationship(
            targetId: "target-1",
            type: .person,
            displayName: "Colleague"
        )
        
        let relationship2 = Relationship(
            targetId: "target-1",
            type: .person,
            displayName: "Colleague"
        )
        
        // Different instances with different IDs should not be equal
        #expect(relationship1 != relationship2)
        #expect(relationship1.hashValue != relationship2.hashValue)
        
        // Same instance should be equal to itself
        #expect(relationship1 == relationship1)
        #expect(relationship1.hashValue == relationship1.hashValue)
    }
    
    // MARK: - EntityType Tests
    
    @Test("EntityType enumeration completeness")
    func testEntityTypeEnumeration() throws {
        let allTypes = TestDataCollections.allEntityTypes
        
        // Verify we have all expected types
        #expect(allTypes.contains(.article))
        #expect(allTypes.contains(.person))
        #expect(allTypes.contains(.organization))
        #expect(allTypes.contains(.location))
        #expect(allTypes.contains(.category))
        #expect(allTypes.contains(.source))
        #expect(allTypes.contains(.mediaItem))
        #expect(allTypes.contains(.newsEvent))
        
        // Test raw values are meaningful
        #expect(EntityType.article.rawValue == "articles")
        #expect(EntityType.person.rawValue == "persons")
        #expect(EntityType.organization.rawValue == "organizations")
        
        // Test singular names
        #expect(EntityType.article.singularName == "article")
        #expect(EntityType.person.singularName == "person")
        #expect(EntityType.organization.singularName == "organization")
    }
    
    @Test("EntityType Codable conformance")
    func testEntityTypeCodable() throws {
        for entityType in TestDataCollections.allEntityTypes {
            try TestUtilities.validateCodableConformance(entityType)
        }
        
        // Test specific encoding/decoding
        let originalType = EntityType.person
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalType)
        
        let decoder = JSONDecoder()
        let decodedType = try decoder.decode(EntityType.self, from: data)
        
        #expect(originalType == decodedType)
    }
    
    // MARK: - AssociatedData Protocol Tests
    
    @Test("AssociatedData embedding text generation")
    func testEmbeddingTextGeneration() throws {
        var person = TestUtilities.createSamplePerson()
        
        // Test with no relationships
        person.relationships = []
        let emptyRelationshipsText = person.toEmbeddingText()
        #expect(emptyRelationshipsText.contains(person.name))
        #expect(emptyRelationshipsText.contains(person.id))
        #expect(emptyRelationshipsText.contains("Person"))
        #expect(!emptyRelationshipsText.contains("relationship"))
        
        // Test with relationships
        person.relationships = [
            Relationship(targetId: "org-1", type: .organization, displayName: "Works at", context: "Senior Developer"),
            Relationship(targetId: "loc-1", type: .location, displayName: "Lives in", context: "Primary residence")
        ]
        
        let withRelationshipsText = person.toEmbeddingText()
        #expect(withRelationshipsText.contains("relationship"))
        #expect(withRelationshipsText.contains("Works at"))
        #expect(withRelationshipsText.contains("Lives in"))
        #expect(withRelationshipsText.contains("Senior Developer"))
        #expect(withRelationshipsText.contains("Primary residence"))
        #expect(withRelationshipsText.contains("org-1"))
        #expect(withRelationshipsText.contains("loc-1"))
    }
    
    @Test("AssociatedData with complex relationships")
    func testComplexRelationships() throws {
        var organization = TestUtilities.createSampleOrganization()
        
        // Add multiple relationships of different types
        organization.relationships = [
            Relationship(targetId: "person-1", type: .person, displayName: "CEO"),
            Relationship(targetId: "person-2", type: .person, displayName: "CTO"),
            Relationship(targetId: "location-1", type: .location, displayName: "Headquarters"),
            Relationship(targetId: "article-1", type: .article, displayName: "Featured in"),
            Relationship(targetId: "source-1", type: .source, displayName: "News source")
        ]
        
        let embeddingText = organization.toEmbeddingText()
        
        // Verify all relationships are included
        #expect(embeddingText.contains("CEO"))
        #expect(embeddingText.contains("CTO"))
        #expect(embeddingText.contains("Headquarters"))
        #expect(embeddingText.contains("Featured in"))
        #expect(embeddingText.contains("News source"))
        
        // Verify target IDs are included
        #expect(embeddingText.contains("person-1"))
        #expect(embeddingText.contains("person-2"))
        #expect(embeddingText.contains("location-1"))
        #expect(embeddingText.contains("article-1"))
        #expect(embeddingText.contains("source-1"))
        
        try TestUtilities.validateCodableConformance(organization)
    }
    
    // MARK: - BaseEntity Protocol Tests
    
    @Test("BaseEntity protocol conformance")
    func testBaseEntityConformance() throws {
        let entities: [any BaseEntity] = [
            TestUtilities.createSampleArticle(),
            TestUtilities.createSamplePerson(),
            TestUtilities.createSampleOrganization(),
            TestUtilities.createSampleLocation(),
            TestUtilities.createSampleSource(),
            TestUtilities.createSampleCategory(),
            TestUtilities.createSampleNewsEvent()
        ]
        
        for entity in entities {
            TestUtilities.validateBaseEntity(entity)
            
            // Test that all BaseEntity types are Identifiable
            #expect(!entity.id.isEmpty)
            
            // Test that all BaseEntity types have meaningful names
            #expect(!entity.name.isEmpty)
            #expect(entity.name.count > 1)
        }
    }
    
    @Test("BaseEntity identifier uniqueness")
    func testEntityIdentifierUniqueness() throws {
        let articles = (0..<100).map { _ in TestUtilities.createSampleArticle() }
        let ids = Set(articles.map(\.id))
        
        // All IDs should be unique
        #expect(ids.count == articles.count)
        
        // All IDs should be non-empty
        for id in ids {
            #expect(!id.isEmpty)
        }
    }
    
    // MARK: - Relationship Management Tests
    
    @Test("Adding and removing relationships")
    func testRelationshipManagement() throws {
        var article = TestUtilities.createSampleArticle()
        let originalRelationshipCount = article.relationships.count
        
        // Add a new relationship
        let newRelationship = Relationship(
            targetId: "new-target",
            type: .person,
            displayName: "Author"
        )
        
        article.relationships.append(newRelationship)
        #expect(article.relationships.count == originalRelationshipCount + 1)
        #expect(article.relationships.contains(newRelationship))
        
        // Remove the relationship
        article.relationships.removeAll { $0.id == newRelationship.id }
        #expect(article.relationships.count == originalRelationshipCount)
        #expect(!article.relationships.contains(newRelationship))
        
        try TestUtilities.validateCodableConformance(article)
    }
    
    @Test("Relationship circular references")
    func testCircularRelationships() throws {
        var person1 = TestUtilities.createSamplePerson(id: "person-1")
        var person2 = TestUtilities.createSamplePerson(id: "person-2")
        
        // Create bidirectional relationship
        let person1ToPerson2 = Relationship(
            targetId: person2.id,
            type: .person,
            displayName: "Colleague"
        )
        
        let person2ToPerson1 = Relationship(
            targetId: person1.id,
            type: .person,
            displayName: "Colleague"
        )
        
        person1.relationships = [person1ToPerson2]
        person2.relationships = [person2ToPerson1]
        
        // Both should generate valid embedding text despite circular reference
        let person1Text = person1.toEmbeddingText()
        let person2Text = person2.toEmbeddingText()
        
        #expect(person1Text.contains("person-2"))
        #expect(person2Text.contains("person-1"))
        #expect(person1Text.contains("Colleague"))
        #expect(person2Text.contains("Colleague"))
        
        try TestUtilities.validateCodableConformance(person1)
        try TestUtilities.validateCodableConformance(person2)
    }
    
    @Test("Relationship context handling")
    func testRelationshipContext() throws {
        let relationshipWithContext = Relationship(
            targetId: "target-1",
            type: .organization,
            displayName: "Works at",
            context: "Software Engineer position since 2020"
        )
        
        let relationshipWithoutContext = Relationship(
            targetId: "target-2",
            type: .location,
            displayName: "Lives in"
        )
        
        var person = TestUtilities.createSamplePerson()
        person.relationships = [relationshipWithContext, relationshipWithoutContext]
        
        let embeddingText = person.toEmbeddingText()
        
        #expect(embeddingText.contains("Software Engineer position since 2020"))
        #expect(embeddingText.contains("Works at"))
        #expect(embeddingText.contains("Lives in"))
        #expect(!embeddingText.contains("null"))
        
        try TestUtilities.validateCodableConformance(person)
    }
    
    // MARK: - RelationshipSource Tests
    
    @Test("RelationshipSource enumeration")
    func testRelationshipSource() throws {
        let sources: [RelationshipSource] = [.system, .userInput, .aiInference, .dataImport]
        
        for source in sources {
            try TestUtilities.validateCodableConformance(source)
            #expect(!source.rawValue.isEmpty)
        }
        
        #expect(RelationshipSource.system.rawValue == "system")
        #expect(RelationshipSource.userInput.rawValue == "user_input")
        #expect(RelationshipSource.aiInference.rawValue == "ai_inference")
        #expect(RelationshipSource.dataImport.rawValue == "data_import")
    }
    
    // MARK: - Edge Cases and Error Handling
    
    @Test("Empty relationship arrays")
    func testEmptyRelationshipArrays() throws {
        let entitiesWithEmptyRelationships: [any AssociatedData] = [
            Article(title: "Test", url: "https://example.com", relationships: []),
            Person(name: "Test Person", relationships: []),
            Organization(name: "Test Org", relationships: [])
        ]
        
        for entity in entitiesWithEmptyRelationships {
            #expect(entity.relationships.isEmpty)
            
            let embeddingText = entity.toEmbeddingText()
            #expect(!embeddingText.isEmpty)
            #expect(!embeddingText.contains("relationship"))
            
            TestUtilities.validateBaseEntity(entity)
            TestUtilities.validateAssociatedData(entity)
        }
    }
    
    @Test("Large relationship collections")
    func testLargeRelationshipCollections() throws {
        var organization = TestUtilities.createSampleOrganization()
        
        // Add many relationships
        organization.relationships = (0..<100).map { index in
            Relationship(
                targetId: "target-\(index)",
                type: EntityType.allCases.randomElement() ?? .person,
                displayName: "Relationship \(index)"
            )
        }
        
        #expect(organization.relationships.count == 100)
        
        let embeddingText = organization.toEmbeddingText()
        #expect(!embeddingText.isEmpty)
        #expect(embeddingText.contains("relationship"))
        
        // Should still be encodable/decodable
        try TestUtilities.validateCodableConformance(organization)
    }
    
    @Test("Relationship with special characters")
    func testRelationshipWithSpecialCharacters() throws {
        let relationship = Relationship(
            targetId: "target-with-special-chars-!@#$%",
            type: .person,
            displayName: "Special Relationship: \"quoted\" & escaped",
            context: "Context with émojis 🎉 and newlines\nand tabs\t"
        )
        
        try TestUtilities.validateCodableConformance(relationship)
        
        var person = TestUtilities.createSamplePerson()
        person.relationships = [relationship]
        
        let embeddingText = person.toEmbeddingText()
        #expect(embeddingText.contains("Special Relationship"))
        #expect(embeddingText.contains("Context with émojis"))
        
        try TestUtilities.validateCodableConformance(person)
    }
    
    @Test("AssociatedData type erasure")
    func testAssociatedDataTypeErasure() throws {
        let entities: [any AssociatedData] = TestDataCollections.sampleEntities
        
        for entity in entities {
            // Should work with type-erased entities
            TestUtilities.validateAssociatedData(entity)
            
            let embeddingText = entity.toEmbeddingText()
            #expect(!embeddingText.isEmpty)
            #expect(embeddingText.contains(entity.name))
            #expect(embeddingText.contains(entity.id))
        }
    }
}