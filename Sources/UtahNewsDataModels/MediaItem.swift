//
//  MediaItem.swift
//  UtahNewsDataModels
//
//  Created by Mark Evans on 01/29/25
//
//  Summary: Defines the unified MediaItem model which represents all types of media content
//           in the UtahNewsDataModels system. Lightweight version without heavy dependencies.

import Foundation

/// Represents a media item in the UtahNewsDataModels system, such as images, videos,
/// audio recordings, documents, and text. MediaItems can be associated with articles,
/// events, and other entities.
public struct MediaItem: AssociatedData, JSONSchemaProvider, Sendable {
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

    /// Metadata associated with the media item
    public var metadata: [String: String] = [:]

    /// Creates a new MediaItem with the specified properties.
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
        relationships: [Relationship] = [],
        metadata: [String: String] = [:]
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
        self.metadata = metadata
    }

    /// The name property required by the AssociatedData protocol.
    /// Returns the title of the media item.
    public var name: String {
        return title
    }

    /// JSON schema for LLM responses
    public static var jsonSchema: String {
        """
        {
            "type": "object",
            "properties": {
                "id": {"type": "string"},
                "title": {"type": "string"},
                "type": {
                    "type": "string",
                    "enum": ["article", "image", "video", "audio", "document"]
                },
                "url": {"type": "string", "format": "uri"},
                "caption": {"type": "string", "optional": true},
                "description": {"type": "string", "optional": true},
                "creator": {"$ref": "#/definitions/Person", "optional": true},
                "source": {"$ref": "#/definitions/Organization", "optional": true},
                "dateCreated": {"type": "string", "format": "date-time", "optional": true},
                "dateModified": {"type": "string", "format": "date-time", "optional": true},
                "fileSize": {"type": "integer", "optional": true},
                "fileFormat": {"type": "string", "optional": true},
                "duration": {"type": "number", "optional": true},
                "resolution": {"type": "string", "optional": true},
                "width": {"type": "integer", "optional": true},
                "height": {"type": "integer", "optional": true},
                "tags": {
                    "type": "array",
                    "items": {"type": "string"},
                    "optional": true
                },
                "metadata": {
                    "type": "object",
                    "additionalProperties": true,
                    "optional": true
                }
            },
            "required": ["id", "title", "type", "url"],
            "definitions": {
                "Person": {"$ref": "Person.jsonSchema"},
                "Organization": {"$ref": "Organization.jsonSchema"}
            }
        }
        """
    }
}

// MARK: - Convenience Extensions

public extension MediaItem {
    /// Creates a MediaItem from a file URL and a given media type.
    init(
        sourceURL: URL, type: MediaType, title: String = "", textContent: String? = nil,
        fileType: String? = nil
    ) {
        self.init(
            title: title,
            type: type,
            url: sourceURL.absoluteString,
            altText: nil,
            caption: nil,
            textContent: textContent,
            creator: nil,
            source: nil,
            author: nil,
            publishedAt: Date()
        )
        self.format = fileType
    }
}

// MARK: - Conversion from Content Types

public extension MediaItem {
    /// Creates a MediaItem from an Article
    ///
    /// - Parameter article: The Article to convert
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

    /// Creates a MediaItem from a Video
    ///
    /// - Parameter video: The Video to convert
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

    /// Creates a MediaItem from an Audio
    ///
    /// - Parameter audio: The Audio to convert
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
}