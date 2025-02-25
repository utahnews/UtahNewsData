# UtahNewsData Swift Package

A comprehensive Swift package for managing news data with support for relational database export and Retrieval-Augmented Generation (RAG).

## Overview

UtahNewsData provides a rich set of data models for representing news entities such as articles, people, organizations, events, and more. It includes functionality for:

- Creating and managing relationships between entities
- Exporting data to relational databases
- Preparing data for vector embeddings and RAG systems
- Generating knowledge graphs
- Creating rich context for AI systems

## Installation

Add UtahNewsData to your Swift package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/UtahNewsData.git", from: "1.0.0")
]
```

## Core Concepts

### Entity Models

The package includes the following entity models:
- `CalEvent`
- `Category`
- `ConsolidatedModels`
- `ExpertAnalysis`
- `Fact`
- `Jurisdiction`
- `LegalDocument`
- `Location`
- `NewsAlert`
- `NewsEvent`
- `NewsStory`
- `Organization`
- `Person`
- `Poll`
- `Quote`
- `SocialMediaPost`
- `Source`
- `StatisticalData`
- `UserSubmission`

### Relationship Model

Entities can be connected through relationships using the `Relationship` struct:

```swift
public struct Relationship: Codable, Hashable {
    public let id: String                  // ID of the target entity
    public let type: AssociatedDataType    // Type of the target entity
    public var displayName: String?        // Human-readable relationship description
    public let createdAt: Date             // When the relationship was created
    public let confidence: Float           // Confidence score (0.0 to 1.0)
    public let context: String?            // Additional context about the relationship
    public let source: RelationshipSource  // Source of this relationship information
}
```

### RAG Utilities

The package includes utilities for Retrieval-Augmented Generation:

- Context generation for entities and relationships
- Vector record preparation for embedding
- Knowledge graph generation
- Combined context generation for multiple entities

### Data Export

Utilities for exporting data to relational databases:

- SQL statement generation for entities
- SQL statement generation for relationships
- Table schema generation

## Usage Examples

### Creating Entities and Relationships

```swift
// Create entities
let person = Person(
    name: "Jane Doe",
    details: "A reporter",
    occupation: "Journalist"
)

let organization = Organization(
    name: "Utah News Network",
    orgDescription: "A news organization"
)

// Create a relationship
let relationship = Relationship(
    id: organization.id,
    type: .organization,
    displayName: "Works at",
    context: "Jane has been working here since 2020",
    confidence: 0.95,
    source: .userInput
)

// Add the relationship to the person
var updatedPerson = person
updatedPerson.relationships.append(relationship)
```

### Generating Context for RAG

```swift
// Generate context for a single entity
let personContext = RAGUtilities.generateEntityContext(updatedPerson)

// Generate context for multiple entities
let combinedContext = RAGUtilities.generateCombinedContext([updatedPerson, organization])
```

### Preparing Data for Vector Embedding

```swift
// Generate vector records for entities
let vectorRecords = RAGUtilities.prepareEntitiesForEmbedding([updatedPerson, organization])
```

### Creating a Knowledge Graph

```swift
// Generate a knowledge graph
let graph = RAGUtilities.generateKnowledgeGraph([updatedPerson, organization])

// Export to JSON
let graphJSON = try graph.toJSON()
```

### Exporting to SQL

```swift
// Generate SQL for an entity
let personSQL = DataExporter.exportEntityToSQL(updatedPerson)

// Generate SQL for relationships
let relationshipSQL = DataExporter.exportRelationshipsToSQL(updatedPerson)
```

## Entity Types

The following entity types are supported in the `AssociatedDataType` enum:
- `.system`
- `.userInput`
- `.aiInference`
- `.dataImport`
- `.person`
- `.organization`
- `.location`
- `.category`
- `.source`
- `.mediaItem`
- `.newsEvent`
- `.newsStory`
- `.quote`
- `.fact`
- `.statisticalData`
- `.calendarEvent`
- `.legalDocument`
- `.socialMediaPost`
- `.expertAnalysis`
- `.poll`
- `.alert`
- `.jurisdiction`
- `.userSubmission`

## RAG Example

Here's a complete example of using the RAG utilities:

```swift    public static func prepareEntitiesForRAG() {
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
```

## Model Reference

This package includes the following models:
### Article

A struct representing an article in the news app.

### AssociatedData

public protocol AssociatedData {

### Audio

A struct representing an audio clip in the news app.

### CalEvent

public struct CalEvent: AssociatedData {

### Category

public struct Category: AssociatedData {

### ConsolidatedModels

//  A struct representing an article in the news app.

### ContactInfo

public struct ContactInfo: Codable, Identifiable, Hashable, Equatable {

### DataExporter

Utilities for exporting UtahNewsData models to various formats

### ExpertAnalysis

public struct ExpertAnalysis: AssociatedData {

### Extensions

Constructs a fully qualified URL using the base URL if needed.

### Fact

public struct Fact: AssociatedData, Codable {

### Jurisdiction

public enum JurisdictionType: String, Codable, CaseIterable {

### LegalDocument

public struct LegalDocument: AssociatedData {

### Location

// Summary: Defines the Location structure for the UtahNewsData module.

### MediaItem

//  Updated so each media struct defines custom `==` and `hash(into:)`

### NewsAlert

public struct NewsAlert: AssociatedData {

### NewsContent

A protocol defining the common properties and methods for news content types.

### NewsEvent

public struct NewsEvent: AssociatedData {

### NewsStory

public struct NewsStory: AssociatedData {

### Organization

public struct Organization: AssociatedData, Codable, Identifiable, Hashable, EntityDetailsProvider {

### Person

public struct Person: AssociatedData, Codable, Identifiable, Hashable, EntityDetailsProvider {

### Poll

public struct Poll: AssociatedData {

### Quote

public struct Quote: AssociatedData {

### RAGExample

It is not meant to be used in production, but rather as a reference.

### RAGUtilities

Utilities for working with RAG (Retrieval-Augmented Generation) systems

### ScrapeStory

public struct StoryExtract: Codable {

### SocialMediaPost

public struct SocialMediaPost: AssociatedData {

### Source

// By aligning the Source struct with the schema defined in NewsSource, you can decode

### StatisticalData

public struct StatisticalData: AssociatedData {

### UserSubmission

public struct UserSubmission: AssociatedData, Codable, Identifiable, Hashable {

### UtahNewsData

No description available.

### VIdeo

A struct representing a video in the news app.

## Consolidated Models

For a complete reference of all models, see the `ConsolidatedModels.swift` file which is generated by the `scripts/consolidate_models.sh` script.

## License

This package is available under the MIT license.