import Foundation
import SwiftSoup

extension NewsAlert: HTMLParsable {
    public static func parse(from document: Document) throws -> NewsAlert {
        // Validate that the document has a proper structure
        guard try !document.select("body").isEmpty(),
              try !document.select("head").isEmpty() else {
            throw ParsingError.invalidFormat("Invalid HTML document structure")
        }
        
        // Extract required fields
        let title = try extractTitle(from: document)
        let description = try extractDescription(from: document)
        
        // Extract optional fields
        let urgencyLevel = try extractUrgencyLevel(from: document)
        let category = try extractCategory(from: document)
        let timestamp = try extractTimestamp(from: document)
        let source = try extractSource(from: document)
        
        // Create and return the NewsAlert
        return NewsAlert(
            id: UUID().uuidString,
            title: title,
            content: description,
            alertType: category ?? "General",
            severity: urgencyLevel,
            publishedAt: timestamp ?? Date(),
            source: source ?? "Unknown"
        )
    }
    
    // MARK: - Private Helper Methods
    
    private static func extractTitle(from document: Document) throws -> String {
        let titleSelectors = [
            "[itemprop='headline']",
            ".alert-title",
            "h1.title",
            "meta[property='og:title']"
        ]
        
        for selector in titleSelectors {
            if selector.contains("meta") {
                if let title = try document.select(selector).first()?.attr("content"),
                   !title.isEmpty {
                    return title
                }
            } else {
                if let title = try document.select(selector).first()?.text(),
                   !title.isEmpty {
                    return title
                }
            }
        }
        
        throw ParsingError.missingRequiredField("title")
    }
    
    private static func extractDescription(from document: Document) throws -> String {
        let descriptionSelectors = [
            "[itemprop='description']",
            ".alert-description",
            ".alert-content",
            "meta[property='og:description']"
        ]
        
        for selector in descriptionSelectors {
            if selector.contains("meta") {
                if let description = try document.select(selector).first()?.attr("content"),
                   !description.isEmpty {
                    return description
                }
            } else {
                if let description = try document.select(selector).first()?.text(),
                   !description.isEmpty {
                    return description
                }
            }
        }
        
        throw ParsingError.missingRequiredField("description")
    }
    
    private static func extractUrgencyLevel(from document: Document) throws -> AlertSeverity {
        let urgencySelectors = [
            "[itemprop='urgencyLevel']",
            ".alert-urgency",
            ".urgency-level"
        ]
        
        for selector in urgencySelectors {
            if let urgencyText = try document.select(selector).first()?.text() {
                let text = urgencyText.lowercased()
                if text.contains("critical") || text.contains("emergency") {
                    return AlertSeverity(rawValue: "Critical") ?? .medium
                } else if text.contains("high") {
                    return AlertSeverity(rawValue: "High") ?? .medium
                } else if text.contains("medium") {
                    return AlertSeverity(rawValue: "Medium") ?? .medium
                } else if text.contains("low") {
                    return AlertSeverity(rawValue: "Low") ?? .medium
                }
            }
        }
        
        return .medium
    }
    
    private static func extractCategory(from document: Document) throws -> String? {
        let categorySelectors = [
            "[itemprop='category']",
            ".alert-category",
            ".alert-type"
        ]
        
        for selector in categorySelectors {
            if let category = try document.select(selector).first()?.text(),
               !category.isEmpty {
                return category
            }
        }
        
        return nil
    }
    
    private static func extractLocation(from document: Document) throws -> Location? {
        for selector in ["[itemprop='location']", ".alert-location", ".location-info"] {
            if let element = try document.select(selector).first() {
                let nameElement = try element.select("[itemprop='name']").first()
                let name: String
                if let nameText = try nameElement?.text() {
                    name = nameText
                } else {
                    let locationNameElement = try element.select(".location-name").first()
                    if let locationNameText = try locationNameElement?.text() {
                        name = locationNameText
                    } else {
                        name = try element.text()
                    }
                }
                
                let address = try element.select("[itemprop='streetAddress']").first()?.text()
                let city = try element.select("[itemprop='addressLocality']").first()?.text()
                let state = try element.select("[itemprop='addressRegion']").first()?.text()
                let zipCode = try element.select("[itemprop='postalCode']").first()?.text()
                let country = try element.select("[itemprop='addressCountry']").first()?.text()
                
                return Location(
                    latitude: nil,
                    longitude: nil,
                    address: address,
                    city: city,
                    state: state,
                    zipCode: zipCode,
                    country: country,
                    relationships: []
                )
            }
        }
        
        return nil
    }
    
    private static func extractTimestamp(from document: Document) throws -> Date? {
        let timestampSelectors = [
            "[itemprop='datePublished']",
            "time[datetime]",
            "meta[property='article:published_time']",
            ".alert-timestamp"
        ]
        
        for selector in timestampSelectors {
            if selector.contains("meta") || selector.contains("time") {
                if let dateStr = try document.select(selector).first()?.attr(selector.contains("time") ? "datetime" : "content"),
                   let date = DateFormatter.iso8601.date(from: dateStr) {
                    return date
                }
            } else {
                if let dateStr = try document.select(selector).first()?.text(),
                   let date = DateFormatter.standardDate.date(from: dateStr) {
                    return date
                }
            }
        }
        
        return nil
    }
    
    private static func extractSource(from document: Document) throws -> String? {
        let sourceSelectors = [
            "[itemprop='publisher']",
            ".alert-source",
            "meta[property='og:site_name']",
            ".source-info"
        ]
        
        for selector in sourceSelectors {
            if selector.contains("meta") {
                if let source = try document.select(selector).first()?.attr("content"),
                   !source.isEmpty {
                    return source
                }
            } else {
                if let source = try document.select(selector).first()?.text(),
                   !source.isEmpty {
                    return source
                }
            }
        }
        
        return nil
    }
} 