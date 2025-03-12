//
//  Audio+HTMLParsable.swift
//  UtahNewsData
//
//  Created by Mark Evans on 3/21/24
//
//  Summary: Extension making Audio conform to HTMLParsable for HTML content extraction.

import Foundation
import SwiftSoup

extension Audio: HTMLParsable {
    public static func parse(from document: Document) throws -> Audio {
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
            throw ParsingError.missingRequiredField("url")
        }
        
        // Get the title from various possible locations
        let title = try document.select("meta[property='og:title']").first()?.attr("content") ??
                   document.select("meta[name='title']").first()?.attr("content") ??
                   document.title()
        
        // Validate that we have a title
        guard !title.isEmpty else {
            throw ParsingError.missingRequiredField("title")
        }
        
        // Get the audio duration
        let durationStr = try document.select("meta[property='audio:duration']").first()?.attr("content") ??
                         document.select("[itemprop='duration']").first()?.attr("content") ??
                         "0"
        let duration = TimeInterval(durationStr) ?? 0
        
        // Get the audio bitrate
        let bitrateStr = try document.select("meta[property='audio:bitrate']").first()?.attr("content") ??
                        document.select("[itemprop='bitrate']").first()?.attr("content") ??
                        "128"
        let bitrate = Int(bitrateStr) ?? 128
        
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
        
        return Audio(
            title: title,
            url: url,
            urlToImage: thumbnailUrl,
            publishedAt: publishedAt,
            textContent: description,
            author: author,
            duration: duration,
            bitrate: bitrate
        )
    }
    
    public static func parse(from html: String) throws -> Audio {
        do {
            let document = try SwiftSoup.parse(html)
            return try parse(from: document)
        } catch {
            throw ParsingError.invalidHTML
        }
    }
} 