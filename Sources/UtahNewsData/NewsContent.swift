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
     var id: UUID
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
     var id: UUID
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
 */

import Foundation

/// A protocol defining the common properties and methods for news content types.
/// This protocol serves as the foundation for various types of news content in the
/// UtahNewsData system, such as articles, videos, and audio content.
public protocol NewsContent: Identifiable, Codable, Equatable, Hashable {
    /// Unique identifier for the content
    var id: UUID { get set }
    
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
}
