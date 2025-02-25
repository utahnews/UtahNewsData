//
//  UserSubmission.swift
//  UtahNewsData
//
//  Created by Mark Evans on 1/28/25.
//

/*
 # UserSubmission Model
 
 This file defines the UserSubmission model, which represents content submitted by users
 to the UtahNewsData system. User submissions can include various types of media content
 such as text, images, videos, audio, and documents.
 
 ## Key Features:
 
 1. Core submission metadata (title, description, submission date)
 2. User attribution (who submitted the content)
 3. Multiple media type support (text, images, videos, audio, documents)
 4. Relationship tracking with other entities
 
 ## Usage:
 
 ```swift
 // Create a user submission with text and an image
 let submission = UserSubmission(
     id: UUID().uuidString,
     relationships: [],
     title: "Traffic accident on Main Street",
     description: "I witnessed a car accident at the intersection of Main and State",
     user: currentUser,
     text: [TextMedia(content: "The accident happened around 2:30 PM...")],
     images: [ImageMedia(url: "https://example.com/accident-photo.jpg")]
 )
 
 // Add the submission to the system
 dataStore.addUserSubmission(submission)
 ```
 
 UserSubmission implements AssociatedData, allowing it to maintain relationships
 with other entities in the system, such as locations, events, or people mentioned
 in the submission.
 */

import Foundation

/// Represents content submitted by users to the news system.
/// User submissions can include various types of media content such as
/// text, images, videos, audio, and documents.
public struct UserSubmission: AssociatedData, Codable, Identifiable, Hashable {
    /// Unique identifier for the submission
    public var id: String
    
    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []
    
    /// Title or headline of the submission
    public var title: String
    
    /// Detailed description of the submission
    public var description: String
    
    /// When the content was submitted
    public var dateSubmitted: Date
    
    /// User who submitted the content
    public var user: Person
    
    /// Text content included in the submission
    public var text: [TextMedia]
    
    /// Image content included in the submission
    public var images: [ImageMedia]
    
    /// Video content included in the submission
    public var videos: [VideoMedia]
    
    /// Audio content included in the submission
    public var audio: [AudioMedia]
    
    /// Document content included in the submission
    public var documents: [DocumentMedia]
    
    /// Creates a new user submission with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the submission
    ///   - relationships: Relationships to other entities in the system
    ///   - title: Title or headline of the submission
    ///   - description: Detailed description of the submission
    ///   - dateSubmitted: When the content was submitted (defaults to current date)
    ///   - user: User who submitted the content
    ///   - text: Text content included in the submission
    ///   - images: Image content included in the submission
    ///   - videos: Video content included in the submission
    ///   - audio: Audio content included in the submission
    ///   - documents: Document content included in the submission
    public init(
        id: String,
        relationships: [Relationship],
        title: String,
        description: String = "",
        dateSubmitted: Date = Date(),
        user: Person,
        text: [TextMedia] = [],
        images: [ImageMedia] = [],
        videos: [VideoMedia] = [],
        audio: [AudioMedia] = [],
        documents: [DocumentMedia] = []
    ) {
        self.id = id
        self.relationships = relationships
        self.title = title
        self.description = description
        self.dateSubmitted = dateSubmitted
        self.user = user
        self.text = text
        self.images = images
        self.videos = videos
        self.audio = audio
        self.documents = documents
    }
    
    /// The name property required by the AssociatedData protocol.
    /// Returns the title of the submission.
    public var name: String {
        return title
    }
}

/// Represents text content in a user submission
public struct TextMedia: Codable, Hashable {
    /// Unique identifier for the text content
    public var id: String = UUID().uuidString
    
    /// The text content
    public var content: String
    
    /// Creates new text content with the specified content.
    ///
    /// - Parameter content: The text content
    public init(content: String) {
        self.content = content
    }
}

/// Represents image content in a user submission
public struct ImageMedia: Codable, Hashable {
    /// Unique identifier for the image
    public var id: String = UUID().uuidString
    
    /// URL where the image can be accessed
    public var url: String
    
    /// Caption or description of the image
    public var caption: String?
    
    /// Creates new image content with the specified properties.
    ///
    /// - Parameters:
    ///   - url: URL where the image can be accessed
    ///   - caption: Caption or description of the image
    public init(url: String, caption: String? = nil) {
        self.url = url
        self.caption = caption
    }
}

/// Represents video content in a user submission
public struct VideoMedia: Codable, Hashable {
    /// Unique identifier for the video
    public var id: String = UUID().uuidString
    
    /// URL where the video can be accessed
    public var url: String
    
    /// Caption or description of the video
    public var caption: String?
    
    /// Duration of the video in seconds
    public var duration: Double?
    
    /// Creates new video content with the specified properties.
    ///
    /// - Parameters:
    ///   - url: URL where the video can be accessed
    ///   - caption: Caption or description of the video
    ///   - duration: Duration of the video in seconds
    public init(url: String, caption: String? = nil, duration: Double? = nil) {
        self.url = url
        self.caption = caption
        self.duration = duration
    }
}

/// Represents audio content in a user submission
public struct AudioMedia: Codable, Hashable {
    /// Unique identifier for the audio
    public var id: String = UUID().uuidString
    
    /// URL where the audio can be accessed
    public var url: String
    
    /// Caption or description of the audio
    public var caption: String?
    
    /// Duration of the audio in seconds
    public var duration: Double?
    
    /// Creates new audio content with the specified properties.
    ///
    /// - Parameters:
    ///   - url: URL where the audio can be accessed
    ///   - caption: Caption or description of the audio
    ///   - duration: Duration of the audio in seconds
    public init(url: String, caption: String? = nil, duration: Double? = nil) {
        self.url = url
        self.caption = caption
        self.duration = duration
    }
}

/// Represents document content in a user submission
public struct DocumentMedia: Codable, Hashable {
    /// Unique identifier for the document
    public var id: String = UUID().uuidString
    
    /// URL where the document can be accessed
    public var url: String
    
    /// Title or name of the document
    public var title: String?
    
    /// Type or format of the document (e.g., "pdf", "docx")
    public var documentType: String?
    
    /// Creates new document content with the specified properties.
    ///
    /// - Parameters:
    ///   - url: URL where the document can be accessed
    ///   - title: Title or name of the document
    ///   - documentType: Type or format of the document
    public init(url: String, title: String? = nil, documentType: String? = nil) {
        self.url = url
        self.title = title
        self.documentType = documentType
    }
}
