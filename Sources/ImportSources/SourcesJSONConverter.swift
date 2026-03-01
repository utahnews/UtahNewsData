import Foundation
import os
import UtahNewsData

/// This struct represents the JSON structure in sourcesUpdated.json
struct SourceJSON: Codable {
        var id: String
        var name: String
        var url: String
        var category: String?
        var siteMapURL: String?
        var relationships: [RelationshipJSON]?
        // The __collections__ field is a dictionary that can be empty or contain nested dictionaries
        // Instead of trying to decode it as a complex structure, we'll just ignore it

        enum CodingKeys: String, CodingKey {
                case id, name, url, category, siteMapURL, relationships
                // __collections__ is intentionally not included here
        }
}

/// This struct represents the relationship JSON structure in sourcesUpdated.json
struct RelationshipJSON: Codable {
        var id: String
        var type: String
        var displayName: String?
}

/// A class to handle the conversion from JSON to Source objects
class SourcesConverter {
        private static let logger = Logger(subsystem: "com.utahnews.data", category: "SourcesConverter")
        /// Converts the JSON file content into an array of Source objects
        /// - Parameter jsonData: The JSON data from sourcesUpdated.json
        /// - Returns: An array of Source objects
        static func convertJSONToSources(jsonData: Data) throws -> [Source] {
                let decoder = JSONDecoder()
                let sourcesJSON = try decoder.decode([SourceJSON].self, from: jsonData)

                // Convert the JSON objects to Source objects
                return sourcesJSON.map { jsonSource -> Source in
                        // Create a new Source object with basic properties
                        var source = Source(
                                id: jsonSource.id,
                                name: jsonSource.name,
                                url: jsonSource.url,
                                category: jsonSource.category
                        )

                        // Set the siteMapURL if present
                        if let siteMapURLString = jsonSource.siteMapURL,
                                let siteMapURL = URL(string: siteMapURLString)
                        {
                                source.siteMapURL = siteMapURL
                        }

                        // Convert relationships if present
                        if let jsonRelationships = jsonSource.relationships {
                                source.relationships = jsonRelationships.map {
                                        relationship -> Relationship in
                                        // Create a relationship with the ID as the targetId
                                        Relationship(
                                                id: relationship.id,
                                                type: EntityType(rawValue: relationship.type)
                                                        ?? .source,
                                                displayName: relationship.displayName
                                        )
                                }
                        }

                        return source
                }
        }

        /// Loads the sourcesUpdated.json file directly from the file path
        /// - Parameter filePath: Path to the JSON file
        /// - Returns: An array of Source objects
        static func loadSourcesFromFile(filePath: String) -> [Source]? {
                let fileURL = URL(fileURLWithPath: filePath)

                do {
                        let data = try Data(contentsOf: fileURL)
                        let sources = try convertJSONToSources(jsonData: data)
                        return sources
                } catch {
                        Self.logger.error("Error converting JSON to sources: \(error, privacy: .public)")
                        return nil
                }
        }
}

// Example usage:
// let sources = SourcesConverter.loadSourcesFromFile(filePath: "path/to/sourcesUpdated.json")
// if let sources = sources {
//     print("Successfully loaded \(sources.count) sources")
// } else {
//     print("Failed to load sources")
// }
