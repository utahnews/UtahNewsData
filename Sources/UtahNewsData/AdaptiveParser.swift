//
//  AdaptiveParser.swift
//  UtahNewsData
//
//  Created by Mark Evans on 3/21/24
//
//  Summary: Provides an adaptive HTML parser that can learn and adjust to different website structures.

import Foundation
import SwiftSoup

/// A parser that can adapt to different HTML structures and fall back to LLM extraction
@MainActor
public class AdaptiveParser: @unchecked Sendable {
    
    // MARK: - Types
    
    /// Represents a set of CSS selectors for parsing specific content types
    public struct SelectorSet: Codable {
        var title: String
        var content: String
        var author: String?
        var date: String?
        var image: String?
        var category: String?
        
        public init(
            title: String = "h1",
            content: String = "article",
            author: String? = nil,
            date: String? = nil,
            image: String? = nil,
            category: String? = nil
        ) {
            self.title = title
            self.content = content
            self.author = author
            self.date = date
            self.image = image
            self.category = category
        }
    }
    
    /// Result of a parsing attempt
    public enum ParsingResult<T: Sendable>: Sendable {
        case success(T, source: ParsingSource)
        case failure(Error)
        
        public var isSuccess: Bool {
            switch self {
            case .success: return true
            case .failure: return false
            }
        }
    }
    
    /// Source of the parsed content
    public enum ParsingSource: Sendable {
        case htmlParsing
        case llmExtraction
    }
    
    /// Errors that can occur during parsing
    public enum ParsingError: Error {
        case invalidType
        case invalidHTML
        case llmError(String)
        case llmExtractionFailed
    }
    
    // MARK: - Properties
    
    /// Cache of successful selector sets for different domains
    private var selectorCache: [String: SelectorSet] = [:]
    
    /// The LLM manager for fallback extraction
    private let llmManager: LocalLLMManager
    
    /// Whether to use LLM fallback when HTML parsing fails
    private let useLLMFallback: Bool
    
    // MARK: - Initialization
    
    /// Creates a new adaptive parser
    /// - Parameters:
    ///   - useLLMFallback: Whether to use LLM fallback when HTML parsing fails
    ///   - llmManager: The LLM manager to use for fallback (defaults to a new instance)
    public init(useLLMFallback: Bool = true, llmManager: LocalLLMManager? = nil) {
        self.useLLMFallback = useLLMFallback
        self.llmManager = llmManager ?? LocalLLMManager()
    }
    
    // MARK: - Parsing Methods
    
    /// Parse HTML content with fallback to LLM if needed
    /// - Parameters:
    ///   - html: The HTML content to parse
    ///   - url: The URL of the content
    ///   - type: The type to parse into
    /// - Returns: The parsing result, indicating success/failure and the source
    public func parseWithFallback<T: HTMLParsable>(html: String, from url: URL? = nil, as type: T.Type) async throws -> ParsingResult<T> {
        do {
            // First try HTML parsing
            let document = try SwiftSoup.parse(html)
            let parsedContent = try T.parse(from: document)
            
            // Check if we got empty content - if so, treat as parsing failure
            let contentIsEmpty = try document.select("body").text().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            if contentIsEmpty {
                throw ParsingError.invalidHTML
            }
            
            return .success(parsedContent, source: .htmlParsing)
            
        } catch {
            // If HTML parsing fails and LLM fallback is enabled, try LLM extraction
            if useLLMFallback {
                do {
                    // Extract title and content using LLM
                    let title = try await llmManager.extractContent(from: html, contentType: "title")
                    let content = try await llmManager.extractContent(from: html, contentType: "main content")
                    
                    // Create appropriate type based on extracted content
                    if let result = try? createInstance(ofType: T.self, withTitle: title, content: content) {
                        return .success(result, source: .llmExtraction)
                    }
                    
                    throw ParsingError.llmExtractionFailed
                } catch {
                    throw ParsingError.llmExtractionFailed
                }
            } else {
                throw ParsingError.invalidHTML
            }
        }
    }
    
    /// Parses HTML content using stored selectors for the domain if available
    /// - Parameters:
    ///   - html: The HTML content to parse
    ///   - url: The URL of the content (used for domain-specific selectors)
    /// - Returns: A dictionary of extracted content
    public func parse(html: String, from url: URL) throws -> [String: String] {
        let document = try SwiftSoup.parse(html)
        let domain = url.host ?? ""
        
        // Get or create selector set for this domain
        let selectors = selectorCache[domain] ?? SelectorSet()
        
        var result: [String: String] = [:]
        
        // Extract content using selectors
        if let title = try document.select(selectors.title).first()?.text() {
            result["title"] = title
        }
        
        if let content = try document.select(selectors.content).first()?.text() {
            result["content"] = content
        }
        
        if let author = selectors.author.flatMap({ try? document.select($0).first()?.text() }) {
            result["author"] = author
        }
        
        if let date = selectors.date.flatMap({ try? document.select($0).first()?.text() }) {
            result["date"] = date
        }
        
        if let image = selectors.image.flatMap({ try? document.select($0).first()?.attr("src") }) {
            result["image"] = image
        }
        
        if let category = selectors.category.flatMap({ try? document.select($0).first()?.text() }) {
            result["category"] = category
        }
        
        return result
    }
    
    // MARK: - Learning Methods
    
    /// Updates the selector set for a specific domain based on successful parsing
    /// - Parameters:
    ///   - selectors: The successful selector set
    ///   - domain: The domain these selectors work for
    public func learn(selectors: SelectorSet, for domain: String) {
        selectorCache[domain] = selectors
    }
    
    /// Attempts to find optimal selectors for a given HTML structure
    /// - Parameter document: The parsed HTML document
    /// - Returns: A set of selectors that might work for this structure
    public func discoverSelectors(in document: Document) throws -> SelectorSet {
        var selectors = SelectorSet()
        
        // Try common title selectors
        let titleSelectors = ["h1", ".article-title", ".post-title", "[itemprop='headline']"]
        for selector in titleSelectors {
            if try !document.select(selector).isEmpty() {
                selectors.title = selector
                break
            }
        }
        
        // Try common content selectors
        let contentSelectors = ["article", ".article-content", ".post-content", "[itemprop='articleBody']"]
        for selector in contentSelectors {
            if try !document.select(selector).isEmpty() {
                selectors.content = selector
                break
            }
        }
        
        // Try common author selectors
        let authorSelectors = [".author", "[rel='author']", "[itemprop='author']"]
        for selector in authorSelectors {
            if try !document.select(selector).isEmpty() {
                selectors.author = selector
                break
            }
        }
        
        return selectors
    }
    
    /// Clears the selector cache for testing or reset purposes
    public func clearCache() {
        selectorCache.removeAll()
    }
    
    // Helper method to create instances of different types
    private func createInstance<T>(ofType type: T.Type, withTitle title: String, content: String) throws -> T {
        if T.self == Article.self {
            let article = Article(
                title: title,
                url: "",  // Empty since we don't have it
                urlToImage: nil,
                additionalImages: nil,
                publishedAt: Date(),
                textContent: content,
                author: nil,
                category: nil
            )
            return article as! T
        }
        // Add other type handling as needed
        throw ParsingError.invalidType
    }
} 