//
//  NewsStory+HTMLParsable.swift
//  UtahNewsData
//
//  Created by Mark Evans on 3/21/24
//
//  Summary: Extension making NewsStory conform to HTMLParsable for HTML content extraction.

import Foundation
import SwiftSoup

extension NewsStory: HTMLParsable {
    public static func parse(from document: Document) throws -> NewsStory {
        // Validate that the document has a proper structure
        guard try !document.select("body").isEmpty(),
              try !document.select("head").isEmpty() else {
            throw ParsingError.invalidHTML
        }
        
        // Get the headline from various possible locations
        let headline = try extractHeadline(from: document)
        
        // Get the URL from canonical link or og:url
        let url = try extractURL(from: document)
        
        // Get the content
        let content = try extractContent(from: document)
        
        // Get the author information
        let author = try extractAuthor(from: document)
        
        // Get the publication date
        let publishedAt = try extractPublicationDate(from: document)
        
        // Get the featured image URL
        let featuredImageURL = try extractFeaturedImage(from: document)
        
        return NewsStory(
            headline: headline,
            author: author,
            publishedDate: publishedAt,
            content: content,
            url: url,
            featuredImageURL: featuredImageURL
        )
    }
    
    // MARK: - Private Helper Methods
    
    private static func extractHeadline(from document: Document) throws -> String {
        // Try common headline selectors first
        let headlineSelectors = [
            "h1.story-headline",
            "h1.Article__Headline",
            "h1.Headline",
            "h1.article-headline",
            "h1.entry-title",
            "h1[itemprop='headline']"
        ]
        
        for selector in headlineSelectors {
            if let headline = try document.select(selector).first()?.text(),
               !headline.isEmpty {
                return headline
            }
        }
        
        // Try meta tags as fallback
        if let ogTitle = try document.select("meta[property='og:title']").first()?.attr("content"),
           !ogTitle.isEmpty {
            return ogTitle
        }
        
        // Fallback to document title
        let title = try document.title()
        if !title.isEmpty {
            return title
        }
        
        throw ParsingError.invalidHTML
    }
    
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
        
        throw ParsingError.invalidHTML
    }
    
    private static func extractContent(from document: Document) throws -> String? {
        // Try common content selectors
        let contentSelectors = [
            "article",
            ".Article__Content",
            ".Article-content",
            ".article-body",
            ".entry-content",
            ".story-content",
            "[itemprop='articleBody']"
        ]
        
        for selector in contentSelectors {
            if let content = try document.select(selector).first()?.text(),
               !content.isEmpty {
                return content
            }
        }
        
        // Try meta description as fallback
        return try document.select("meta[property='og:description']").first()?.attr("content") ??
               document.select("meta[name='description']").first()?.attr("content")
    }
    
    private static func extractAuthor(from document: Document) throws -> Person {
        var authorName = "Unknown"
        var authorDetails: String? = nil
        var authorBio: String? = nil
        
        // Try to get author name
        let authorSelectors = [
            "[itemprop='author']",
            ".Article__Author",
            ".Author-name",
            ".article-author",
            ".byline",
            "meta[name='author']"
        ]
        
        for selector in authorSelectors {
            if let name = try document.select(selector).first()?.text(),
               !name.isEmpty {
                authorName = name
                break
            }
        }
        
        // Try to get author details
        authorDetails = try document.select("[itemprop='jobTitle']").first()?.text() ??
                       document.select(".author-title").first()?.text()
        
        // Try to get author bio
        authorBio = try document.select("[itemprop='description']").first()?.text() ??
                    document.select(".author-bio").first()?.text()
        
        return Person(
            name: authorName,
            details: authorDetails ?? "Author",
            biography: authorBio
        )
    }
    
    private static func extractPublicationDate(from document: Document) throws -> Date {
        // Try various date meta tags
        let dateSelectors = [
            "meta[property='article:published_time']",
            "meta[property='og:published_time']",
            "[itemprop='datePublished']",
            "time.Article__Date",
            "time.Article-date",
            "time.published-date"
        ]
        
        for selector in dateSelectors {
            if let dateStr = try document.select(selector).first()?.attr(selector.contains("meta") ? "content" : "datetime"),
               let date = DateFormatter.iso8601Full.date(from: dateStr) {
                return date
            }
        }
        
        return Date()
    }
    
    private static func extractFeaturedImage(from document: Document) throws -> String? {
        // Try og:image first
        if let ogImage = try document.select("meta[property='og:image']").first()?.attr("content"),
           !ogImage.isEmpty {
            return ogImage
        }
        
        // Try common image selectors
        let imageSelectors = [
            ".Article__Hero img",
            ".Article-hero img",
            ".featured-image img",
            ".article-featured-image img",
            "[itemprop='image']"
        ]
        
        for selector in imageSelectors {
            if let imageUrl = try document.select(selector).first()?.attr("src"),
               !imageUrl.isEmpty {
                return imageUrl
            }
        }
        
        return nil
    }
} 