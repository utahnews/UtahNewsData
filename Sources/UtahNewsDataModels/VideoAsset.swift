//
//  VideoAsset.swift
//  UtahNewsDataModels
//
//  Created by Claude Code on 10/10/25.
//

import Foundation

#if canImport(CloudKit)
import CloudKit
#endif

/// Represents a video asset stored in CloudKit Public Database
public struct VideoAsset: Identifiable, Codable, Sendable, Hashable {
    public let id: String
    public var title: String
    public var slug: String
    public var manifestURL: URL
    public var thumbnailURL: URL?
    public var duration: Double
    public var resolution: String
    public var publishedAt: Date
    public var author: String
    public var textContent: String

    /// Initialize from CloudKit record
    #if canImport(CloudKit)
    public init(record: CKRecord) {
        id = record.recordID.recordName
        title = record["title"] as? String ?? "Untitled Video"
        slug = record["slug"] as? String ?? ""

        // Extract manifest URL from CloudKit Asset
        if let manifestAsset = record["manifest"] as? CKAsset,
           let url = manifestAsset.fileURL {
            manifestURL = url
        } else {
            // Fallback URL if asset is missing
            manifestURL = URL(string: "about:blank")!
        }

        // Extract thumbnail URL from CloudKit Asset
        if let thumbnailAsset = record["thumbnail"] as? CKAsset {
            thumbnailURL = thumbnailAsset.fileURL
        } else {
            thumbnailURL = nil
        }

        duration = record["duration"] as? Double ?? 0.0
        resolution = record["resolution"] as? String ?? "1080p"
        publishedAt = record["publishedAt"] as? Date ?? Date()
        author = record["author"] as? String ?? "Unknown"
        textContent = record["description"] as? String ?? ""
    }
    #endif

    /// Manual initializer for testing and manual creation
    public init(
        id: String = UUID().uuidString,
        title: String,
        slug: String,
        manifestURL: URL,
        thumbnailURL: URL? = nil,
        duration: Double = 0,
        resolution: String = "1080p",
        publishedAt: Date = Date(),
        author: String = "Unknown",
        textContent: String = ""
    ) {
        self.id = id
        self.title = title
        self.slug = slug
        self.manifestURL = manifestURL
        self.thumbnailURL = thumbnailURL
        self.duration = duration
        self.resolution = resolution
        self.publishedAt = publishedAt
        self.author = author
        self.textContent = textContent
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: VideoAsset, rhs: VideoAsset) -> Bool {
        lhs.id == rhs.id
    }
}
