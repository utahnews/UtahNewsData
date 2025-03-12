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
- `Article`
- `CalEvent`
- `Category`
- `ConsolidatedModels`
- `ExpertAnalysis`
- `Fact`
- `Jurisdiction`
- `LegalDocument`
- `Location`
- `MediaItem`
- `NewsAlert`
- `NewsEvent`
- `NewsStory`
- `Organization`
- `Person`
- `Poll`
- `SocialMediaPost`
- `Source`
- `StatisticalData`
- `UserSubmission`
- `UtahNewsData`

### Relationship Model

Entities can be connected through relationships using the `Relationship` struct:

```swift
public struct Relationship: BaseEntity, Codable, Hashable {
    public var id: String                  // Unique identifier for the relationship
    public var name: String                // Name or description of the relationship
    public let targetId: String            // ID of the target entity
    public let type: EntityType            // Type of the target entity
    public var displayName: String?        // Human-readable relationship description
    public let createdAt: Date             // When the relationship was created
    public var context: String?            // Additional context about the relationship
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
    context: "Jane has been working here since 2020"
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
        // MARK: - Create Example Entities
        
        // Create a Person entity with detailed information
        let person = Person(
            name: "Jane Doe",
            details: "A fictional person used for demonstration purposes.",
            biography: "Jane Doe is a software engineer with 10 years of experience in Swift development.",
            occupation: "Software Engineer",
            nationality: "American",
            notableAchievements: ["Developed the UtahNewsData framework", "Published 3 books on Swift"]
        )
        
        // Create an Organization entity
        let organization = Organization(
            name: "Utah News Network",
            orgDescription: "A fictional news organization covering Utah news.",
            website: "https://www.utahnewsnetwork.example"
        )
        
        // MARK: - Create Relationships
        
        // Create a relationship from Person to Organization
        // Note the use of context and display name
        let personToOrgRelationship = Relationship(
            id: organization.id,
            type: .organization,
            displayName: "Works at",
            context: "Jane Doe has been working at Utah News Network since 2020."
        )
        
        // Create a relationship from Organization to Person
        // This establishes a bidirectional relationship
        let orgToPersonRelationship = Relationship(
            id: person.id,
            type: .person,
            displayName: "Employs",
            context: "Utah News Network employs Jane Doe as a senior reporter."
        )
        
        // Add relationships to entities
        // Note: We create new instances because the entities are immutable
        var updatedPerson = person
        updatedPerson.relationships.append(personToOrgRelationship)
        
        var updatedOrg = organization
        updatedOrg.relationships.append(orgToPersonRelationship)
        
        // MARK: - Generate RAG Context
        
        // Generate context for multiple entities
        // This combines context from multiple entities into a single document
        let personContext = RAGUtilities.generateCombinedContext([updatedPerson])
        let orgContext = RAGUtilities.generateCombinedContext([updatedOrg])
        let combinedContext = personContext + "\n\n" + orgContext
        print("Combined Context:\n\(combinedContext)\n")
        
        // Generate vector records for entities
        // These records can be sent to an embedding service and stored in a vector database
        let personVectorRecords = RAGUtilities.prepareEntitiesForEmbedding([updatedPerson])
        let orgVectorRecords = RAGUtilities.prepareEntitiesForEmbedding([updatedOrg])
        let vectorRecords = personVectorRecords + orgVectorRecords
        print("Generated \(vectorRecords.count) vector records")
        
        // Create a knowledge graph from entities
        // This builds a graph representation with nodes (entities) and edges (relationships)
        let personGraph = RAGUtilities.generateKnowledgeGraph([updatedPerson])
        let orgGraph = RAGUtilities.generateKnowledgeGraph([updatedOrg])
        // Combine the graphs
        var graph = KnowledgeGraph()
        graph.nodes = personGraph.nodes + orgGraph.nodes
        graph.edges = personGraph.edges + orgGraph.edges
        
        print("Knowledge Graph: \(graph.nodes.count) nodes, \(graph.edges.count) edges")
        
        // Export the graph to JSON
        // This can be used for visualization or import into a graph database
        do {
            let graphJSON = try graph.toJSON()
            print("Knowledge Graph JSON (excerpt):")
            let excerpt = String(graphJSON.prefix(200))
            print("\(excerpt)...")
        } catch {
            print("Error generating graph JSON: \(error)")
        }
```
## Model Reference

This package includes the following models:

### JSON Schema Generation

Most models in this package conform to `JSONSchemaProvider`, enabling automatic JSON schema generation for LLM interactions:

```swift
// Example of accessing a model's JSON schema
let schema = StatisticalData.jsonSchema

// Use this schema to instruct LLMs how to generate valid JSON
// for creating or updating StatisticalData instances
```

The JSON schemas define:
- Required and optional properties
- Property types and formats
- Nested object structures
- Array specifications
- Validation rules
### AdaptiveParser

//  Summary: Provides an adaptive HTML parser that can learn and adjust to different website structures.

### Article+HTMLParsable

// Validate that the document has a proper structure

### Article

A struct representing an article in the news app.

### AssociatedData

This file defines the core protocols and relationship model for the UtahNewsData package.

### Audio+HTMLParsable

// Validate that the document has a proper structure

### Audio

public struct Audio: NewsContent, BaseEntity, JSONSchemaProvider, Sendable {

### CalEvent

Represents a recurrence rule for repeating calendar events

### Category

Categories provide a way to organize and classify content such as articles, media items, and other

### ConsolidatedModels

//  A struct representing an article in the news app.

### ContactInfo

Represents contact information for entities in the news data system.

### ContentExtractionService

A service that loads HTML from a URL and maps it to a Swift object conforming to HTMLParsable.

### ContentValidator

A utility class for validating content based on its type

### DataExporter

The DataExporter class provides static methods that can be used with any entity

### DateFormatters

Extension providing standard date formatters for use across the app

### ExpertAnalysis

Represents an expert's analysis or commentary on a topic or news event.

### Extensions

- URL construction and validation

### Fact

Represents the verification status of a fact

### HTMLParsable

//  Summary: Defines the HTMLParsable protocol for parsing HTML content into domain models.

### JSONSchemaProvider

//  Summary: Defines a protocol for types that provide a JSON schema for instructing an LLM

### Jurisdiction

Represents the type of governmental jurisdiction.

### LLMConfiguration

//  Summary: Defines the configuration protocol for LLM settings and related types.

### LegalDocument

Represents a legal document or official record in the news system.

### LocalLLMManager

A manager class for handling interactions with a local LLM

### Location

//           Also includes the Coordinates struct with JSON schema updates.

### MediaItem

2. Media type classification (image, video, audio, document)

### NetworkClient

A client for fetching HTML content from URLs

### NewsAlert

Represents a time-sensitive alert or notification in the news system.

### NewsContent

This file defines the NewsContent protocol, which serves as the foundation for

### NewsEvent

statement: "The proposed state budget includes $200 million for water infrastructure."

### NewsStory+HTMLParsable

// Validate that the document has a proper structure

### NewsStory

Represents a complete news story in the news system.

### Organization

Represents an organization in the UtahNewsData system

### ParsingError

Errors that can occur during parsing

### ParsingResult

The source of the parsed content

### Person

Represents a person in the news data system.

### Poll

Represents an option in a poll that users can vote for.

### Quote

text: "We're committed to improving Utah's water infrastructure.",

### RAGExample

It is not meant to be used in production, but rather as a reference.

### RAGUtilities

The RAGUtilities class provides static methods that can be used with any entity

### ScrapeStory

This file defines the ScrapeStory model and related response structures used for

### SelectorDiscovery

A utility class for discovering CSS selectors in HTML documents

### SocialMediaPost

Represents a social media post in the news system.

### Source

// By aligning the Source struct with the schema defined in NewsSource, you can decode

### StatisticalData+HTMLParsable

// Validate that the document has a proper structure

### StatisticalData

Represents the type of visualization suitable for the statistical data

### UserSubmission

Represents content submitted by users to the news system.

### UtahNewsData

- Relationship System: AssociatedData protocol and Relationship struct

### VIdeo

system. The Video struct implements the NewsContent protocol, providing a consistent

### Video+HTMLParsable

// Validate that the document has a proper structure

### WebPageLoader

public final class WebPageLoader: @unchecked Sendable {

## Consolidated Models

For a complete reference of all models, see the `ConsolidatedModels.swift` file which is generated by the `scripts/consolidate_models.sh` script.

## License

This package is available under the MIT license.