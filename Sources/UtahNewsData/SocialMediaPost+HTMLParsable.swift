import Foundation
import SwiftSoup

extension SocialMediaPost: HTMLParsable {
    public static func parse(from document: Document) throws -> SocialMediaPost {
        let content = try extractContent(from: document)
        let platform = try extractPlatform(from: document)
        let author = try extractAuthor(from: document)
        let datePosted = try extractDatePosted(from: document)
        let url = try extractURL(from: document)
        let mediaURLs = try extractMediaURLs(from: document)
        let engagement = try extractEngagement(from: document)
        
        return SocialMediaPost(
            id: UUID().uuidString,
            author: author,
            platform: platform,
            datePosted: datePosted,
            url: URL(string: url)!,
            content: content,
            mediaURLs: mediaURLs,
            likeCount: engagement.likes,
            shareCount: engagement.shares,
            commentCount: engagement.comments
        )
    }
    
    // MARK: - Private Helper Methods
    
    private static func extractContent(from document: Document) throws -> String {
        let contentSelectors = [
            "[itemprop='text']",
            ".post-content",
            ".tweet-text",
            "meta[property='og:description']"
        ]
        
        for selector in contentSelectors {
            if selector.contains("meta") {
                if let content = try document.select(selector).first()?.attr("content"),
                   !content.isEmpty {
                    return content
                }
            } else {
                if let content = try document.select(selector).first()?.text(),
                   !content.isEmpty {
                    return content
                }
            }
        }
        
        throw ParsingError.missingRequiredField("content")
    }
    
    private static func extractPlatform(from document: Document) throws -> String {
        let url = document.location()
        if url.contains("twitter.com") || url.contains("x.com") {
            return "Twitter"
        } else if url.contains("facebook.com") {
            return "Facebook"
        } else if url.contains("instagram.com") {
            return "Instagram"
        } else if url.contains("linkedin.com") {
            return "LinkedIn"
        }
        
        for selector in ["[itemprop='platform']", ".platform", ".social-platform"] {
            if let element = try document.select(selector).first() {
                return try element.text()
            }
        }
        
        return "Unknown"
    }
    
    private static func extractAuthor(from document: Document) throws -> Person {
        for selector in ["[itemprop='author']", ".post-author", ".author-info"] {
            if let element = try document.select(selector).first() {
                let nameElement = try element.select("[itemprop='name']").first()
                let name: String
                if let nameText = try nameElement?.text() {
                    name = nameText
                } else {
                    let authorNameElement = try element.select(".author-name").first()
                    if let authorNameText = try authorNameElement?.text() {
                        name = authorNameText
                    } else {
                        name = try element.text()
                    }
                }
                
                return Person(
                    id: UUID().uuidString,
                    name: name,
                    details: ""
                )
            }
        }
        
        throw ParsingError.missingRequiredField("author")
    }
    
    private static func extractDatePosted(from document: Document) throws -> Date {
        let dateSelectors = [
            "[itemprop='datePublished']",
            "time[datetime]",
            "meta[property='article:published_time']",
            ".post-date"
        ]
        
        for selector in dateSelectors {
            if selector.contains("meta") || selector.contains("time") {
                if let dateStr = try document.select(selector).first()?.attr(selector.contains("time") ? "datetime" : "content"),
                   let date = DateFormatter.iso8601.date(from: dateStr) {
                    return date
                }
            } else {
                if let dateStr = try document.select(selector).first()?.text(),
                   let date = DateFormatter.standardDate.date(from: dateStr) {
                    return date
                }
            }
        }
        
        return Date()
    }
    
    private static func extractURL(from document: Document) throws -> String {
        let url = document.location()
        if !url.isEmpty {
            return url
        }
        
        let urlSelectors = [
            "meta[property='og:url']",
            "link[rel='canonical']",
            "[itemprop='url']"
        ]
        
        for selector in urlSelectors {
            if let url = try document.select(selector).first()?.attr(selector.contains("meta") ? "content" : "href"),
               !url.isEmpty {
                return url
            }
        }
        
        throw ParsingError.missingRequiredField("url")
    }
    
    private static func extractMediaURLs(from document: Document) throws -> [String]? {
        let mediaSelectors = [
            "[itemprop='image']",
            "[itemprop='video']",
            ".post-media img",
            ".post-media video",
            "meta[property='og:image']",
            "meta[property='og:video']"
        ]
        
        var mediaURLs: [String] = []
        
        for selector in mediaSelectors {
            let elements = try document.select(selector)
            for element in elements {
                let url = if selector.contains("meta") {
                    try element.attr("content")
                } else {
                    try element.attr("src")
                }
                if !url.isEmpty {
                    mediaURLs.append(url)
                }
            }
        }
        
        return mediaURLs.isEmpty ? nil : mediaURLs
    }
    
    private static func extractEngagement(from document: Document) throws -> Engagement {
        let engagementSelectors = [
            "[itemprop='interactionStatistic']",
            ".engagement-stats",
            ".post-metrics"
        ]
        
        for selector in engagementSelectors {
            if let element = try document.select(selector).first() {
                let likes = try Int(element.select(".likes-count, [itemprop='likes']").first()?.text() ?? "0") ?? 0
                let shares = try Int(element.select(".shares-count, [itemprop='shares']").first()?.text() ?? "0") ?? 0
                let comments = try Int(element.select(".comments-count, [itemprop='comments']").first()?.text() ?? "0") ?? 0
                
                if likes > 0 || shares > 0 || comments > 0 {
                    return Engagement(likes: likes, shares: shares, comments: comments)
                }
            }
        }
        
        throw ParsingError.missingRequiredField("engagement")
    }
}

// MARK: - Helper Types

private struct Engagement {
    let likes: Int
    let shares: Int
    let comments: Int
} 