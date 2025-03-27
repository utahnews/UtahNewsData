import Foundation
import UtahNewsData

/// A script to import sources from the sourcesUpdated.json file
/// This demonstrates loading the sources and using them in the application
@main
struct ImportSources {
        static func main() {
                print("Starting source import...")

                // Demo converting JSON to array of Source objects
                print("\n=== PART 1: Direct JSON Conversion ===\n")
                convertJSONToSources()

                // Demo using the ConvertedSources static variable
                print("\n=== PART 2: Using ConvertedSources ===\n")
                DemoConvertedSources.main()
        }

        static func convertJSONToSources() {
                // Get the current directory path
                let currentDirectoryPath = FileManager.default.currentDirectoryPath

                // Create the full path to the JSON file
                let jsonFilePath = "\(currentDirectoryPath)/sourcesUpdated.json"
                print("Looking for JSON file at: \(jsonFilePath)")

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

                // Print information about the imported sources
                print("Successfully imported \(sources.count) sources")

                // Print sample of the first 5 sources
                for (index, source) in sources.prefix(5).enumerated() {
                        print("\n--- Source \(index + 1) ---")
                        print("ID: \(source.id)")
                        print("Name: \(source.name)")
                        print("URL: \(source.url)")
                        print("Category: \(source.category ?? "None")")

                        if !source.relationships.isEmpty {
                                print("Relationships:")
                                for relationship in source.relationships {
                                        print(
                                                "  - \(relationship.displayName ?? "Unnamed") (\(relationship.type.rawValue)) - \(relationship.targetId)"
                                        )
                                }
                        }
                }

                print("\nDirect import complete!")
        }
}
