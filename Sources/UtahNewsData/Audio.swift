//
//  Audio.swift
//  UtahNewsData
//
//  Created by Mark Evans on 11/18/24.
//

import SwiftUI
import SwiftData

/// A model representing an audio clip in the news app.
@Model
public final class Audio: NewsContent, Equatable, Hashable {
    public var id: UUID
    public var title: String
    public var url: String
    public var urlToImage: String?
    public var publishedAt: Date
    public var textContent: String?
    public var duration: TimeInterval
    public var bitrate: Int
    public var author: String?
    
    public init(
        id: UUID = UUID(),
        title: String,
        url: String,
        urlToImage: String? = nil,
        publishedAt: Date,
        textContent: String? = nil,
        duration: TimeInterval,
        bitrate: Int,
        author: String? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.urlToImage = urlToImage
        self.publishedAt = publishedAt
        self.textContent = textContent
        self.duration = duration
        self.bitrate = bitrate
        self.author = author
    }
    
    // MARK: - Equatable Conformance
    public static func == (lhs: Audio, rhs: Audio) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Hashable Conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public extension Audio {
    /// An example instance of `Audio` for previews and testing.
    @MainActor static let example = Audio(
        title: "Utah News Podcast Episode 1",
        url: "https://www.utahnews.com/podcast-episode-1",
        urlToImage: "https://picsum.photos/800/600",
        publishedAt: Date(),
        textContent: "Listen to the first episode of the Utah News podcast.",
        duration: 1800, // Duration in seconds
        bitrate: 256,   // Bitrate in kbps
        author: "Mark Evans"
    )
}
