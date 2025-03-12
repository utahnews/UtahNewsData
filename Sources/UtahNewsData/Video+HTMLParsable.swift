//
//  Video+HTMLParsable.swift
//  UtahNewsData
//
//  Created by Mark Evans on 3/21/24
//
//  Summary: Extension making Video conform to HTMLParsable for HTML content extraction.

import Foundation
import SwiftSoup

extension Video: HTMLParsable {
    public static func parse(from document: Document) throws -> Video {
        // Validate that the document has a proper structure
        guard try !document.select("body").isEmpty(),
              try !document.select("head").isEmpty() else {
            throw ParsingError.invalidHTML
        }
        
        // Get the canonical URL if available, otherwise use the og:url or current URL
        let canonicalUrl = try document.select("link[rel=canonical]").first()?.attr("href")
        let ogUrl = try document.select("meta[property='og:url']").first()?.attr("content")
        let url = canonicalUrl ?? ogUrl ?? ""
        
        // Get the title from various possible locations
        let title = try document.select("meta[property='og:title']").first()?.attr("content") ??
                   document.select("meta[name='title']").first()?.attr("content") ??
                   document.title()
        
        // Validate that we have a URL
        guard !url.isEmpty else {
            throw ParsingError.missingRequiredField("url")
        }
        
        // Validate that we have a title
        guard !title.isEmpty else {
            throw ParsingError.missingRequiredField("title")
        }
        
        // Get the video duration
        let durationStr = try document.select("meta[property='video:duration']").first()?.attr("content") ??
                         document.select("[itemprop='duration']").first()?.attr("content") ??
                         "0"
        let duration = TimeInterval(durationStr) ?? 0
        
        // Get the video resolution
        let resolution: String
        if let width = try document.select("meta[property='og:video:width']").first(),
           let height = try document.select("meta[property='og:video:height']").first() {
            let widthValue = try width.attr("content")
            let heightValue = try height.attr("content")
            resolution = "\(widthValue)x\(heightValue)"
        } else {
            resolution = "Unknown"
        }
        
        // Get the thumbnail URL
        let thumbnailUrl = try document.select("meta[property='og:image']").first()?.attr("content") ??
                          document.select("[itemprop='thumbnailUrl']").first()?.attr("src")
        
        // Get the description/text content
        let description = try document.select("meta[property='og:description']").first()?.attr("content") ??
                         document.select("[itemprop='description']").first()?.text()
        
        // Get the author/creator
        let author = try document.select("[itemprop='author']").first()?.text() ??
                    document.select("meta[name='author']").first()?.attr("content")
        
        // Get the publication date
        let dateString = try document.select("[itemprop='uploadDate']").first()?.attr("datetime") ??
                        document.select("meta[property='article:published_time']").first()?.attr("content") ??
                        ""
        
        // Parse the date string if available
        let publishedAt = DateFormatter.iso8601Full.date(from: dateString) ?? Date()
        
        return Video(
            title: title,
            url: url,
            urlToImage: thumbnailUrl,
            publishedAt: publishedAt,
            textContent: description,
            author: author,
            duration: duration,
            resolution: resolution
        )
    }
    
    public static func parse(from html: String) throws -> Video {
        do {
            let document = try SwiftSoup.parse(html)
            return try parse(from: document)
        } catch {
            throw ParsingError.invalidHTML
        }
    }
} 