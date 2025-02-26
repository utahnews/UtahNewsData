//
//  MediaItem.swift
//  UtahNewsData
//
//  Created by Mark Evans on 2/12/25.
//

/*
 # MediaItem Model
 
 This file defines the unified MediaItem model, which represents all types of media content
 in the UtahNewsData system, such as images, videos, audio recordings, and documents.
 MediaItems can be associated with articles, events, and other entities.
 
 ## Key Features:
 
 1. Core identification (id, title)
 2. Media type classification (image, video, audio, document)
 3. Source attribution and metadata
 4. Content description and caption
 5. File information (URL, format, size)
 6. Type-specific properties (duration, resolution, etc.)
 7. Associated entities via relationships
 8. RAG support through EntityDetailsProvider
 
 ## Usage:
 
 ```swift
 // Create an image media item
 let image = MediaItem(
     title: "Downtown Salt Lake City Skyline",
     type: .image,
     url: "https://example.com/images/slc-skyline.jpg",
     caption: "View of downtown Salt Lake City with mountains in background",
     creator: photographer // Person entity
 )
 
 // Create a video media item
 let video = MediaItem(
     title: "Governor's Press Conference",
     type: .video,
     url: "https://example.com/videos/governor-presser.mp4",
     duration: 1800, // 30 minutes in seconds
     creator: videoTeam, // Person entity
     source: newsOrganization // Organization entity
 )
 
 // Associate media with an article
 article.relationships.append(Relationship(
     id: image.id,
     type: .mediaItem,
     displayName: "Featured Image"
 ))
 
 // Convert legacy types to MediaItem
 let legacyVideo = Video(title: "Legacy Video", url: "https://example.com/video.mp4", duration: 300, resolution: "1080p")
 let mediaItem = MediaItem.from(legacyVideo)
 ```
 
 The MediaItem model implements AssociatedData and EntityDetailsProvider, allowing it to
 maintain relationships with other entities and generate rich text descriptions for RAG systems.
 */

import Foundation

/// Represents the type of media content
public enum MediaType: String, Codable {
    case image
    case video
    case audio
    case document
    case text
    case other
}

/// Represents a media item in the UtahNewsData system, such as images, videos,
/// audio recordings, documents, and text. MediaItems can be associated with articles,
/// events, and other entities.
public struct MediaItem: AssociatedData, EntityDetailsProvider {
    /// Unique identifier for the media item
    public var id: String = UUID().uuidString
    
    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []
    
    /// Title or name of the media item
    public var title: String
    
    /// Type of media (image, video, audio, document, text, other)
    public var type: MediaType
    
    /// URL where the media can be accessed
    public var url: String
    
    /// Alternative text description for accessibility
    public var altText: String?
    
    /// Caption or description of the media content
    public var caption: String?
    
    /// The main text content, if available (for text type or transcripts)
    public var textContent: String?
    
    /// Person or entity that created the media
    public var creator: Person?
    
    /// Organization that provided or published the media
    public var source: Organization?
    
    /// Author name as string (for backward compatibility)
    public var author: String?
    
    /// When the media was created or published
    public var publishedAt: Date
    
    /// Duration in seconds (for audio/video)
    public var duration: Double?
    
    /// Resolution or quality (for video)
    public var resolution: String?
    
    /// Bitrate in kbps (for audio)
    public var bitrate: Int?
    
    /// File format (e.g., "jpg", "mp4", "mp3", "pdf")
    public var format: String?
    
    /// File size in bytes
    public var fileSize: Int?
    
    /// Width in pixels (for images/videos)
    public var width: Int?
    
    /// Height in pixels (for images/videos)
    public var height: Int?
    
    /// Keywords or tags associated with the media
    public var tags: [String]?
    
    /// Geographic location where the media was captured
    public var location: Location?
    
    /// Creates a new MediaItem with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the media item (defaults to a new UUID string)
    ///   - title: Title or name of the media item
    ///   - type: Type of media (image, video, audio, document, text, other)
    ///   - url: URL where the media can be accessed
    ///   - altText: Alternative text description for accessibility
    ///   - caption: Caption or description of the media content
    ///   - textContent: The main text content, if available
    ///   - creator: Person or entity that created the media
    ///   - source: Organization that provided or published the media
    ///   - author: Author name as string (for backward compatibility)
    ///   - publishedAt: When the media was created or published
    ///   - duration: Duration in seconds (for audio/video)
    ///   - resolution: Resolution or quality (for video)
    ///   - bitrate: Bitrate in kbps (for audio)
    ///   - format: File format (e.g., "jpg", "mp4", "mp3", "pdf")
    ///   - fileSize: File size in bytes
    ///   - width: Width in pixels (for images/videos)
    ///   - height: Height in pixels (for images/videos)
    ///   - tags: Keywords or tags associated with the media
    ///   - location: Geographic location where the media was captured
    public init(
        id: String = UUID().uuidString,
        title: String,
        type: MediaType,
        url: String,
        altText: String? = nil,
        caption: String? = nil,
        textContent: String? = nil,
        creator: Person? = nil,
        source: Organization? = nil,
        author: String? = nil,
        publishedAt: Date = Date(),
        duration: Double? = nil,
        resolution: String? = nil,
        bitrate: Int? = nil,
        format: String? = nil,
        fileSize: Int? = nil,
        width: Int? = nil,
        height: Int? = nil,
        tags: [String]? = nil,
        location: Location? = nil,
        relationships: [Relationship] = []
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.url = url
        self.altText = altText
        self.caption = caption
        self.textContent = textContent
        self.creator = creator
        self.source = source
        self.author = author
        self.publishedAt = publishedAt
        self.duration = duration
        self.resolution = resolution
        self.bitrate = bitrate
        self.format = format
        self.fileSize = fileSize
        self.width = width
        self.height = height
        self.tags = tags
        self.location = location
        self.relationships = relationships
    }
    
    /// The name property required by the AssociatedData protocol.
    /// Returns the title of the media item.
    public var name: String {
        return title
    }
    
    /// Generates a detailed text description of the media item for use in RAG systems.
    /// The description includes the title, type, caption, and metadata.
    ///
    /// - Returns: A formatted string containing the media item's details
    public func getDetailedDescription() -> String {
        var description = "MEDIA ITEM: \(title) (Type: \(type.rawValue))"
        
        if let caption = caption {
            description += "\nCaption: \(caption)"
        }
        
        if let altText = altText {
            description += "\nDescription: \(altText)"
        }
        
        if let textContent = textContent {
            description += "\nContent: \(textContent.prefix(200))"
            if textContent.count > 200 {
                description += "..."
            }
        }
        
        if let creator = creator {
            description += "\nCreator: \(creator.name)"
        } else if let author = author {
            description += "\nAuthor: \(author)"
        }
        
        if let source = source {
            description += "\nSource: \(source.name)"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        description += "\nPublished: \(formatter.string(from: publishedAt))"
        
        if let duration = duration {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            description += "\nDuration: \(minutes)m \(seconds)s"
        }
        
        if let resolution = resolution {
            description += "\nResolution: \(resolution)"
        }
        
        if let bitrate = bitrate {
            description += "\nBitrate: \(bitrate) kbps"
        }
        
        if let location = location {
            description += "\nLocation: \(location.name)"
        }
        
        if let tags = tags, !tags.isEmpty {
            description += "\nTags: \(tags.joined(separator: ", "))"
        }
        
        description += "\nURL: \(url)"
        
        return description
    }
}

// MARK: - Conversion from Legacy Types

public extension MediaItem {
    /// Creates a MediaItem from a legacy Article
    ///
    /// - Parameter article: The legacy Article to convert
    /// - Returns: A new MediaItem with properties from the Article
    static func from(_ article: Article) -> MediaItem {
        return MediaItem(
            id: article.id,
            title: article.title,
            type: .text,
            url: article.url,
            textContent: article.textContent,
            author: article.author,
            publishedAt: article.publishedAt
        )
    }
    
    /// Creates a MediaItem from a legacy Video
    ///
    /// - Parameter video: The legacy Video to convert
    /// - Returns: A new MediaItem with properties from the Video
    static func from(_ video: Video) -> MediaItem {
        return MediaItem(
            id: video.id,
            title: video.title,
            type: .video,
            url: video.url,
            caption: video.textContent,
            author: video.author,
            publishedAt: video.publishedAt,
            duration: video.duration,
            resolution: video.resolution
        )
    }
    
    /// Creates a MediaItem from a legacy Audio
    ///
    /// - Parameter audio: The legacy Audio to convert
    /// - Returns: A new MediaItem with properties from the Audio
    static func from(_ audio: Audio) -> MediaItem {
        return MediaItem(
            id: audio.id,
            title: audio.title,
            type: .audio,
            url: audio.url,
            caption: audio.textContent,
            author: audio.author,
            publishedAt: audio.publishedAt,
            duration: audio.duration
        )
    }
    
    /// Creates a MediaItem from a UserSubmission media type
    ///
    /// - Parameter imageMedia: The ImageMedia to convert
    /// - Returns: A new MediaItem with properties from the ImageMedia
    @available(*, deprecated, message: "Use MediaItem initializer with type .image instead")
    static func from(_ imageMedia: ImageMedia) -> MediaItem {
        return MediaItem(
            id: imageMedia.id,
            title: imageMedia.caption ?? "Image",
            type: .image,
            url: imageMedia.url,
            caption: imageMedia.caption
        )
    }
    
    /// Creates a MediaItem from a UserSubmission media type
    ///
    /// - Parameter videoMedia: The VideoMedia to convert
    /// - Returns: A new MediaItem with properties from the VideoMedia
    @available(*, deprecated, message: "Use MediaItem initializer with type .video instead")
    static func from(_ videoMedia: VideoMedia) -> MediaItem {
        return MediaItem(
            id: videoMedia.id,
            title: videoMedia.caption ?? "Video",
            type: .video,
            url: videoMedia.url,
            caption: videoMedia.caption,
            duration: videoMedia.duration
        )
    }
    
    /// Creates a MediaItem from a UserSubmission media type
    ///
    /// - Parameter audioMedia: The AudioMedia to convert
    /// - Returns: A new MediaItem with properties from the AudioMedia
    @available(*, deprecated, message: "Use MediaItem initializer with type .audio instead")
    static func from(_ audioMedia: AudioMedia) -> MediaItem {
        return MediaItem(
            id: audioMedia.id,
            title: audioMedia.caption ?? "Audio",
            type: .audio,
            url: audioMedia.url,
            caption: audioMedia.caption,
            duration: audioMedia.duration
        )
    }
    
    /// Creates a MediaItem from a legacy DocumentMedia
    ///
    /// - Parameter documentMedia: The DocumentMedia to convert
    /// - Returns: A new MediaItem with properties from the DocumentMedia
    @available(*, deprecated, message: "Use MediaItem initializer with type .document instead")
    static func from(_ documentMedia: DocumentMedia) -> MediaItem {
        return MediaItem(
            id: documentMedia.id,
            title: documentMedia.title ?? "Document",
            type: .document,
            url: documentMedia.url,
            format: "application/pdf" // Default format since DocumentMedia doesn't have a format property
        )
    }
    
    /// Creates a MediaItem from a UserSubmission media type
    ///
    /// - Parameter textMedia: The TextMedia to convert
    /// - Returns: A new MediaItem with properties from the TextMedia
    @available(*, deprecated, message: "Use MediaItem initializer with type .text instead")
    static func from(_ textMedia: TextMedia) -> MediaItem {
        return MediaItem(
            id: textMedia.id,
            title: "Text",
            type: .text,
            url: "",
            textContent: textMedia.content
        )
    }
}
