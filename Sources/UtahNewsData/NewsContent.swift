//
//  NewsContent.swift
//  UtahNewsData
//
//  Created by Mark Evans on 11/18/24.
//

/*
 # NewsContent Protocol
 
 This file defines the NewsContent protocol, which serves as the foundation for
 various types of news content in the UtahNewsData system, such as articles, videos,
 and audio content.
 
 ## Key Features:
 
 1. Core identification (id, title)
 2. Content access (url)
 3. Media representation (urlToImage)
 4. Publication metadata (publishedAt, author)
 5. Content storage (textContent)
 6. Basic information display (basicInfo)
 
 ## Usage:
 
 The NewsContent protocol is implemented by various content types:
 
 ```swift
 // Article implementation
 struct Article: NewsContent {
     var id: String
     var title: String
     var url: String
     var urlToImage: String?
     var publishedAt: Date
     var textContent: String?
     var author: String?
     
     // Additional article-specific properties
     var category: String?
     var source: String?
 }
 
 // Video implementation
 struct Video: NewsContent {
     var id: String
     var title: String
     var url: String
     var urlToImage: String?
     var publishedAt: Date
     var textContent: String?
     var author: String?
     
     // Additional video-specific properties
     var duration: TimeInterval
     var resolution: String
 }
 ```
 
 The protocol provides a common interface for working with different types of news content,
 allowing for consistent handling in UI components and data processing.
 
 ## Migration to MediaItem
 
 While the NewsContent protocol is still supported for backward compatibility,
 new code should use the MediaItem struct instead, which provides a more unified
 approach to handling all types of media content.
 
 ```swift
 // Convert a NewsContent object to a MediaItem
 let article = Article(title: "News Article", url: "https://example.com")
 let mediaItem = MediaItem.from(article)
 ```
 */

import Foundation

/// A protocol defining the common properties and methods for news content types.
/// This protocol serves as the foundation for various types of news content in the
/// UtahNewsData system, such as articles, videos, and audio content.
///
/// Note: While still supported for backward compatibility, new code should use
/// the MediaItem struct instead, which provides a more unified approach to
/// handling all types of media content.
public protocol NewsContent: BaseEntity {
    /// Title or headline of the content
    var title: String { get set }
    
    /// URL where the content can be accessed
    var url: String { get set }
    
    /// URL to an image representing the content (thumbnail, featured image)
    var urlToImage: String? { get set }
    
    /// When the content was published
    var publishedAt: Date { get set }
    
    /// The main text content, if available
    var textContent: String? { get set }
    
    /// Author or creator of the content
    var author: String? { get set }
    
    /// Returns a basic information string about the content
    func basicInfo() -> String
}

/// Default implementation of the basicInfo method
public extension NewsContent {
    /// Returns a basic information string containing the title and publication date.
    /// 
    /// - Returns: A formatted string with the content's title and publication date
    func basicInfo() -> String {
        return "Title: \(title), Published At: \(publishedAt)"
    }
    
    /// The name property required by the BaseEntity protocol.
    /// Returns the title of the content.
    var name: String {
        return title
    }
}

/// Extension to provide conversion to MediaItem
public extension NewsContent {
    /// Converts this NewsContent object to a MediaItem.
    ///
    /// - Returns: A new MediaItem with properties from this NewsContent object
    func toMediaItem() -> MediaItem {
        return MediaItem(
            id: id,
            title: title,
            type: determineMediaType(),
            url: url,
            textContent: textContent,
            author: author,
            publishedAt: publishedAt
        )
    }
    
    /// Determines the appropriate MediaType for this NewsContent object.
    ///
    /// - Returns: The MediaType that best matches this content
    private func determineMediaType() -> MediaType {
        // This is a simple implementation that could be overridden by specific types
        let typeString = String(describing: type(of: self)).lowercased()
        
        if typeString.contains("video") {
            return .video
        } else if typeString.contains("audio") {
            return .audio
        } else if typeString.contains("article") {
            return .text
        } else {
            return .other
        }
    }
}
