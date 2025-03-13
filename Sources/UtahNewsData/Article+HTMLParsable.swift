//
//  Article+HTMLParsable.swift
//  UtahNewsData
//
//  Created by Mark Evans on 3/21/24
//
//  Summary: Extension making Article conform to HTMLParsable for HTML content extraction.

import Foundation
import SwiftSoup

extension Article: HTMLParsable {
    public static func parse(from document: Document) throws -> Article {
        // Validate that the document has a proper structure
        guard try !document.select("body").isEmpty(),
              try !document.select("head").isEmpty() else {
            throw ParsingError.invalidFormat("Invalid HTML document structure")
        }
        
        // Get the canonical URL if available, otherwise use the og:url or current URL
        let canonicalUrl = try document.select("link[rel=canonical]").first()?.attr("href")
        let ogUrl = try document.select("meta[property='og:url']").first()?.attr("content")
        let documentUrl = document.location()
        let url = canonicalUrl ?? ogUrl ?? documentUrl
        
        // Validate that we have a URL
        guard !url.isEmpty else {
            throw ParsingError.missingRequiredField("url")
        }
        
        // Get the title from various possible locations
        let title = try document.select("h1.article-title").first()?.text() ??
                   document.select("meta[property='og:title']").first()?.attr("content") ??
                   document.title()
        
        // Validate that we have a title
        guard !title.isEmpty else {
            throw ParsingError.missingRequiredField("title")
        }
        
        // Get the main content
        let content = try document.select(".article-content").first()?.text() ??
                     document.select("[itemprop='articleBody']").first()?.text() ??
                     ""
        
        // Get the author
        let author = try document.select(".author").first()?.text() ??
                    document.select("[itemprop='author']").first()?.text() ??
                    document.select("meta[name='author']").first()?.attr("content") ??
                    "Unknown"
        
        // Get the publication date
        let dateString = try document.select("[itemprop='datePublished']").first()?.attr("datetime") ??
                        document.select("meta[property='article:published_time']").first()?.attr("content") ??
                        ""
        
        // Get the main image URL
        let imageUrl = try document.select("meta[property='og:image']").first()?.attr("content") ??
                      document.select("[itemprop='image']").first()?.attr("src") ??
                      document.select(".article-image img").first()?.attr("src")
        
        // Get additional images
        var additionalImages: [String] = []
        let imageElements = try document.select(".article-content img")
        for element in imageElements {
            if let src = try? element.attr("src") {
                additionalImages.append(src)
            }
        }
        
        // Get the category
        let category = try document.select("[itemprop='articleSection']").first()?.text() ??
                      document.select(".category").first()?.text() ??
                      document.select("meta[property='article:section']").first()?.attr("content")
        
        // Parse the date string if available
        let publishedAt = DateFormatter.iso8601Full.date(from: dateString) ?? Date()
        
        return Article(
            title: title,
            url: url,
            urlToImage: imageUrl,
            additionalImages: additionalImages.isEmpty ? nil : additionalImages,
            publishedAt: publishedAt,
            textContent: content,
            author: author,
            category: category
        )
    }
    
    // MARK: - Private Helper Methods
    
    private static func extractURL(from document: Document) throws -> String {
        // Try canonical URL first
        if let canonicalUrl = try document.select("link[rel=canonical]").first()?.attr("href"),
           !canonicalUrl.isEmpty {
            return canonicalUrl
        }
        
        // Try og:url
        if let ogUrl = try document.select("meta[property='og:url']").first()?.attr("content"),
           !ogUrl.isEmpty {
            return ogUrl
        }
        
        // Use document location as last resort
        let url = document.location()
        if !url.isEmpty {
            return url
        }
        
        throw ParsingError.missingRequiredField("url")
    }
    
    private static func extractTitle(from document: Document) throws -> String {
        // Try article title first
        if let title = try document.select("h1.article-title").first()?.text(),
           !title.isEmpty {
            return title
        }
        
        // Try og:title
        if let ogTitle = try document.select("meta[property='og:title']").first()?.attr("content"),
           !ogTitle.isEmpty {
            return ogTitle
        }
        
        // Use document title as last resort
        let title = try document.title()
        if !title.isEmpty {
            return title
        }
        
        throw ParsingError.missingRequiredField("title")
    }
    
    private static func extractContent(from document: Document) throws -> String {
        // Try article content first with more comprehensive selectors
        let contentSelectors = [
            // Standard article content selectors
            ".article-content",
            "[itemprop='articleBody']",
            ".article-body",
            ".story-body",
            ".entry-content",
            ".post-content",
            // Main content areas
            "main article",
            "main .content",
            ".main-content",
            // Article with nested paragraphs
            "article p",
            // Content wrapper selectors
            ".content-wrapper",
            ".story-content",
            // Specific news site patterns
            ".story__body",
            ".article__body",
            // Direct paragraph selectors within content areas
            ".article-content > p",
            ".story-content > p",
            ".entry-content > p",
            // Fallback selectors
            "article",
            "main",
            // Last resort - any substantial paragraphs
            "body > :not(header):not(footer):not(nav) p"
        ]
        
        // First try to get content from specific selectors
        for selector in contentSelectors {
            let elements = try document.select(selector)
            if !elements.isEmpty() {
                // Get all text content and clean it
                let content = try elements.text()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                
                // Check if content is substantial (more than just a few words)
                if content.count > 50 {
                    return content
                }
            }
        }
        
        // If no content found through selectors, try to intelligently gather paragraphs
        let allParagraphs = try document.select("p").filter { element in
            do {
                let text = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
                // Filter out short paragraphs and common non-content elements
                return text.count > 30 && 
                       !text.contains("cookie") &&
                       !text.contains("subscribe") &&
                       !text.contains("sign up") &&
                       !text.contains("advertisement")
            } catch {
                return false
            }
        }
        
        if !allParagraphs.isEmpty {
            let content = try allParagraphs.map { try $0.text() }
                .joined(separator: "\n\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !content.isEmpty {
                return content
            }
        }
        
        return ""
    }
    
    private static func extractAuthor(from document: Document) throws -> String? {
        // Try author tag
        if let author = try document.select(".author").first()?.text(),
           !author.isEmpty {
            return author
        }
        
        // Try author meta
        if let author = try document.select("meta[name='author']").first()?.attr("content"),
           !author.isEmpty {
            return author
        }
        
        // Try article:author
        if let author = try document.select("meta[property='article:author']").first()?.attr("content"),
           !author.isEmpty {
            return author
        }
        
        return nil
    }
    
    private static func extractPublicationDate(from document: Document) throws -> Date {
        // Try published time meta
        if let dateStr = try document.select("meta[property='article:published_time']").first()?.attr("content"),
           let date = DateFormatter.iso8601Full.date(from: dateStr) {
            return date
        }
        
        // Try datePublished
        if let dateStr = try document.select("[itemprop='datePublished']").first()?.attr("datetime"),
           let date = DateFormatter.iso8601Full.date(from: dateStr) {
            return date
        }
        
        return Date()
    }
    
    private static func extractImages(from document: Document) throws -> (String?, [String]) {
        var mainImage: String? = nil
        var additionalImages: [String] = []
        
        // Try og:image for main image
        mainImage = try document.select("meta[property='og:image']").first()?.attr("content")
        
        // If no og:image, try article image
        if mainImage == nil {
            mainImage = try document.select("[itemprop='image']").first()?.attr("src") ??
                       document.select(".article-image img").first()?.attr("src")
        }
        
        // Get additional images
        let imageElements = try document.select(".article-content img")
        for element in imageElements {
            if let src = try? element.attr("src"),
               !src.isEmpty,
               src != mainImage {
                additionalImages.append(src)
            }
        }
        
        return (mainImage, additionalImages)
    }
    
    private static func extractCategory(from document: Document) throws -> String? {
        // Try article section
        if let category = try document.select("[itemprop='articleSection']").first()?.text(),
           !category.isEmpty {
            return category
        }
        
        // Try category class
        if let category = try document.select(".category").first()?.text(),
           !category.isEmpty {
            return category
        }
        
        // Try article:section meta
        return try document.select("meta[property='article:section']").first()?.attr("content")
    }
}

// MARK: - Helper Extensions

private extension Article {
    /// Attempts to parse a date string using multiple common formats
    static func parseDate(_ dateString: String) -> Date? {
        let formatters: [DateFormatter] = [
            .iso8601Full,
            .iso8601,
            .standardDate
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
} 