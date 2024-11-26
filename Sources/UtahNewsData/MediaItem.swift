//
//  MediaItem.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

import SwiftUI


public protocol MediaItem: AssociatedData, Codable {
    public var type: MediaType { get }
    public var title: String? { get set }
    public var dateCreated: Date { get }
}

public enum MediaType: String, Identifiable, Codable {
    case text
    case image
    case video
    case audio
    case document
    
   public var id: MediaType { self }
}

public struct TextMedia: MediaItem {
    public var id: UUID
    public var relationships: [Relationship] = []
    public var type: MediaType = .text
    public var title: String?
    public var dateCreated: Date
    public var text: String

    init(id: UUID = UUID(), title: String? = nil, text: String, dateCreated: Date = Date()) {
        self.id = id
        self.title = title
        self.text = text
        self.dateCreated = dateCreated
    }
}

public struct ImageMedia: MediaItem {
    public var id: UUID
    public var relationships: [Relationship] = []
    public var type: MediaType = .image
    public var title: String?
    public var dateCreated: Date
    public var imageURL: URL
    public var caption: String?
    public var credit: String?

    init(id: UUID = UUID(), title: String? = nil, imageURL: URL, caption: String? = nil, credit: String? = nil, dateCreated: Date = Date()) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
        self.caption = caption
        self.credit = credit
        self.dateCreated = dateCreated
    }
}


public struct VideoMedia: MediaItem {
    public var id: UUID
    public var relationships: [Relationship] = []
    public var type: MediaType = .video
    public var title: String?
    public var dateCreated: Date
    public var videoURL: URL
    public var duration: TimeInterval?
    public var thumbnailURL: URL?

    init(id: UUID = UUID(), title: String? = nil, videoURL: URL, duration: TimeInterval? = nil, thumbnailURL: URL? = nil, dateCreated: Date = Date()) {
        self.id = id
        self.title = title
        self.videoURL = videoURL
        self.duration = duration
        self.thumbnailURL = thumbnailURL
        self.dateCreated = dateCreated
    }
}


public struct AudioMedia: MediaItem {
    public var id: UUID
    public var relationships: [Relationship] = []
    public var type: MediaType = .audio
    public var title: String?
    public var dateCreated: Date
    public var audioURL: URL
    public var duration: TimeInterval?

    init(id: UUID = UUID(), title: String? = nil, audioURL: URL, duration: TimeInterval? = nil, dateCreated: Date = Date()) {
        self.id = id
        self.title = title
        self.audioURL = audioURL
        self.duration = duration
        self.dateCreated = dateCreated
    }
}


public struct DocumentMedia: MediaItem {
    public var id: UUID
    public var relationships: [Relationship] = []
    public var type: MediaType = .document
    public var title: String?
    public var dateCreated: Date
    public var documentURL: URL
    public var fileType: String // e.g., "pdf", "docx"

    init(id: UUID = UUID(), title: String? = nil, documentURL: URL, fileType: String, dateCreated: Date = Date()) {
        self.id = id
        self.title = title
        self.documentURL = documentURL
        self.fileType = fileType
        self.dateCreated = dateCreated
    }
}
