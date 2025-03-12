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
    public func parseWithFallback<T: HTMLParsable>(html: String, from url: URL, as type: T.Type) async throws -> ParsingResult<T> {
        do {
            // First, validate that the HTML is well-formed
            guard let document = try? SwiftSoup.parse(html),
                  try !document.select("body").isEmpty() else {
                throw ParsingError.invalidHTML
            }
            
            // Try HTML parsing first
            do {
                let content = try T.parse(from: document)
                return .success(content, source: .htmlParsing)
            } catch {
                // If HTML parsing fails and LLM fallback is enabled, try LLM extraction
                if useLLMFallback {
                    // Try LLM extraction
                    let title = try await llmManager.extractContent(from: html, contentType: "title")
                    let content = try await llmManager.extractContent(from: html, contentType: "main content")
                    let author = try await llmManager.extractContent(from: html, contentType: "author")
                    let publishedAtStr = try await llmManager.extractContent(from: html, contentType: "publication date")
                    let category = try await llmManager.extractContent(from: html, contentType: "category")
                    let imageURL = try? await llmManager.extractContent(from: html, contentType: "featured image URL")
                    
                    // Try to parse the date string, fallback to current date
                    let dateFormatter = DateFormatter()
                    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                    let publishedAt = dateFormatter.date(from: publishedAtStr) ?? Date()
                    
                    // Create the appropriate type based on T
                    if T.self == NewsStory.self {
                        let story = NewsStory(
                            headline: title,
                            author: Person(name: author, details: "Author", biography: nil),
                            publishedDate: publishedAt,
                            content: content,
                            url: url.absoluteString,
                            featuredImageURL: imageURL
                        )
                        return .success(story as! T, source: .llmExtraction)
                    } else if T.self == Article.self {
                        let article = Article(
                            id: UUID().uuidString,
                            title: title,
                            url: url.absoluteString,
                            urlToImage: imageURL,
                            additionalImages: [],
                            publishedAt: publishedAt,
                            textContent: content,
                            author: author,
                            category: category,
                            videoURL: nil,
                            location: nil,
                            relationships: []
                        )
                        return .success(article as! T, source: .llmExtraction)
                    } else if T.self == Video.self {
                        let video = Video(
                            id: UUID().uuidString,
                            title: title,
                            url: url.absoluteString,
                            urlToImage: imageURL,
                            publishedAt: publishedAt,
                            textContent: content,
                            author: author,
                            duration: 0,  // Default duration since we can't extract it reliably
                            resolution: "Unknown"  // Default resolution since we can't extract it reliably
                        )
                        return .success(video as! T, source: .llmExtraction)
                    } else if T.self == Audio.self {
                        let audio = Audio(
                            id: UUID().uuidString,
                            title: title,
                            url: url.absoluteString,
                            urlToImage: imageURL,
                            publishedAt: publishedAt,
                            textContent: content,
                            author: author,
                            duration: 0,  // Default duration since we can't extract it reliably
                            bitrate: 128  // Default bitrate since we can't extract it reliably
                        )
                        return .success(audio as! T, source: .llmExtraction)
                    } else if T.self == StatisticalData.self {
                        let stats = StatisticalData(
                            title: title,
                            value: content,  // Use the main content as the value
                            unit: category.isEmpty ? "Unknown" : category,
                            source: Person(name: author, details: "Source", biography: nil),
                            date: publishedAt,
                            methodology: nil,
                            marginOfError: nil
                        )
                        return .success(stats as! T, source: .llmExtraction)
                    }
                    
                    throw ParsingError.invalidType
                } else {
                    throw error
                }
            }
        } catch {
            throw error
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
} 