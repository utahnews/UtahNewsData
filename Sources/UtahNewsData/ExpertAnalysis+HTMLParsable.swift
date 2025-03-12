import Foundation
import SwiftSoup

extension ExpertAnalysis: HTMLParsable {
    public static func parse(from document: Document) throws -> ExpertAnalysis {
        // Validate that the document has a proper structure
        guard try !document.select("body").isEmpty(),
              try !document.select("head").isEmpty() else {
            throw ParsingError.invalidFormat("Invalid HTML document structure")
        }
        
        // Extract required fields
        let expert = try extractExpert(from: document)
        let date = try extractDate(from: document) ?? Date()
        
        // Create and return the ExpertAnalysis
        return ExpertAnalysis(
            expert: expert,
            date: date
        )
    }
    
    // MARK: - Private Helper Methods
    
    private static func extractExpert(from document: Document) throws -> Person {
        let expertSelectors = [
            "[itemprop='expert']",
            ".expert-info",
            ".analyst-details"
        ]
        
        for selector in expertSelectors {
            if let element = try document.select(selector).first() {
                let name = try element.select("[itemprop='name']").first()?.text()
                let title = try element.select("[itemprop='jobTitle']").first()?.text()
                let organization = try element.select("[itemprop='affiliation']").first()?.text()
                
                if let name = name {
                    return Person(
                        name: name,
                        details: title ?? "",
                        biography: nil,
                        birthDate: nil,
                        deathDate: nil,
                        occupation: organization,
                        nationality: nil,
                        notableAchievements: nil,
                        imageURL: nil,
                        locationString: nil,
                        locationLatitude: nil,
                        locationLongitude: nil,
                        email: nil,
                        website: nil,
                        phone: nil,
                        address: nil,
                        socialMediaHandles: nil
                    )
                }
            }
        }
        
        throw ParsingError.missingRequiredField("expert")
    }
    
    private static func extractDate(from document: Document) throws -> Date? {
        let dateSelectors = [
            "[itemprop='dateCreated']",
            ".analysis-date",
            "time[datetime]",
            "meta[property='article:published_time']"
        ]
        
        for selector in dateSelectors {
            if let dateStr = try document.select(selector).first()?.attr(selector.contains("meta") ? "content" : "datetime") {
                for formatter in [DateFormatter.iso8601Full, DateFormatter.iso8601, DateFormatter.standardDate] {
                    if let date = formatter.date(from: dateStr) {
                        return date
                    }
                }
            }
        }
        
        return nil
    }
} 