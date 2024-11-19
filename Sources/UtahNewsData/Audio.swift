//
//  Audio.swift
//  UtahNewsData
//
//  Created by Mark Evans on 11/18/24.
//

import Foundation

/// A struct representing an audio clip in the news app.
public struct Audio: NewsContent {
    public var id: UUID
    public var title: String
    public var url: String
    public var urlToImage: String?
    public var publishedAt: Date
    public var textContent: String?
    public var author: String?
    public var duration: TimeInterval
    public var bitrate: Int
    
    public init(
        id: UUID = UUID(),
        title: String,
        url: String,
        urlToImage: String? = "https://picsum.photos/800/1200",
        publishedAt: Date = Date(),
        textContent: String? = nil,
        author: String? = nil,
        duration: TimeInterval,
        bitrate: Int
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.urlToImage = urlToImage
        self.publishedAt = publishedAt
        self.textContent = textContent
        self.author = author
        self.duration = duration
        self.bitrate = bitrate
    }
}

public extension Audio {
    /// An example instance of `Audio` for previews and testing.
    @MainActor static let example = Audio(
        title: "Utah News Podcast Episode 1",
        url: "https://www.utahnews.com/podcast-episode-1",
        urlToImage: "https://picsum.photos/800/600",
        textContent: "Listen to the first episode of the Utah News podcast.",
        author: "Mark Evans",
        duration: 1800, // Duration in seconds
        bitrate: 256   // Bitrate in kbps
    )
}
