import Foundation
import os
import UtahNewsData

/// A script to import sources from the sourcesUpdated.json file
/// This demonstrates loading the sources and using them in the application
@main
struct ImportSources {
        private static let logger = Logger(subsystem: "com.utahnews.data", category: "ImportSources")
        static func main() {
                logger.info("Starting source import...")

                // Demo converting JSON to array of Source objects
                logger.info("=== PART 1: Direct JSON Conversion ===")
                convertJSONToSources()

                // Demo using the ConvertedSources static variable
                logger.info("=== PART 2: Using ConvertedSources ===")
                DemoConvertedSources.main()
        }

        static func convertJSONToSources() {
                // Get the current directory path
                let currentDirectoryPath = FileManager.default.currentDirectoryPath

                // Create the full path to the JSON file
                let jsonFilePath = "\(currentDirectoryPath)/sourcesUpdated.json"
                logger.debug("Looking for JSON file at: \(jsonFilePath, privacy: .public)")

                // Check if the file exists
                guard FileManager.default.fileExists(atPath: jsonFilePath) else {
                        fatalError(
                                "Error: sourcesUpdated.json file not found at path: \(jsonFilePath)"
                        )
                }

                // Load the sources from the JSON file
                guard let sources = SourcesConverter.loadSourcesFromFile(filePath: jsonFilePath)
                else {
                        fatalError("Error: Failed to convert JSON to sources")
                }

                // Log information about the imported sources
                logger.info("Successfully imported \(sources.count, privacy: .public) sources")

                // Log sample of the first 5 sources
                for (index, source) in sources.prefix(5).enumerated() {
                        logger.info("--- Source \(index + 1, privacy: .public) ---")
                        logger.info("ID: \(source.id, privacy: .public)")
                        logger.info("Name: \(source.name, privacy: .public)")
                        logger.info("URL: \(source.url, privacy: .public)")
                        logger.info("Category: \(source.category ?? "None", privacy: .public)")

                        if !source.relationships.isEmpty {
                                logger.info("Relationships:")
                                for relationship in source.relationships {
                                        logger.info(
                                                "  - \(relationship.displayName ?? "Unnamed", privacy: .public) (\(relationship.type.rawValue, privacy: .public)) - \(relationship.targetId, privacy: .public)"
                                        )
                                }
                        }
                }

                logger.info("Direct import complete!")
        }
}
