import Foundation
import SwiftSoup

extension Organization: HTMLParsable {
    public static func parse(from document: Document) throws -> Organization {
        // Validate that the document has a proper structure
        guard try !document.select("body").isEmpty(),
              try !document.select("head").isEmpty() else {
            throw ParsingError.invalidFormat("Invalid HTML document structure")
        }
        
        // Extract required fields
        let name = try extractName(from: document)
        
        // Extract optional fields
        let description = try extractDescription(from: document)
        let website = try extractWebsite(from: document)
        let location = try extractLocation(from: document)
        let type = try extractType(from: document)
        let contactInfo = try extractContactInfo(from: document)
        
        // Create and return the Organization
        return Organization(
            name: name,
            orgDescription: description,
            contactInfo: contactInfo.map { [$0] },
            website: website,
            logoURL: nil,
            location: location.map { Location(name: $0) },
            type: type ?? "Unknown"
        )
    }
    
    // MARK: - Private Helper Methods
    
    private static func extractName(from document: Document) throws -> String {
        let nameSelectors = [
            "[itemprop='name']",
            ".org-name",
            "h1.organization-name",
            "meta[property='og:site_name']"
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
    
    private static func extractDescription(from document: Document) throws -> String? {
        let descriptionSelectors = [
            "[itemprop='description']",
            ".org-description",
            "meta[property='og:description']",
            ".about-org"
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
        
        return nil
    }
    
    private static func extractWebsite(from document: Document) throws -> String? {
        let websiteSelectors = [
            "[itemprop='url']",
            "link[rel='canonical']",
            "meta[property='og:url']",
            ".org-website a"
        ]
        
        for selector in websiteSelectors {
            if selector.contains("meta") || selector.contains("link") {
                if let url = try document.select(selector).first()?.attr(selector.contains("link") ? "href" : "content"),
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
    
    private static func extractLocation(from document: Document) throws -> String? {
        let locationSelectors = [
            "[itemprop='location']",
            ".org-location",
            ".headquarters",
            "meta[property='business:location']"
        ]
        
        for selector in locationSelectors {
            if selector.contains("meta") {
                if let location = try document.select(selector).first()?.attr("content"),
                   !location.isEmpty {
                    return location
                }
            } else {
                if let location = try document.select(selector).first()?.text(),
                   !location.isEmpty {
                    return location
                }
            }
        }
        
        return nil
    }
    
    private static func extractType(from document: Document) throws -> String? {
        let typeSelectors = [
            "[itemprop='organizationType']",
            ".org-type",
            ".organization-category"
        ]
        
        for selector in typeSelectors {
            if let typeText = try document.select(selector).first()?.text() {
                return typeText.trimmingCharacters(in: .whitespaces)
            }
        }
        
        return nil
    }
    
    private static func extractContactInfo(from document: Document) throws -> ContactInfo? {
        let contactSelectors = [
            "[itemprop='contactPoint']",
            ".contact-info",
            ".org-contact"
        ]
        
        for selector in contactSelectors {
            if let element = try document.select(selector).first() {
                let email = try element.select("[itemprop='email']").first()?.text()
                let phone = try element.select("[itemprop='telephone']").first()?.text()
                let website = try element.select("[itemprop='url']").first()?.attr("href")
                
                if email != nil || phone != nil || website != nil {
                    return ContactInfo(
                        email: email,
                        website: website,
                        phone: phone
                    )
                }
            }
        }
        
        return nil
    }
} 