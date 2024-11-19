//
//  Video.swift
//  UtahNewsData
//
//  Created by Mark Evans on 11/18/24.
//

import Foundation

/// A struct representing a video in the news app.
public struct Video: NewsContent {
    public var id: UUID
    public var title: String
    public var url: String
    public var urlToImage: String?
    public var publishedAt: Date
    public var textContent: String?
    public var author: String?
    public var duration: TimeInterval
    public var resolution: String
    
    public init(
        id: UUID = UUID(),
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
}

public extension Video {
    /// An example instance of `Video` for previews and testing.
    @MainActor static let example = Video(
        title: "Utah News Video Highlights",
        url: "https://www.utahnews.com/video-highlights",
        urlToImage: "https://picsum.photos/800/600",
        textContent: "Watch the latest video highlights from Utah News.",
        author: "Mark Evans",
        duration: 300, // Duration in seconds
        resolution: "1080p"
    )
}
