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

- **MediaItem**: A unified model for all media content (replacing older media-specific types)
- **Person**: Individuals relevant to news stories
- **Organization**: Companies, government agencies, and other groups
- **Event**: Occurrences with time, location, and participants
- **Location**: Geographic places and venues
- **Topic**: Subject matter categories and themes

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

### Unified Media Model

The package now uses a unified `MediaItem` model for all media content types:

```swift
public struct MediaItem: NewsContent, AssociatedData {
    public var id: String
    public var title: String
    public var type: MediaType
    public var url: String
    public var textContent: String?
    public var author: String?
    public var publishedAt: Date
    public var relationships: [Relationship]
    // Additional properties for specific media types...
}
```

This replaces the previously separate models for different media types, providing a more consistent API while maintaining backward compatibility through deprecation warnings.

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

### Creating Media Items

```swift
// Create an article as a MediaItem
let article = MediaItem(
    title: "Utah Legislature Passes New Water Conservation Bill",
    type: .text,
    url: "https://www.utahnews.com/articles/water-conservation-bill",
    textContent: "The Utah Legislature passed a new bill today...",
    author: "Jane Smith",
    publishedAt: Date(),
    relationships: []
)

// Create an image as a MediaItem
let image = MediaItem(
    title: "Downtown Salt Lake City Skyline",
    type: .image,
    url: "https://example.com/images/slc-skyline.jpg",
    caption: "View of downtown Salt Lake City with mountains in background",
    publishedAt: Date(),
    relationships: []
)
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
let graph = KnowledgeGraph(entities: [updatedPerson, organization])

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

## Migration Guide

### From Legacy Media Types to MediaItem

The package has deprecated individual media type models in favor of the unified `MediaItem` model:

1. **Deprecated Types**: `Article`, `Image`, `Video`, `Audio`, and `Document` are now marked as deprecated
2. **Migration Path**: Use the `toMediaItem()` method on deprecated types to convert to the new model
3. **Backward Compatibility**: Deprecated types will continue to work but will show compiler warnings

Example migration:

```swift
// Old way (deprecated)
let article = Article(
    title: "News Story",
    url: "https://example.com/story",
    publishedAt: Date()
)

// New way (recommended)
let mediaItem = MediaItem(
    title: "News Story",
    type: .text,
    url: "https://example.com/story",
    publishedAt: Date(),
    relationships: []
)

// Or convert from deprecated type
let convertedItem = article.toMediaItem()
```

## Model Reference

For a complete reference of all models, see the `ConsolidatedModels.swift` file which is generated by the `scripts/consolidate_models.sh` script.

## License

This package is available under the MIT license.