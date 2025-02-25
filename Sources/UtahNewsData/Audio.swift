//
//  Audio.swift
//  UtahNewsData
//
//  Created by Mark Evans on 11/18/24.
//

/*
 # Audio Model
 
 This file defines the Audio model, which represents audio content in the UtahNewsData
 system. The Audio struct implements the NewsContent protocol, providing a consistent
 interface for working with audio content alongside other news content types.
 
 ## Key Features:
 
 1. Core news content properties (title, URL, publication date)
 2. Audio-specific metadata (duration, bitrate)
 3. Preview support with example instance
 
 ## Usage:
 
 ```swift
 // Create an audio instance
 let podcast = Audio(
     title: "Utah Politics Weekly Podcast",
     url: "https://www.utahnews.com/podcasts/politics-weekly-ep45",
     urlToImage: "https://www.utahnews.com/images/podcast-cover.jpg",
     publishedAt: Date(),
     textContent: "This week we discuss the latest developments in Utah politics",
     author: "Jane Smith",
     duration: 2400, // 40 minutes in seconds
     bitrate: 192 // 192 kbps
 )
 
 // Access audio properties
 print("Podcast: \(podcast.title)")
 print("Duration: \(Int(podcast.duration / 60)) minutes")
 print("Audio Quality: \(podcast.bitrate) kbps")
 
 // Use in a list with other news content types
 let newsItems: [NewsContent] = [article1, podcast, video]
 for item in newsItems {
     print(item.basicInfo())
 }
 ```
 
 The Audio model is designed to work seamlessly with UI components that display
 news content, while providing additional properties specific to audio content.
 */

import Foundation

/// A struct representing an audio clip in the news app.
/// Audio clips are a type of news content with additional properties for
/// duration and audio quality (bitrate).
public struct Audio: NewsContent {
    /// Unique identifier for the audio clip
    public var id: UUID
    
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
    ///   - id: Unique identifier for the audio clip (defaults to a new UUID)
    ///   - title: Title or name of the audio clip
    ///   - url: URL where the audio can be accessed
    ///   - urlToImage: URL to an image representing the audio (defaults to a placeholder)
    ///   - publishedAt: When the audio was published (defaults to current date)
    ///   - textContent: Description or transcript of the audio
    ///   - author: Creator or producer of the audio
    ///   - duration: Length of the audio in seconds
    ///   - bitrate: Audio quality in kilobits per second (kbps)
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
}

public extension Audio {
    /// An example instance of `Audio` for previews and testing.
    /// This provides a convenient way to use a realistic audio instance
    /// in SwiftUI previews and unit tests.
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
