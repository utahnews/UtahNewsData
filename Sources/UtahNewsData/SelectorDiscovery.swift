//
//  SelectorDiscovery.swift
//  UtahNewsData
//
//  Created by Mark Evans on 3/21/24
//
//  Summary: Provides advanced selector discovery and validation functionality.

import Foundation
import SwiftSoup

/// A utility class for discovering CSS selectors in HTML documents
public enum SelectorDiscovery {
    /// A discovered selector with its confidence score and metadata
    public struct ScoredSelector: Hashable {
        public let selector: String
        public let score: Double
        public let metadata: [String: Any]
        
        public init(selector: String, score: Double, metadata: [String: Any] = [:]) {
            self.selector = selector
            self.score = score
            self.metadata = metadata
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(selector)
            hasher.combine(score)
        }
        
        public static func == (lhs: ScoredSelector, rhs: ScoredSelector) -> Bool {
            lhs.selector == rhs.selector && lhs.score == rhs.score
        }
    }
    
    /// Content types that can be discovered
    public enum ContentType {
        case title
        case mainContent
        case author
        case date
        case image
        case category
        
        /// Common selectors for each content type
        var commonSelectors: [String] {
            switch self {
            case .title:
                return [
                    "h1",
                    "h1.article-title",
                    ".article-title",
                    ".title",
                    ".headline",
                    "meta[property='og:title']",
                    "meta[name='title']"
                ]
            case .mainContent:
                return [
                    "article",
                    ".article-content",
                    ".content",
                    ".main-content",
                    ".story-content",
                    "meta[property='og:description']",
                    "meta[name='description']"
                ]
            case .author:
                return [
                    ".author",
                    ".byline",
                    ".writer",
                    "meta[name='author']",
                    "meta[property='article:author']"
                ]
            case .date:
                return [
                    ".date",
                    ".published-date",
                    ".timestamp",
                    "time",
                    "meta[property='article:published_time']",
                    "meta[name='date']"
                ]
            case .image:
                return [
                    ".featured-image",
                    ".article-image",
                    ".main-image",
                    "meta[property='og:image']",
                    "meta[name='image']"
                ]
            case .category:
                return [
                    ".category",
                    ".section",
                    ".topic",
                    "meta[property='article:section']",
                    "meta[name='category']"
                ]
            }
        }
        
        /// Common patterns in element text for each content type
        var textPatterns: [String] {
            switch self {
            case .title:
                return ["headline", "title"]
            case .mainContent:
                return ["article", "story", "content"]
            case .author:
                return ["by", "written by", "author"]
            case .date:
                return ["published", "posted", "date"]
            case .image:
                return ["image", "photo", "picture"]
            case .category:
                return ["category", "section", "topic"]
            }
        }
    }
    
    /// Discovers potential selectors for a specific content type in an HTML document
    public static func discoverSelectors(in document: Document, for type: ContentType) throws -> [ScoredSelector] {
        var selectors: [ScoredSelector] = []
        
        // Try common selectors first
        for selector in type.commonSelectors {
            if let element = try? document.select(selector).first() {
                let score = calculateScore(for: element, type: type)
                let metadata = gatherMetadata(from: element)
                selectors.append(ScoredSelector(selector: selector, score: score, metadata: metadata))
            }
        }
        
        // Look for elements with matching class names or IDs
        for pattern in type.textPatterns {
            let elements = try document.select("[class*=\(pattern)], [id*=\(pattern)]")
            for element in elements {
                let selector = try buildSelector(for: element)
                let score = calculateScore(for: element, type: type)
                let metadata = gatherMetadata(from: element)
                selectors.append(ScoredSelector(selector: selector, score: score, metadata: metadata))
            }
        }
        
        // Look for schema.org metadata
        if let schemaSelectors = try findSchemaOrgSelectors(in: document, for: type) {
            selectors.append(contentsOf: schemaSelectors)
        }
        
        // Sort by score and remove duplicates
        return Array(Set(selectors)).sorted { $0.score > $1.score }
    }
    
    private static func calculateScore(for element: Element, type: ContentType) -> Double {
        var score = 0.0
        
        // Position score (elements higher in the document get higher scores)
        if let position = try? element.siblingIndex {
            score += max(0, 1.0 - Double(position) * 0.1)
        }
        
        // Class name score
        if let className = try? element.className(), !className.isEmpty {
            for pattern in type.textPatterns {
                if className.lowercased().contains(pattern) {
                    score += 0.3
                }
            }
        }
        
        // Tag name score
        let tagName = element.tagName()
        switch type {
        case .title where tagName == "h1":
            score += 0.4
        case .mainContent where tagName == "article":
            score += 0.4
        case .author where tagName == "address":
            score += 0.3
        case .date where tagName == "time":
            score += 0.3
        case .image where tagName == "img":
            score += 0.4
        default:
            break
        }
        
        // Content length score
        if let text = try? element.text() {
            switch type {
            case .title:
                score += text.count > 20 && text.count < 200 ? 0.2 : 0
            case .mainContent:
                score += text.count > 200 ? 0.3 : 0
            case .author:
                score += text.count > 3 && text.count < 100 ? 0.2 : 0
            default:
                break
            }
        }
        
        return min(1.0, score)
    }
    
    private static func gatherMetadata(from element: Element) -> [String: Any] {
        var metadata: [String: Any] = [:]
        
        if let text = try? element.text() {
            metadata["text"] = text
        }
        
        // Get attributes using public API
        let attributeNames = ["id", "class", "name", "content", "property", "itemprop"]
        var attributes: [String] = []
        for name in attributeNames {
            if let value = try? element.attr(name), !value.isEmpty {
                attributes.append("\(name)=\(value)")
            }
        }
        if !attributes.isEmpty {
            metadata["attributes"] = attributes
        }
        
        return metadata
    }
    
    private static func buildSelector(for element: Element) throws -> String {
        var parts: [String] = []
        
        if let id = try? element.id(), !id.isEmpty {
            return "#\(id)"
        }
        
        if let className = try? element.className(), !className.isEmpty {
            parts.append(".\(className.components(separatedBy: .whitespaces).first!)")
        }
        
        parts.insert(element.tagName(), at: 0)
        return parts.joined()
    }
    
    private static func findSchemaOrgSelectors(in document: Document, for type: ContentType) throws -> [ScoredSelector]? {
        var selectors: [ScoredSelector] = []
        
        // Look for JSON-LD
        let scripts = try document.select("script[type='application/ld+json']")
        for script in scripts {
            if let jsonText = try? script.html(),
               let data = jsonText.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                let schemaType: String
                switch type {
                case .title: schemaType = "headline"
                case .mainContent: schemaType = "articleBody"
                case .author: schemaType = "author"
                case .date: schemaType = "datePublished"
                case .image: schemaType = "image"
                case .category: schemaType = "articleSection"
                }
                
                if json[schemaType] != nil {
                    selectors.append(ScoredSelector(
                        selector: "script[type='application/ld+json']",
                        score: 0.9,
                        metadata: ["schemaType": schemaType]
                    ))
                }
            }
        }
        
        return selectors.isEmpty ? nil : selectors
    }
} 