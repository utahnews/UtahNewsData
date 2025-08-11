//
//  Video.swift
//  UtahNewsDataModels
//
//  Created by Mark Evans on 01/29/25
//
//  Summary: Defines the Video model which represents video content in the UtahNewsDataModels system.
//           Lightweight version without HTML parsing capabilities.

import Foundation

/// A struct representing a video in the news app.
/// Videos are a type of news content with additional properties for
/// duration and resolution.
public struct Video: NewsContent, BaseEntity, Sendable {
    /// Unique identifier for the video
    public var id: String
    
    /// The name of the entity (required by BaseEntity)
    public var name: String { title }
    
    /// Title or headline of the video
    public var title: String
    
    /// URL where the video can be accessed
    public var url: String
    
    /// URL to a thumbnail image representing the video
    public var urlToImage: String?
    
    /// When the video was published
    public var publishedAt: Date
    
    /// Description or transcript of the video
    public var textContent: String?
    
    /// Creator or producer of the video
    public var author: String?
    
    /// Length of the video in seconds
    public var duration: TimeInterval
    
    /// Video quality (e.g., "720p", "1080p", "4K")
    public var resolution: String
    
    /// Creates a new video with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the video (defaults to a new UUID string)
    ///   - title: Title or headline of the video
    ///   - url: URL where the video can be accessed
    ///   - urlToImage: URL to a thumbnail image (defaults to a placeholder)
    ///   - publishedAt: When the video was published (defaults to current date)
    ///   - textContent: Description or transcript of the video
    ///   - author: Creator or producer of the video
    ///   - duration: Length of the video in seconds
    ///   - resolution: Video quality (e.g., "720p", "1080p", "4K")
    public init(
        id: String = UUID().uuidString,
        title: String,
        url: String,
        urlToImage: String? = "https://picsum.photos/800/1200",
        publishedAt: Date = Date(),
        textContent: String? = nil,
        author: String? = nil,
        duration: TimeInterval,
        resolution: String
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.urlToImage = urlToImage
        self.publishedAt = publishedAt
        self.textContent = textContent
        self.author = author
        self.duration = duration
        self.resolution = resolution
    }
    
    /// Determines the appropriate MediaType for this Video.
    public func determineMediaType() -> MediaType {
        return .video
    }
    
    /// Returns a formatted duration string in minutes and seconds.
    ///
    /// - Returns: A string in the format "MM:SS"
    public func formattedDuration() -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

public extension Video {
    /// An example instance of `Video` for previews and testing.
    /// This provides a convenient way to use a realistic video instance
    /// in SwiftUI previews and unit tests.
    static let example = Video(
        title: "Utah News Video Highlights",
        url: "https://www.utahnews.com/video-highlights",
        urlToImage: "https://picsum.photos/800/600",
        textContent: "Watch the latest video highlights from Utah News.",
        author: "Mark Evans",
        duration: 300, // Duration in seconds
        resolution: "1080p"
    )
}