import Foundation
import SwiftSoup

extension Fact: HTMLParsable {
    public static func parse(from document: Document) throws -> Fact {
        // Validate that the document has a proper structure
        guard try !document.select("body").isEmpty(),
              try !document.select("head").isEmpty() else {
            throw ParsingError.invalidFormat("Invalid HTML document structure")
        }
        
        // Extract required fields
        let statement = try extractStatement(from: document)
        let verificationStatus = try extractVerificationStatus(from: document)
        let confidenceLevel = try extractConfidenceLevel(from: document)
        
        // Extract optional fields
        let sources = try extractSources(from: document)
        
        // Create and return the Fact
        return Fact(
            statement: statement,
            sources: sources,
            verificationStatus: verificationStatus,
            confidenceLevel: confidenceLevel,
            date: Date(),
            categoryId: nil,
            relatedEntities: []
        )
    }
    
    // MARK: - Private Helper Methods
    
    private static func extractStatement(from document: Document) throws -> String {
        let statementSelectors = [
            "[itemprop='claimReviewed']",
            ".fact-statement",
            ".claim-text",
            "meta[property='fact:statement']"
        ]
        
        for selector in statementSelectors {
            if selector.contains("meta") {
                if let statement = try document.select(selector).first()?.attr("content"),
                   !statement.isEmpty {
                    return statement
                }
            } else {
                if let statement = try document.select(selector).first()?.text(),
                   !statement.isEmpty {
                    return statement
                }
            }
        }
        
        throw ParsingError.missingRequiredField("statement")
    }
    
    private static func extractVerificationStatus(from document: Document) throws -> VerificationStatus {
        let statusSelectors = [
            "[itemprop='reviewRating']",
            ".verification-status",
            ".fact-status",
            ".rating"
        ]
        
        for selector in statusSelectors {
            if let statusText = try document.select(selector).first()?.text() {
                // Try to match status text with VerificationStatus cases
                let normalizedStatus = statusText.trimmingCharacters(in: .whitespaces).lowercased()
                
                switch normalizedStatus {
                case let text where text.contains("true"):
                    return .verified
                case let text where text.contains("false"):
                    return .disputed
                case let text where text.contains("misleading"):
                    return .disputed
                case let text where text.contains("unverified"):
                    return .unverified
                case let text where text.contains("partially"):
                    return .disputed
                default:
                    continue
                }
            }
        }
        
        return .unverified // Default status if none found
    }
    
    private static func extractConfidenceLevel(from document: Document) throws -> ConfidenceLevel {
        let confidenceSelectors = [
            "[itemprop='confidenceLevel']",
            ".confidence-rating",
            ".certainty-level"
        ]
        
        for selector in confidenceSelectors {
            if let confidenceText = try document.select(selector).first()?.text() {
                let normalizedText = confidenceText.trimmingCharacters(in: .whitespaces).lowercased()
                
                // Try direct match
                if let confidence = ConfidenceLevel(rawValue: normalizedText) {
                    return confidence
                }
                
                // Try matching based on keywords
                switch normalizedText {
                case let text where text.contains("high"):
                    return .high
                case let text where text.contains("medium"):
                    return .medium
                case let text where text.contains("low"):
                    return .low
                default:
                    continue
                }
            }
        }
        
        return .medium // Default confidence level if none found
    }
    
    private static func extractSources(from document: Document) throws -> [any EntityDetailsProvider]? {
        let sourceSelectors = [
            ".fact-sources .source",
            "[itemprop='citation']",
            ".reference-list li"
        ]
        
        var sources: [any EntityDetailsProvider] = []
        
        for selector in sourceSelectors {
            let elements = try document.select(selector)
            for element in elements {
                let name = try element.text()
                let url = try element.attr("href")
                if !name.isEmpty && !url.isEmpty {
                    let source = SourceInfo(name: name, url: url)
                    sources.append(source)
                }
            }
        }
        
        return sources.isEmpty ? nil : sources
    }
}

// MARK: - Helper Types

private struct SourceInfo: EntityDetailsProvider {
    var id: String = UUID().uuidString
    var name: String
    var url: String
    var details: String? = nil
    
    func getDetailedDescription() -> String {
        return "\(name) (\(url))"
    }
} 