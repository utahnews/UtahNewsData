import Foundation
import UtahNewsData

/// A demo application to test the ConvertedSources functionality
struct DemoConvertedSources {
        static func main() {
                print("Testing ConvertedSources...")

                // Access the static array of sources
                let sources = ConvertedSources.allSources
                print("Total sources: \(sources.count)")

                // Get sources by category
                let educationSources = ConvertedSources.sources(withCategory: "education")
                print("Education sources: \(educationSources.count)")

                let governmentSources = ConvertedSources.sources(
                        withCategory: "localGovernmentAndPolitics")
                print("Government sources: \(governmentSources.count)")

                // Get a specific source by ID
                if let source = ConvertedSources.source(
                        withID: "005AEAD3-397C-4BCA-B02B-D5D49A755BEA")
                {
                        print("\nFound source by ID:")
                        print("Name: \(source.name)")
                        print("URL: \(source.url)")
                        print("Category: \(source.category ?? "None")")
                }

                // Print the first few sources in different categories
                if !educationSources.isEmpty {
                        let sample = educationSources[0]
                        print("\nSample Education Source:")
                        print("Name: \(sample.name)")
                        print("URL: \(sample.url)")
                }

                if !governmentSources.isEmpty {
                        let sample = governmentSources[0]
                        print("\nSample Government Source:")
                        print("Name: \(sample.name)")
                        print("URL: \(sample.url)")
                }

                print("\nTest complete!")
        }
}
