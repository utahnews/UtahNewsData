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
 3. Multiple media item support using the unified MediaItem model
 4. Relationship tracking with other entities

 ## Usage:

 ```swift
 // Create a user submission with text and an image
 let submission = UserSubmission(
     id: UUID().uuidString,
     title: "Traffic accident on Main Street",
     description: "I witnessed a car accident at the intersection of Main and State",
     user: currentUser,
     mediaItems: [
         MediaItem(title: "Description", type: .text, url: "", textContent: "The accident happened around 2:30 PM..."),
         MediaItem(title: "Photo", type: .image, url: "https://example.com/accident-photo.jpg")
     ]
 )

 // Add the submission to the system
 dataStore.addUserSubmission(submission)

 // Add a relationship to a location
 let location = Location(name: "Main Street and State Street")
 submission.relationships.append(Relationship(
     id: location.id,
     type: .location,
     displayName: "Location"
 ))
 ```

 UserSubmission implements AssociatedData, allowing it to maintain relationships
 with other entities in the system, such as locations, events, or people mentioned
 in the submission.
 */

import Foundation

/// Represents content submitted by users to the news system.
/// User submissions can include various types of media content such as
/// text, images, videos, audio, and documents.
public struct UserSubmission: AssociatedData, EntityDetailsProvider, JSONSchemaProvider {
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

    /// Media items included in the submission
    public var mediaItems: [MediaItem]

    /// Creates a new user submission with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the submission
    ///   - title: Title or headline of the submission
    ///   - description: Detailed description of the submission
    ///   - dateSubmitted: When the content was submitted (defaults to current date)
    ///   - user: User who submitted the content
    ///   - mediaItems: Media items included in the submission
    ///   - relationships: Relationships to other entities in the system
    public init(
        id: String = UUID().uuidString,
        title: String,
        description: String = "",
        dateSubmitted: Date = Date(),
        user: Person,
        mediaItems: [MediaItem] = [],
        relationships: [Relationship] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.dateSubmitted = dateSubmitted
        self.user = user
        self.mediaItems = mediaItems
        self.relationships = relationships
    }

    /// The name property required by the AssociatedData protocol.
    /// Returns the title of the submission.
    public var name: String {
        return title
    }

    /// Generates a detailed text description of the user submission for use in RAG systems.
    /// The description includes the title, description, user information, and media items.
    ///
    /// - Returns: A formatted string containing the submission's details
    public func getDetailedDescription() -> String {
        var description = "USER SUBMISSION: \(title)"
        description += "\nDescription: \(self.description)"
        description += "\nSubmitted by: \(user.name) on \(formatDate(dateSubmitted))"

        if !mediaItems.isEmpty {
            description += "\n\nMedia Items:"
            for (index, item) in mediaItems.enumerated() {
                description += "\n\n[\(index + 1)] \(item.getDetailedDescription())"
            }
        }

        return description
    }

    /// Helper method to format a date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// JSON schema for LLM responses
    public static var jsonSchema: String {
        """
        {
            "type": "object",
            "properties": {
                "id": {"type": "string"},
                "title": {"type": "string"},
                "description": {"type": "string"},
                "user": {"$ref": "#/definitions/Person"},
                "submissionDate": {"type": "string", "format": "date-time"},
                "mediaItems": {
                    "type": "array",
                    "items": {"$ref": "#/definitions/MediaItem"},
                    "optional": true
                },
                "status": {
                    "type": "string",
                    "enum": ["pending", "approved", "rejected", "archived"],
                    "optional": true
                },
                "moderatorNotes": {"type": "string", "optional": true},
                "tags": {
                    "type": "array",
                    "items": {"type": "string"},
                    "optional": true
                },
                "location": {"$ref": "#/definitions/Location", "optional": true},
                "metadata": {
                    "type": "object",
                    "additionalProperties": true,
                    "optional": true
                }
            },
            "required": ["id", "title", "description", "user", "submissionDate"],
            "definitions": {
                "Person": {"$ref": "Person.jsonSchema"},
                "MediaItem": {"$ref": "MediaItem.jsonSchema"},
                "Location": {"$ref": "Location.jsonSchema"}
            }
        }
        """
    }
}

// MARK: - Legacy Support

/// Extension to provide backward compatibility with the old media type model
extension UserSubmission {
    /// Creates a UserSubmission from the legacy model that used separate media type arrays
    ///
    /// - Parameters:
    ///   - legacySubmission: The legacy UserSubmission with separate media arrays
    /// - Returns: A new UserSubmission with a unified mediaItems array
    public static func fromLegacy(
        id: String,
        title: String,
        description: String,
        dateSubmitted: Date,
        user: Person,
        mediaItems: [MediaItem],
        relationships: [Relationship] = []
    ) -> UserSubmission {
        return UserSubmission(
            id: id,
            title: title,
            description: description,
            dateSubmitted: dateSubmitted,
            user: user,
            mediaItems: mediaItems,
            relationships: relationships
        )
    }
}

// MARK: - Legacy Media Types (Deprecated)

/// A text-based media item in a user submission
@available(*, unavailable, message: "Use MediaItem with type .text instead")
public struct TextMedia: BaseEntity, Codable, Hashable, Sendable {
    /// Unique identifier for the text media
    public var id: String

    /// The text content
    public var content: String

    /// The name of the text media, used for display and embedding generation
    public var name: String {
        return content.prefix(50) + (content.count > 50 ? "..." : "")
    }

    /// Creates a new text media item
    public init(id: String = UUID().uuidString, content: String) {
        self.id = id
        self.content = content
    }
}

/// An image media item in a user submission
@available(*, unavailable, message: "Use MediaItem with type .image instead")
public struct ImageMedia: BaseEntity, Codable, Hashable, Sendable {
    /// Unique identifier for the image media
    public var id: String

    /// URL or path to the image
    public var url: String

    /// Caption or description of the image
    public var caption: String?

    /// The name of the image media, used for display and embedding generation
    public var name: String {
        return caption ?? "Image \(id)"
    }

    /// Creates a new image media item
    public init(id: String = UUID().uuidString, url: String, caption: String? = nil) {
        self.id = id
        self.url = url
        self.caption = caption
    }
}

/// A video media item in a user submission
@available(*, unavailable, message: "Use MediaItem with type .video instead")
public struct VideoMedia: BaseEntity, Codable, Hashable, Sendable {
    /// Unique identifier for the video media
    public var id: String

    /// URL or path to the video
    public var url: String

    /// Caption or description of the video
    public var caption: String?

    /// Duration of the video in seconds
    public var duration: TimeInterval?

    /// The name of the video media, used for display and embedding generation
    public var name: String {
        return caption ?? "Video \(id)"
    }

    /// Creates a new video media item
    public init(
        id: String = UUID().uuidString, url: String, caption: String? = nil,
        duration: TimeInterval? = nil
    ) {
        self.id = id
        self.url = url
        self.caption = caption
        self.duration = duration
    }
}

/// An audio media item in a user submission
@available(*, unavailable, message: "Use MediaItem with type .audio instead")
public struct AudioMedia: BaseEntity, Codable, Hashable, Sendable {
    /// Unique identifier for the audio media
    public var id: String

    /// URL or path to the audio
    public var url: String

    /// Caption or description of the audio
    public var caption: String?

    /// Duration of the audio in seconds
    public var duration: TimeInterval?

    /// The name of the audio media, used for display and embedding generation
    public var name: String {
        return caption ?? "Audio \(id)"
    }

    /// Creates a new audio media item
    public init(
        id: String = UUID().uuidString, url: String, caption: String? = nil,
        duration: TimeInterval? = nil
    ) {
        self.id = id
        self.url = url
        self.caption = caption
        self.duration = duration
    }
}

/// A document media item in a user submission
@available(*, unavailable, message: "Use MediaItem with type .document instead")
public struct DocumentMedia: BaseEntity, Codable, Hashable, Sendable {
    /// Unique identifier for the document media
    public var id: String

    /// URL or path to the document
    public var url: String

    /// Title or name of the document
    public var title: String?

    /// Description of the document
    public var description: String?

    /// The name of the document media, used for display and embedding generation
    public var name: String {
        return title ?? "Document \(id)"
    }

    /// Creates a new document media item
    public init(
        id: String = UUID().uuidString, url: String, title: String? = nil,
        description: String? = nil
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.description = description
    }
}
