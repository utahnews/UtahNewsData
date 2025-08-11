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
    .package(url: "https://github.com/utahnews/UtahNewsData.git", branch: "feature/utahnewsdata-model-sync-2025-08-11")
]
```

## Core Concepts
## Platforms and Swift version

- iOS 18+, macOS 15+, tvOS 18+, watchOS 11+
- Swift 6 with Strict Concurrency enabled

## Modules and usage

This package exposes two libraries:

- `UtahNewsDataModels`: Lightweight, pure data models intended for broad reuse across apps. Prefer importing this in client apps and shared code.
- `UtahNewsData`: Higher-level utilities (HTML parsing, RAG helpers, exporters). Import this only where those utilities are needed. Some entity types are also defined here for parsing workflows.

To avoid ambiguous type names when both modules are imported, qualify with the module name. Recommended patterns:

```swift
import UtahNewsDataModels
// Prefer using model types from UtahNewsDataModels in UI and storage layers
let article: UtahNewsDataModels.Article = .init(title: "...", url: "...")

// Import UtahNewsData only where needed for utilities
import UtahNewsData
let context = RAGUtilities.generateCombinedContext([article])
```

Note: If a file does not require utilities, import only `UtahNewsDataModels` to eliminate symbol ambiguity.


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

Shared DateFormatter instances for use across the codebase

### ExpertAnalysis+HTMLParsable

// Validate that the document has a proper structure

### ExpertAnalysis

Represents an expert's analysis or commentary on a topic or news event.

### Extensions

- URL construction and validation

### Fact+HTMLParsable

// Validate that the document has a proper structure

### Fact

Represents the verification status of a fact

### HTMLParsable

//  Summary: Defines the HTMLParsable protocol for parsing HTML content into domain models.

### JSONSchemaProvider

//  Summary: Defines a protocol for types that provide a JSON schema for instructing an LLM

### Jurisdiction+HTMLParsable

No description available.

### Jurisdiction

Represents the type of governmental jurisdiction.

### LLMConfiguration

//  Summary: Defines the configuration protocol for LLM settings and related types.

### LegalDocument+HTMLParsable

// Validate that the document has a proper structure

### LegalDocument

Represents different types of legal documents

### LocalLLMManager

A manager class for handling interactions with a local LLM

### Location+HTMLParsable

No description available.

### Location

//           Also includes the Coordinates struct with JSON schema updates.

### MediaItem

The unified media representation used throughout the package.

• All legacy helpers (`ImageMedia`, `VideoMedia`, `AudioMedia`, `DocumentMedia`, `TextMedia`) were **removed in v1.2** – migrate to `MediaItem` directly.

• Uses **String** for `id`.

• Supports every media type via the `MediaType` enum (image, video, audio, document, text, other).

### NetworkClient

A client for fetching HTML content from URLs

### NewsAlert+HTMLParsable

// Validate that the document has a proper structure

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

### Organization+HTMLParsable

// Validate that the document has a proper structure

### Organization

Represents the type of organization

### ParsingError

Represents errors that can occur during HTML parsing

### ParsingResult

The source of the parsed content

### Person+HTMLParsable

throw ParsingError.invalidFormat("Invalid HTML document structure")

### Person

Represents an educational qualification or degree

### Poll+HTMLParsable

private struct InternalPollOption {

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

### SocialMediaPost+HTMLParsable

private struct Engagement {

### SocialMediaPost

Represents different social media platforms

### Source+HTMLParsable

No description available.

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

# Utah News Data - Source JSON Converter

This project provides code to convert a JSON file of news sources (`sourcesUpdated.json`) into Swift `Source` objects that can be used within the UtahNewsData system.

## Files

- **SourcesJSONConverter.swift**: Contains the logic to convert JSON data to Source objects
- **ImportSources.swift**: A sample application that demonstrates how to use the converter
- **sourcesUpdated.json**: The source data file containing information about news sources

## How to Use

1. Make sure the `sourcesUpdated.json` file is in the same directory as the executable
2. Run the `ImportSources` application to load and display the sources
3. The converter can also be used in other applications by importing the `SourcesConverter` class

### Example Usage

```swift
// Load sources from a specific file path
let sources = SourcesConverter.loadSourcesFromFile(filePath: "/path/to/sourcesUpdated.json")

// Or convert from existing JSON data
let jsonData = try Data(contentsOf: jsonFileURL)
let sources = try SourcesConverter.convertJSONToSources(jsonData: jsonData)

// Use the sources in your application
for source in sources {
    print("Source: \(source.name)")
    // ... work with the source
}
```

## Structure Details

The `sourcesUpdated.json` file has a specific structure that includes:

- Basic source information (id, name, url, category)
- Sitemap URL information for web scraping
- Relationships with other entities
- A `__collections__` field which is typically empty but is handled by the converter

The converter creates proper `Source` objects that match the UtahNewsData model, including converting relationships to the correct format.

## Requirements

- Swift 5.0+
- UtahNewsData package
- Foundation framework