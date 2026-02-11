import Foundation
import os

/// Provides centralized access to the source data converted from sourcesUpdated.json
public enum ConvertedSources {
        private static let logger = Logger(subsystem: "com.utahnews.data", category: "ConvertedSources")
        /// The static array of all sources from the sourcesUpdated.json file
        public static let allSources: [Source] = {
                // Get the path to the JSON file
                guard
                        let fileURL = Bundle.module.url(
                                forResource: "sourcesUpdated", withExtension: "json")
                else {
                        logger.error("sourcesUpdated.json file not found in bundle")
                        return []
                }

                do {
                        // Read the file data
                        let data = try Data(contentsOf: fileURL)

                        // Use a JSONDecoder to decode the data
                        let decoder = JSONDecoder()

                        // Decode the structure directly to preserve all relevant fields
                        struct SourceJSON: Codable {
                                var id: String
                                var name: String
                                var url: String
                                var category: String?
                                var siteMapURL: String?
                                var relationships: [RelationshipJSON]?

                                enum CodingKeys: String, CodingKey {
                                        case id, name, url, category, siteMapURL, relationships
                                }
                        }

                        struct RelationshipJSON: Codable {
                                var id: String
                                var type: String
                                var displayName: String?
                        }

                        // Decode the JSON array
                        let sourcesJSON = try decoder.decode([SourceJSON].self, from: data)

                        // Convert to Source objects
                        let sources = sourcesJSON.map { jsonSource -> Source in
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
                                                Relationship(
                                                        id: relationship.id,
                                                        type: EntityType(
                                                                rawValue: relationship.type)
                                                                ?? .source,
                                                        displayName: relationship.displayName
                                                )
                                        }
                                }

                                return source
                        }

                        return sources
                } catch {
                        logger.error("Failed to load sources from JSON: \(error.localizedDescription)")
                        return []
                }
        }()

        /// Get sources filtered by category
        public static func sources(withCategory category: String) -> [Source] {
                return allSources.filter { $0.category == category }
        }

        /// Get a specific source by ID
        public static func source(withID id: String) -> Source? {
                return allSources.first { $0.id == id }
        }
}
