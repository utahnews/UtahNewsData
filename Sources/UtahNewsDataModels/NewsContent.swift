//
//  NewsContent.swift
//  UtahNewsDataModels
//
//  Created by Mark Evans on 01/29/25
//
//  Summary: Defines the NewsContent protocol, which serves as the foundation for
//           various types of news content in the UtahNewsDataModels system.

import Foundation

/// Represents the type of media content
public enum MediaType: String, Codable, Sendable {
    case article
    case image
    case video
    case audio
    case document
    case text
    case other
}

/// A protocol defining the common properties and methods for news content types.
/// This protocol serves as the foundation for various types of news content in the
/// UtahNewsDataModels system, such as articles, videos, and audio content.
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
    
    /// Determines the appropriate MediaType for this content
    func determineMediaType() -> MediaType
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
    
    /// Default implementation that determines MediaType based on the type name
    func determineMediaType() -> MediaType {
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