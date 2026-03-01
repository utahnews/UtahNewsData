import Foundation
import os
import UtahNewsData

/// A demo application to test the ConvertedSources functionality
struct DemoConvertedSources {
        private static let logger = Logger(subsystem: "com.utahnews.data", category: "DemoConvertedSources")
        static func main() {
                logger.info("Testing ConvertedSources...")

                // Access the static array of sources
                let sources = ConvertedSources.allSources
                logger.info("Total sources: \(sources.count, privacy: .public)")

                // Get sources by category
                let educationSources = ConvertedSources.sources(withCategory: "education")
                logger.info("Education sources: \(educationSources.count, privacy: .public)")

                let governmentSources = ConvertedSources.sources(
                        withCategory: "localGovernmentAndPolitics")
                logger.info("Government sources: \(governmentSources.count, privacy: .public)")

                // Get a specific source by ID
                if let source = ConvertedSources.source(
                        withID: "005AEAD3-397C-4BCA-B02B-D5D49A755BEA")
                {
                        logger.info("Found source by ID:")
                        logger.info("Name: \(source.name, privacy: .public)")
                        logger.info("URL: \(source.url, privacy: .public)")
                        logger.info("Category: \(source.category ?? "None", privacy: .public)")
                }

                // Print the first few sources in different categories
                if !educationSources.isEmpty {
                        let sample = educationSources[0]
                        logger.info("Sample Education Source:")
                        logger.info("Name: \(sample.name, privacy: .public)")
                        logger.info("URL: \(sample.url, privacy: .public)")
                }

                if !governmentSources.isEmpty {
                        let sample = governmentSources[0]
                        logger.info("Sample Government Source:")
                        logger.info("Name: \(sample.name, privacy: .public)")
                        logger.info("URL: \(sample.url, privacy: .public)")
                }

                logger.info("Test complete!")
        }
}
