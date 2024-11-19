//
//  Video.swift
//  UtahNewsData
//
//  Created by Mark Evans on 11/18/24.
//

import SwiftUI
import SwiftData

/// A model representing a video in the news app.
@Model
public final class Video: NewsContent, Equatable, Hashable {
    public var id: UUID
    public var title: String
    public var url: String
    public var urlToImage: String?
    public var publishedAt: Date
    public var textContent: String?
    public var duration: TimeInterval
    public var resolution: String
    public var author: String?
    
    public init(
        id: UUID = UUID(),
        title: String,
        url: String,
        urlToImage: String? = nil,
        publishedAt: Date,
        textContent: String? = nil,
        duration: TimeInterval,
        resolution: String,
        author: String? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.urlToImage = urlToImage
        self.publishedAt = publishedAt
        self.textContent = textContent
        self.duration = duration
        self.resolution = resolution
        self.author = author
    }
    
    // MARK: - Equatable Conformance
    public static func == (lhs: Video, rhs: Video) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Hashable Conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public extension Video {
    /// An example instance of `Video` for previews and testing.
    @MainActor static let example = Video(
        title: "Utah News Video Highlights",
        url: "https://www.utahnews.com/video-highlights",
        urlToImage: "https://picsum.photos/800/600",
        publishedAt: Date(),
        textContent: "Watch the latest video highlights from Utah News.",
        duration: 300, // Duration in seconds
        resolution: "1080p",
        author: "Mark Evans"
    )
}
