import Foundation
import SwiftSoup

extension Source: HTMLParsable {
    public static func parse(from document: Document) throws -> Source {
        let name = try extractName(from: document)
        let url = try extractURL(from: document)
        let description = try extractDescription(from: document)
        let category = try extractCategory(from: document)
        let language = try extractLanguage(from: document)
        
        return Source(
            name: name,
            url: url,
            description: description,
            category: category,
            language: language
        )
    }
    
    // MARK: - Private Helper Methods
    
    private static func extractName(from document: Document) throws -> String {
        let nameSelectors = [
            "[itemprop='name']",
            ".source-name",
            "meta[property='og:site_name']",
            ".publisher-name"
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
    
    private static func extractURL(from document: Document) throws -> String {
        let urlSelectors = [
            "[itemprop='url']",
            "link[rel='canonical']",
            "meta[property='og:url']",
            ".source-url"
        ]
        
        for selector in urlSelectors {
            if selector.contains("meta") {
                if let urlStr = try document.select(selector).first()?.attr("content"),
                   !urlStr.isEmpty {
                    return urlStr
                }
            } else if selector.contains("link") {
                if let urlStr = try document.select(selector).first()?.attr("href"),
                   !urlStr.isEmpty {
                    return urlStr
                }
            } else {
                if let urlStr = try document.select(selector).first()?.attr("href"),
                   !urlStr.isEmpty {
                    return urlStr
                }
            }
        }
        
        let baseURL = document.location()
        if !baseURL.isEmpty {
            return baseURL
        }
        
        throw ParsingError.missingRequiredField("url")
    }
    
    private static func extractDescription(from document: Document) throws -> String? {
        let descriptionSelectors = [
            "[itemprop='description']",
            ".source-description",
            "meta[property='og:description']",
            ".about-source"
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
    
    private static func extractCategory(from document: Document) throws -> String? {
        let categorySelectors = [
            "[itemprop='category']",
            ".source-category",
            ".publisher-category"
        ]
        
        for selector in categorySelectors {
            if let category = try document.select(selector).first()?.text(),
               !category.isEmpty {
                return category
            }
        }
        
        return nil
    }
    
    private static func extractLanguage(from document: Document) throws -> String? {
        // First try HTML lang attribute
        if let htmlLang = try document.select("html").first()?.attr("lang"),
           !htmlLang.isEmpty {
            return htmlLang
        }
        
        // Then try meta tags
        let langSelectors = [
            "meta[http-equiv='content-language']",
            "meta[name='language']",
            "meta[property='og:locale']"
        ]
        
        for selector in langSelectors {
            if let lang = try document.select(selector).first()?.attr("content"),
               !lang.isEmpty {
                return lang
            }
        }
        
        return nil
    }
} 