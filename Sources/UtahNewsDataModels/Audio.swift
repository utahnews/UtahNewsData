//
//  Audio.swift
//  UtahNewsDataModels
//
//  Created by Mark Evans on 01/29/25
//
//  Summary: Defines the Audio model which represents audio content in the UtahNewsDataModels system.
//           Lightweight version without HTML parsing capabilities.

import Foundation

/// A struct representing an audio clip in the news app.
/// Audio content is a type of news content with additional properties for
/// duration and bitrate.
public struct Audio: NewsContent, BaseEntity, JSONSchemaProvider, Sendable {
    /// Unique identifier for the audio clip
    public var id: String

    /// The name of the entity (derived from the title)
    public var name: String { title }

    /// Title or name of the audio clip
    public var title: String

    /// URL where the audio can be accessed
    public var url: String

    /// URL to an image representing the audio (e.g., podcast cover art)
    public var urlToImage: String?

    /// When the audio was published
    public var publishedAt: Date

    /// Description or transcript of the audio
    public var textContent: String?

    /// Creator or producer of the audio
    public var author: String?

    /// Length of the audio in seconds
    public var duration: TimeInterval

    /// Audio quality in kilobits per second (kbps)
    public var bitrate: Int

    /// Creates a new audio clip with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the audio clip (defaults to a new UUID string)
    ///   - title: Title or name of the audio clip
    ///   - url: URL where the audio can be accessed
    ///   - urlToImage: URL to an image representing the audio (defaults to a placeholder)
    ///   - publishedAt: When the audio was published (defaults to current date)
    ///   - textContent: Description or transcript of the audio
    ///   - author: Creator or producer of the audio
    ///   - duration: Length of the audio in seconds
    ///   - bitrate: Audio quality in kilobits per second (kbps)
    public init(
        id: String = UUID().uuidString,
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

    /// Determines the appropriate MediaType for this Audio.
    public func determineMediaType() -> MediaType {
        return .audio
    }

    /// Returns a formatted duration string in minutes and seconds.
    ///
    /// - Returns: A string in the format "MM:SS"
    public func formattedDuration() -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Returns a formatted bitrate string.
    ///
    /// - Returns: A string in the format "X kbps"
    public func formattedBitrate() -> String {
        return "\(bitrate) kbps"
    }

    // MARK: - JSON Schema Provider
    
    /// Provides the JSON schema for Audio.
    public static var jsonSchema: String {
        return """
            {
                "type": "object",
                "properties": {
                    "id": {"type": "string"},
                    "title": {"type": "string"},
                    "url": {"type": "string"},
                    "urlToImage": {"type": ["string", "null"]},
                    "publishedAt": {"type": "string", "format": "date-time"},
                    "textContent": {"type": ["string", "null"]},
                    "author": {"type": ["string", "null"]},
                    "duration": {"type": "number"},
                    "bitrate": {"type": "integer"}
                },
                "required": ["id", "title", "url", "publishedAt", "duration", "bitrate"]
            }
            """
    }
}

public extension Audio {
    /// An example instance of `Audio` for previews and testing.
    static let example = Audio(
        title: "Utah News Podcast Episode 1",
        url: "https://www.utahnews.com/podcast-episode-1",
        urlToImage: "https://picsum.photos/800/600",
        textContent: "Listen to the first episode of the Utah News podcast.",
        author: "Mark Evans",
        duration: 1800,  // Duration in seconds
        bitrate: 256  // Bitrate in kbps
    )
}