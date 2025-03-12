import Foundation
import SwiftSoup

extension Jurisdiction: HTMLParsable {
    public static func parse(from document: Document) throws -> Jurisdiction {
        let name = try extractName(from: document)
        let type = try extractType(from: document)
        let website = try extractWebsite(from: document)
        let location = try Location.parse(from: document)
        
        var jurisdiction = Jurisdiction(
            type: type,
            name: name,
            location: location
        )
        jurisdiction.website = website
        return jurisdiction
    }
    
    // MARK: - Private Helper Methods
    
    private static func extractName(from document: Document) throws -> String {
        let nameSelectors = [
            "[itemprop='name']",
            ".jurisdiction-name",
            "h1.name",
            "meta[property='og:title']"
        ]
        
        for selector in nameSelectors {
            if selector.contains("meta") {
                if let name = try document.select(selector).first()?.attr("content"),
                   !name.isEmpty {
                    return name
                }
            } else {
                if let name = try document.select(selector).first()?.text(),
                   !name.isEmpty {
                    return name
                }
            }
        }
        
        throw ParsingError.missingRequiredField("name")
    }
    
    private static func extractType(from document: Document) throws -> JurisdictionType {
        let typeSelectors = [
            "[itemprop='jurisdictionType']",
            ".jurisdiction-type",
            ".type"
        ]
        
        for selector in typeSelectors {
            if let typeStr = try document.select(selector).first()?.text().lowercased() {
                switch typeStr {
                case "city", "municipality":
                    return .city
                case "county":
                    return .county
                case "state":
                    return .state
                default:
                    continue
                }
            }
        }
        
        return .city // Default to city if no type is found
    }
    
    private static func extractWebsite(from document: Document) throws -> String? {
        let websiteSelectors = [
            "[itemprop='url']",
            "link[rel='canonical']",
            "meta[property='og:url']",
            ".website a"
        ]
        
        for selector in websiteSelectors {
            if selector.contains("meta") {
                if let url = try document.select(selector).first()?.attr("content"),
                   !url.isEmpty {
                    return url
                }
            } else if selector.contains("link") {
                if let url = try document.select(selector).first()?.attr("href"),
                   !url.isEmpty {
                    return url
                }
            } else {
                if let url = try document.select(selector).first()?.attr("href"),
                   !url.isEmpty {
                    return url
                }
            }
        }
        
        return nil
    }
} 