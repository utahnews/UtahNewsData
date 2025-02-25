//
//  MediaItem.swift
//  UtahNewsData
//
//  Created by Mark Evans on 2/12/25.
//

/*
 # MediaItem Model
 
 This file defines the MediaItem model, which represents various types of media content
 in the UtahNewsData system, such as images, videos, audio recordings, and documents.
 MediaItems can be associated with articles, events, and other entities.
 
 ## Key Features:
 
 1. Core identification (id, title)
 2. Media type classification (image, video, audio, document)
 3. Source attribution and metadata
 4. Content description and caption
 5. File information (URL, format, size)
 6. Associated entities
 
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
 let article = Article(
     title: "Utah's Economic Growth Continues",
     body: ["Utah's economy showed strong growth in the first quarter..."],
     mediaItems: [image, video]
 )
 ```
 
 The MediaItem model implements EntityDetailsProvider, allowing it to generate
 rich text descriptions for RAG (Retrieval Augmented Generation) systems.
 */

import Foundation

/// Represents the type of media content
public enum MediaType: String, Codable {
    case image
    case video
    case audio
    case document
    case other
}

/// Represents a media item in the UtahNewsData system, such as images, videos,
/// audio recordings, and documents. MediaItems can be associated with articles,
/// events, and other entities.
public struct MediaItem: Codable, Identifiable, Hashable, Equatable, EntityDetailsProvider {
    /// Unique identifier for the media item
    public var id: String = UUID().uuidString
    
    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []
    
    /// Title or name of the media item
    public var title: String
    
    /// Type of media (image, video, audio, document, other)
    public var type: MediaType
    
    /// URL where the media can be accessed
    public var url: String
    
    /// Alternative text description for accessibility
    public var altText: String?
    
    /// Caption or description of the media content
    public var caption: String?
    
    /// Person or entity that created the media
    public var creator: Person?
    
    /// Organization that provided or published the media
    public var source: Organization?
    
    /// When the media was created or published
    public var creationDate: Date?
    
    /// Duration in seconds (for audio/video)
    public var duration: Double?
    
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
    ///   - title: Title or name of the media item
    ///   - type: Type of media (image, video, audio, document, other)
    ///   - url: URL where the media can be accessed
    ///   - altText: Alternative text description for accessibility
    ///   - caption: Caption or description of the media content
    ///   - creator: Person or entity that created the media
    ///   - source: Organization that provided or published the media
    ///   - creationDate: When the media was created or published
    ///   - duration: Duration in seconds (for audio/video)
    ///   - format: File format (e.g., "jpg", "mp4", "mp3", "pdf")
    ///   - fileSize: File size in bytes
    ///   - width: Width in pixels (for images/videos)
    ///   - height: Height in pixels (for images/videos)
    ///   - tags: Keywords or tags associated with the media
    ///   - location: Geographic location where the media was captured
    public init(
        title: String,
        type: MediaType,
        url: String,
        altText: String? = nil,
        caption: String? = nil,
        creator: Person? = nil,
        source: Organization? = nil,
        creationDate: Date? = nil,
        duration: Double? = nil,
        format: String? = nil,
        fileSize: Int? = nil,
        width: Int? = nil,
        height: Int? = nil,
        tags: [String]? = nil,
        location: Location? = nil
    ) {
        self.title = title
        self.type = type
        self.url = url
        self.altText = altText
        self.caption = caption
        self.creator = creator
        self.source = source
        self.creationDate = creationDate
        self.duration = duration
        self.format = format
        self.fileSize = fileSize
        self.width = width
        self.height = height
        self.tags = tags
        self.location = location
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
        
        if let creator = creator {
            description += "\nCreator: \(creator.name)"
        }
        
        if let source = source {
            description += "\nSource: \(source.name)"
        }
        
        if let creationDate = creationDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            description += "\nCreation Date: \(formatter.string(from: creationDate))"
        }
        
        if let duration = duration {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            description += "\nDuration: \(minutes)m \(seconds)s"
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
