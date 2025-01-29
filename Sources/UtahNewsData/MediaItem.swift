//
//  MediaItem.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//
//  Updated so each media struct defines custom `==` and `hash(into:)`
//  based solely on the `id` property. This prevents duplicated Set entries
//  when other properties (e.g. title, caption) change.
//
//  Copy & Paste this file in place of your existing MediaItem.swift.
//

import SwiftUI

public struct TextMedia: Identifiable, Codable {
    public var id: String
    public var relationships: [Relationship] = []
    public var title: String?
    public var dateCreated: Date
    public var text: String

    public init(
        id: String = UUID().uuidString,
        title: String? = nil,
        text: String,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.text = text
        self.dateCreated = dateCreated
    }
}

extension TextMedia: Equatable, Hashable {
    public static func == (lhs: TextMedia, rhs: TextMedia) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public struct ImageMedia: Identifiable, Codable {
    public var id: String
    public var relationships: [Relationship] = []
    public var title: String?
    public var dateCreated: Date
    public var imageURL: URL
    public var caption: String?
    public var credit: String?

    public init(
        id: String = UUID().uuidString,
        title: String? = nil,
        imageURL: URL,
        caption: String? = nil,
        credit: String? = nil,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
        self.caption = caption
        self.credit = credit
        self.dateCreated = dateCreated
    }
}

extension ImageMedia: Equatable, Hashable {
    public static func == (lhs: ImageMedia, rhs: ImageMedia) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public struct VideoMedia: Identifiable, Codable {
    public var id: String
    public var relationships: [Relationship] = []
    public var title: String?
    public var dateCreated: Date
    public var videoURL: URL
    public var duration: TimeInterval?
    public var thumbnailURL: URL?

    public init(
        id: String = UUID().uuidString,
        title: String? = nil,
        videoURL: URL,
        duration: TimeInterval? = nil,
        thumbnailURL: URL? = nil,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.videoURL = videoURL
        self.duration = duration
        self.thumbnailURL = thumbnailURL
        self.dateCreated = dateCreated
    }
}

extension VideoMedia: Equatable, Hashable {
    public static func == (lhs: VideoMedia, rhs: VideoMedia) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public struct AudioMedia: Identifiable, Codable {
    public var id: String
    public var relationships: [Relationship] = []
    public var title: String?
    public var dateCreated: Date
    public var audioURL: URL
    public var duration: TimeInterval?

    public init(
        id: String = UUID().uuidString,
        title: String? = nil,
        audioURL: URL,
        duration: TimeInterval? = nil,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.audioURL = audioURL
        self.duration = duration
        self.dateCreated = dateCreated
    }
}

extension AudioMedia: Equatable, Hashable {
    public static func == (lhs: AudioMedia, rhs: AudioMedia) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public struct DocumentMedia: Identifiable, Codable {
    public var id: String
    public var relationships: [Relationship] = []
    public var title: String?
    public var dateCreated: Date
    public var documentURL: URL
    public var fileType: String // e.g., "pdf", "docx"

    public init(
        id: String = UUID().uuidString,
        title: String? = nil,
        documentURL: URL,
        fileType: String,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.documentURL = documentURL
        self.fileType = fileType
        self.dateCreated = dateCreated
    }
}

extension DocumentMedia: Equatable, Hashable {
    public static func == (lhs: DocumentMedia, rhs: DocumentMedia) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
