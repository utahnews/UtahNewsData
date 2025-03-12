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
            throw ParsingError.invalidHTML
        }
        
        // Get the canonical URL if available, otherwise use the og:url or current URL
        let canonicalUrl = try document.select("link[rel=canonical]").first()?.attr("href")
        let ogUrl = try document.select("meta[property='og:url']").first()?.attr("content")
        let url = canonicalUrl ?? ogUrl ?? ""
        
        // Validate that we have a URL
        guard !url.isEmpty else {
            throw ParsingError.invalidHTML
        }
        
        // Get the title from various possible locations
        let title = try document.select("h1.article-title").first()?.text() ??
                   document.select("meta[property='og:title']").first()?.attr("content") ??
                   document.title()
        
        // Validate that we have a title
        guard !title.isEmpty else {
            throw ParsingError.invalidHTML
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