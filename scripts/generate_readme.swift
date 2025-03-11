#!/usr/bin/env swift

import Foundation

// MARK: - Configuration
let outputPath = "../README.md"
let sourceDir = "Sources/UtahNewsData"
let consolidatedModelsPath = "\(sourceDir)/ConsolidatedModels.swift"

// MARK: - Utility Functions
func readFile(at path: String) -> String? {
    try? String(contentsOfFile: path, encoding: .utf8)
}

func writeFile(content: String, to path: String) -> Bool {
    do {
        try content.write(toFile: path, atomically: true, encoding: .utf8)
        return true
    } catch {
        print("Error writing to \(path): \(error)")
        return false
    }
}

func listFiles(in directory: String, withExtension ext: String) -> [String] {
    let fileManager = FileManager.default
    guard let files = try? fileManager.contentsOfDirectory(atPath: directory) else {
        return []
    }
    return files.filter { $0.hasSuffix(ext) }.sorted()
}

// MARK: - README Generation
func generateReadme() -> String {
    var readme = """
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

        """

    // List all entity models
    let swiftFiles = listFiles(in: sourceDir, withExtension: ".swift")
    let entityFiles = swiftFiles.filter {
        let content = readFile(at: "\(sourceDir)/\($0)") ?? ""
        return content.contains("AssociatedData") && !$0.contains("AssociatedData.swift")
            && !$0.contains("RAG") && !$0.contains("DataExporter")
    }

    for file in entityFiles {
        let entityName = file.replacingOccurrences(of: ".swift", with: "")
        readme += "- `\(entityName)`\n"
    }

    readme += """

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

        """

    // Extract AssociatedDataType enum cases
    if let associatedDataContent = readFile(at: "\(sourceDir)/AssociatedData.swift") {
        let pattern = #"case\s+(\w+)\s*=\s*"([^"]+)""#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsString = associatedDataContent as NSString
        let matches =
            regex?.matches(
                in: associatedDataContent, options: [],
                range: NSRange(location: 0, length: nsString.length)) ?? []

        for match in matches {
            if match.numberOfRanges >= 2 {
                let caseNameRange = match.range(at: 1)
                let caseName = nsString.substring(with: caseNameRange)
                readme += "- `.\(caseName)`\n"
            }
        }
    }

    readme += """

        ## RAG Example

        Here's a complete example of using the RAG utilities:

        ```swift
        """

    // Include RAGExample.swift content
    if let ragExampleContent = readFile(at: "\(sourceDir)/RAGExample.swift") {
        let lines = ragExampleContent.components(separatedBy: .newlines)
        var inFunction = false

        for line in lines {
            if line.contains("func prepareEntitiesForRAG()") {
                inFunction = true
                readme += line + "\n"
                continue
            }

            if inFunction {
                if line.contains("}") && !line.contains("{")
                    && line.trimmingCharacters(in: .whitespacesAndNewlines) == "}"
                {
                    readme += line + "\n"
                    break
                }
                readme += line + "\n"
            }
        }
    }

    readme += """
        ```
        ## Model Reference

        This package includes the following models:

        """

    // Add JSONSchemaProvider section
    readme += """

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

        """

    // List all Swift files with brief descriptions
    for file in swiftFiles.sorted() {
        let fileName = file.replacingOccurrences(of: ".swift", with: "")
        let filePath = "\(sourceDir)/\(file)"

        if let content = readFile(at: filePath) {
            let lines = content.components(separatedBy: .newlines)
            var description = "No description available."

            // Try to extract a description from comments or struct/class definition
            for line in lines {
                if line.contains("///") && !line.contains("example") {
                    description = line.replacingOccurrences(of: "///", with: "").trimmingCharacters(
                        in: .whitespacesAndNewlines)
                    break
                }

                if line.contains("struct") || line.contains("class") || line.contains("protocol")
                    || line.contains("enum")
                {
                    if description == "No description available." {
                        description = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    break
                }
            }

            readme += "### \(fileName)\n\n\(description)\n\n"
        }
    }

    readme += """
        ## Consolidated Models

        For a complete reference of all models, see the `ConsolidatedModels.swift` file which is generated by the `scripts/consolidate_models.sh` script.

        ## License

        This package is available under the MIT license.
        """

    return readme
}

// MARK: - Main Execution
let readme = generateReadme()
if writeFile(content: readme, to: outputPath) {
    print("README.md successfully generated!")
} else {
    print("Failed to generate README.md")
}
