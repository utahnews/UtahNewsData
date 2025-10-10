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

/// Video source type - determines storage and playback strategy
public enum VideoSourceType: String, Codable, Sendable {
    case produced = "produced"              // UtahNews-produced HLS content
    case userSubmitted = "userSubmitted"    // User-uploaded videos
    case external = "external"              // External URLs (YouTube, etc.)
}

/// Storage backend for video files
public enum StorageBackend: String, Codable, Sendable {
    case cloudkit = "cloudkit"              // CloudKit Asset storage
    case firebase = "firebase"              // Firebase Storage
    case external = "external"              // External hosting (YouTube, etc.)
}

/// Video status for moderation workflow
public enum VideoStatus: String, Codable, Sendable {
    case draft = "draft"
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case archived = "archived"
}

/// Represents a video asset stored in CloudKit Public Database
public struct VideoAsset: Identifiable, Codable, Sendable, Hashable {
    // MARK: - Core Properties
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

    // MARK: - Type & Storage
    public var videoSourceType: VideoSourceType
    public var storageBackend: StorageBackend
    public var status: VideoStatus

    // MARK: - Alternative Storage URLs
    public var firebaseStoragePath: String?    // Firebase Storage path
    public var externalVideoUrl: String?       // External video URL (YouTube, etc.)

    // MARK: - Categorization & Discovery
    public var category: String?               // "news", "sports", "weather", etc.
    public var tags: [String]?                 // Searchable keywords
    public var location: String?               // Utah city/region
    public var featured: Bool                  // Featured on homepage
    public var priority: Int                   // Display priority (higher = more prominent)

    // MARK: - Source & Integration
    public var sourceUrl: String?              // Original source URL
    public var firestoreId: String?            // Link to Firestore document
    public var agentPipelineId: String?        // Pipeline agent ID
    public var sourceOrganization: String?     // Organization name
    public var discoverySource: String?        // "agent_pipeline", "user_upload", "cms_manual"
    public var uploadedBy: String?             // User ID or "system"

    // MARK: - Moderation
    public var moderationNotes: String?
    public var moderatedBy: String?
    public var moderatedAt: Date?

    // MARK: - Multi-Format & Accessibility
    public var hlsVariants: String?            // JSON array of quality variants
    public var captionsUrl: String?            // WebVTT/SRT subtitle file
    public var transcriptUrl: String?          // Full transcript

    // MARK: - Rights & Legal
    public var copyrightInfo: String?
    public var expiresAt: Date?                // Content expiration date

    // MARK: - Extensibility
    public var metadata: String?               // JSON blob for flexible future data
    public var schemaVersion: String?          // Track data model version

    /// Initialize from CloudKit record
    #if canImport(CloudKit)
    public init(record: CKRecord) {
        // Core properties
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

        // Type & Storage
        if let sourceTypeStr = record["videoSourceType"] as? String,
           let sourceType = VideoSourceType(rawValue: sourceTypeStr) {
            videoSourceType = sourceType
        } else {
            videoSourceType = .produced  // Default to produced
        }

        if let backendStr = record["storageBackend"] as? String,
           let backend = StorageBackend(rawValue: backendStr) {
            storageBackend = backend
        } else {
            storageBackend = .cloudkit  // Default to CloudKit
        }

        if let statusStr = record["status"] as? String,
           let videoStatus = VideoStatus(rawValue: statusStr) {
            status = videoStatus
        } else {
            status = .approved  // Default to approved for compatibility
        }

        // Alternative Storage URLs
        firebaseStoragePath = record["firebaseStoragePath"] as? String
        externalVideoUrl = record["externalVideoUrl"] as? String

        // Categorization & Discovery
        category = record["category"] as? String
        tags = record["tags"] as? [String]
        location = record["location"] as? String
        featured = (record["featured"] as? Int64 ?? 0) == 1
        priority = Int(record["priority"] as? Int64 ?? 0)

        // Source & Integration
        sourceUrl = record["sourceUrl"] as? String
        firestoreId = record["firestoreId"] as? String
        agentPipelineId = record["agentPipelineId"] as? String
        sourceOrganization = record["sourceOrganization"] as? String
        discoverySource = record["discoverySource"] as? String
        uploadedBy = record["uploadedBy"] as? String

        // Moderation
        moderationNotes = record["moderationNotes"] as? String
        moderatedBy = record["moderatedBy"] as? String
        moderatedAt = record["moderatedAt"] as? Date

        // Multi-Format & Accessibility
        hlsVariants = record["hlsVariants"] as? String
        captionsUrl = record["captionsUrl"] as? String
        transcriptUrl = record["transcriptUrl"] as? String

        // Rights & Legal
        copyrightInfo = record["copyrightInfo"] as? String
        expiresAt = record["expiresAt"] as? Date

        // Extensibility
        metadata = record["metadata"] as? String
        schemaVersion = record["schemaVersion"] as? String
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
        textContent: String = "",
        videoSourceType: VideoSourceType = .produced,
        storageBackend: StorageBackend = .cloudkit,
        status: VideoStatus = .approved,
        firebaseStoragePath: String? = nil,
        externalVideoUrl: String? = nil,
        category: String? = nil,
        tags: [String]? = nil,
        location: String? = nil,
        featured: Bool = false,
        priority: Int = 0,
        sourceUrl: String? = nil,
        firestoreId: String? = nil,
        agentPipelineId: String? = nil,
        sourceOrganization: String? = nil,
        discoverySource: String? = nil,
        uploadedBy: String? = nil,
        moderationNotes: String? = nil,
        moderatedBy: String? = nil,
        moderatedAt: Date? = nil,
        hlsVariants: String? = nil,
        captionsUrl: String? = nil,
        transcriptUrl: String? = nil,
        copyrightInfo: String? = nil,
        expiresAt: Date? = nil,
        metadata: String? = nil,
        schemaVersion: String? = nil
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
        self.videoSourceType = videoSourceType
        self.storageBackend = storageBackend
        self.status = status
        self.firebaseStoragePath = firebaseStoragePath
        self.externalVideoUrl = externalVideoUrl
        self.category = category
        self.tags = tags
        self.location = location
        self.featured = featured
        self.priority = priority
        self.sourceUrl = sourceUrl
        self.firestoreId = firestoreId
        self.agentPipelineId = agentPipelineId
        self.sourceOrganization = sourceOrganization
        self.discoverySource = discoverySource
        self.uploadedBy = uploadedBy
        self.moderationNotes = moderationNotes
        self.moderatedBy = moderatedBy
        self.moderatedAt = moderatedAt
        self.hlsVariants = hlsVariants
        self.captionsUrl = captionsUrl
        self.transcriptUrl = transcriptUrl
        self.copyrightInfo = copyrightInfo
        self.expiresAt = expiresAt
        self.metadata = metadata
        self.schemaVersion = schemaVersion
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: VideoAsset, rhs: VideoAsset) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Playback URL Resolution

    /// Returns the appropriate playback URL based on video source type and storage backend
    public var playbackURL: URL {
        switch videoSourceType {
        case .produced:
            // UtahNews-produced: use CloudKit manifest URL
            return manifestURL

        case .userSubmitted:
            if storageBackend == .firebase, let firebasePath = firebaseStoragePath {
                // User-submitted from Firebase: construct Firebase Storage URL
                // Note: This would need Firebase SDK to resolve properly
                // For now, return manifest URL as fallback
                return manifestURL
            } else {
                // User-submitted from CloudKit
                return manifestURL
            }

        case .external:
            // External video: use external URL if available
            if let externalUrl = externalVideoUrl, let url = URL(string: externalUrl) {
                return url
            } else {
                // Fallback to manifest URL
                return manifestURL
            }
        }
    }

    /// Indicates if this video should be played via native AVPlayer
    public var isNativePlayback: Bool {
        switch videoSourceType {
        case .produced, .userSubmitted:
            return true  // HLS or direct video file
        case .external:
            return false  // Might be YouTube embed, etc.
        }
    }

    /// Indicates if video is ready for playback
    public var isPlayable: Bool {
        return status == .approved && playbackURL.absoluteString != "about:blank"
    }
}
