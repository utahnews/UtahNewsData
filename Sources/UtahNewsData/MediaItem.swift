//
//  MediaItem.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

import SwiftUI



public struct TextMedia: Identifiable, Codable, Hashable {
    public var id: String
    public var relationships: [Relationship] = []
    public var title: String?
    public var dateCreated: Date
    public var text: String

    public init(id: String = UUID().uuidString, title: String? = nil, text: String, dateCreated: Date = Date()) {
        self.id = id
        self.title = title
        self.text = text
        self.dateCreated = dateCreated
    }
}

public struct ImageMedia: Identifiable, Codable, Hashable {
    public var id: String
    public var relationships: [Relationship] = []
    public var title: String?
    public var dateCreated: Date
    public var imageURL: URL
    public var caption: String?
    public var credit: String?

    public init(id: String = UUID().uuidString, title: String? = nil, imageURL: URL, caption: String? = nil, credit: String? = nil, dateCreated: Date = Date()) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
        self.caption = caption
        self.credit = credit
        self.dateCreated = dateCreated
    }
}


public struct VideoMedia: Hashable {
    public var id: String
    public var relationships: [Relationship] = []
    public var title: String?
    public var dateCreated: Date
    public var videoURL: URL
    public var duration: TimeInterval?
    public var thumbnailURL: URL?

    public init(id: String = UUID().uuidString, title: String? = nil, videoURL: URL, duration: TimeInterval? = nil, thumbnailURL: URL? = nil, dateCreated: Date = Date()) {
        self.id = id
        self.title = title
        self.videoURL = videoURL
        self.duration = duration
        self.thumbnailURL = thumbnailURL
        self.dateCreated = dateCreated
    }
}


public struct AudioMedia: Identifiable, Codable, Hashable {
    public var id: String
    public var relationships: [Relationship] = []
    public var title: String?
    public var dateCreated: Date
    public var audioURL: URL
    public var duration: TimeInterval?

    public init(id: String = UUID().uuidString, title: String? = nil, audioURL: URL, duration: TimeInterval? = nil, dateCreated: Date = Date()) {
        self.id = id
        self.title = title
        self.audioURL = audioURL
        self.duration = duration
        self.dateCreated = dateCreated
    }
}


public struct DocumentMedia: Identifiable, Codable, Hashable {
    public var id: String
    public var relationships: [Relationship] = []
    public var title: String?
    public var dateCreated: Date
    public var documentURL: URL
    public var fileType: String // e.g., "pdf", "docx"

 public init(id: String = UUID().uuidString, title: String? = nil, documentURL: URL, fileType: String, dateCreated: Date = Date()) {
        self.id = id
        self.title = title
        self.documentURL = documentURL
        self.fileType = fileType
        self.dateCreated = dateCreated
    }
}
