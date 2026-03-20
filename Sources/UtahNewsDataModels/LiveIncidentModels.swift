//
//  LiveIncidentModels.swift
//  UtahNewsDataModels
//
//  "Happening Now" — real-time citizen witness reporting models.
//  Used by UtahNews (consumer), NewsCapture (editorial), UTNewsDashboard (admin).
//

import Foundation

// MARK: - Enums

/// Type of incident being reported
public nonisolated enum IncidentType: String, Codable, Hashable, Sendable, CaseIterable {
    case breaking
    case fire
    case accident
    case weather
    case police
    case community
    case protest
    case construction
    case other

    public var displayName: String {
        switch self {
        case .breaking: "Breaking"
        case .fire: "Fire"
        case .accident: "Accident"
        case .weather: "Weather"
        case .police: "Police"
        case .community: "Community"
        case .protest: "Protest"
        case .construction: "Construction"
        case .other: "Other"
        }
    }

    public var systemImage: String {
        switch self {
        case .breaking: "exclamationmark.triangle.fill"
        case .fire: "flame.fill"
        case .accident: "car.fill"
        case .weather: "cloud.bolt.fill"
        case .police: "shield.fill"
        case .community: "person.3.fill"
        case .protest: "megaphone.fill"
        case .construction: "hammer.fill"
        case .other: "questionmark.circle.fill"
        }
    }
}

/// Severity level of an incident
public nonisolated enum IncidentSeverity: String, Codable, Hashable, Sendable, CaseIterable {
    case low
    case normal
    case high
    case critical

    public var sortOrder: Int {
        switch self {
        case .critical: 0
        case .high: 1
        case .normal: 2
        case .low: 3
        }
    }
}

/// Current status of an incident
public nonisolated enum IncidentStatus: String, Codable, Hashable, Sendable, CaseIterable {
    case active
    case monitoring
    case resolved
    case merged
}

/// Editorial review status for an incident
public nonisolated enum EditorialStatus: String, Codable, Hashable, Sendable, CaseIterable {
    case unreviewed
    case reviewing
    case approved
    case rejected
    case published
}

/// Source that created the incident
public nonisolated enum IncidentSource: String, Codable, Hashable, Sendable, CaseIterable {
    case witness
    case pipeline
    case inquiry
    case editorial
}

/// Status of a witness report
public nonisolated enum WitnessReportStatus: String, Codable, Hashable, Sendable, CaseIterable {
    case pending
    case verified
    case flagged
    case rejected
}

/// Media upload progress for a witness report
public nonisolated enum MediaUploadStatus: String, Codable, Hashable, Sendable, CaseIterable {
    case pending
    case uploading
    case complete
    case failed
}

/// Type of inquiry ("what's happening?")
public nonisolated enum InquiryType: String, Codable, Hashable, Sendable, CaseIterable {
    case pinDrop = "pin_drop"
    case directionEstimate = "direction_estimate"
}

/// Status of an inquiry request
public nonisolated enum InquiryStatus: String, Codable, Hashable, Sendable, CaseIterable {
    case active
    case answered
    case expired
    case cancelled
}

// MARK: - LiveIncident

/// A real-time newsworthy event reported by witnesses or detected by the pipeline.
public nonisolated struct LiveIncident: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let description: String?
    public let incidentType: IncidentType
    public let severity: IncidentSeverity
    public let status: IncidentStatus
    public let latitude: Double
    public let longitude: Double
    public let radiusMeters: Int
    public let city: String?
    public let reportCount: Int
    public let witnessYesCount: Int
    public let witnessNoCount: Int
    public let editorialStatus: EditorialStatus
    public let linkedArticleId: String?
    public let source: IncidentSource
    public let pushSent: Bool
    public let mergedIntoId: String?
    public let expiresAt: Date?
    public let createdAt: Date?
    public let updatedAt: Date?

    public init(
        id: String = UUID().uuidString,
        title: String,
        description: String? = nil,
        incidentType: IncidentType = .other,
        severity: IncidentSeverity = .normal,
        status: IncidentStatus = .active,
        latitude: Double,
        longitude: Double,
        radiusMeters: Int = 500,
        city: String? = nil,
        reportCount: Int = 0,
        witnessYesCount: Int = 0,
        witnessNoCount: Int = 0,
        editorialStatus: EditorialStatus = .unreviewed,
        linkedArticleId: String? = nil,
        source: IncidentSource = .witness,
        pushSent: Bool = false,
        mergedIntoId: String? = nil,
        expiresAt: Date? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.incidentType = incidentType
        self.severity = severity
        self.status = status
        self.latitude = latitude
        self.longitude = longitude
        self.radiusMeters = radiusMeters
        self.city = city
        self.reportCount = reportCount
        self.witnessYesCount = witnessYesCount
        self.witnessNoCount = witnessNoCount
        self.editorialStatus = editorialStatus
        self.linkedArticleId = linkedArticleId
        self.source = source
        self.pushSent = pushSent
        self.mergedIntoId = mergedIntoId
        self.expiresAt = expiresAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, latitude, longitude, city, source, status, severity
        case incidentType = "incident_type"
        case radiusMeters = "radius_meters"
        case reportCount = "report_count"
        case witnessYesCount = "witness_yes_count"
        case witnessNoCount = "witness_no_count"
        case editorialStatus = "editorial_status"
        case linkedArticleId = "linked_article_id"
        case pushSent = "push_sent"
        case mergedIntoId = "merged_into_id"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - WitnessMediaItem

/// A single media item attached to a witness report (stored as JSONB array element).
public nonisolated struct WitnessMediaItem: Codable, Hashable, Sendable, Identifiable {
    public var id: String { url }
    public let url: String
    public let type: String
    public let thumbnailUrl: String?
    public let uploadedAt: String?

    public init(url: String, type: String = "photo", thumbnailUrl: String? = nil, uploadedAt: String? = nil) {
        self.url = url
        self.type = type
        self.thumbnailUrl = thumbnailUrl
        self.uploadedAt = uploadedAt
    }

    enum CodingKeys: String, CodingKey {
        case url, type
        case thumbnailUrl = "thumbnail_url"
        case uploadedAt = "uploaded_at"
    }
}

// MARK: - WitnessReport

/// An individual eyewitness contribution linked to an incident.
public nonisolated struct WitnessReport: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let incidentId: String
    public let userId: String?
    public let textDescription: String?
    public let latitude: Double?
    public let longitude: Double?
    public let heading: Double?
    public let estimatedDistanceMeters: Int?
    public let mediaUrls: [WitnessMediaItem]
    public let mediaUploadStatus: MediaUploadStatus
    public let status: WitnessReportStatus
    public let isConfirmed: Bool
    public let interviewTranscriptId: String?
    public let createdAt: Date?
    public let updatedAt: Date?

    public init(
        id: String = UUID().uuidString,
        incidentId: String,
        userId: String? = nil,
        textDescription: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        heading: Double? = nil,
        estimatedDistanceMeters: Int? = nil,
        mediaUrls: [WitnessMediaItem] = [],
        mediaUploadStatus: MediaUploadStatus = .pending,
        status: WitnessReportStatus = .pending,
        isConfirmed: Bool = false,
        interviewTranscriptId: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.incidentId = incidentId
        self.userId = userId
        self.textDescription = textDescription
        self.latitude = latitude
        self.longitude = longitude
        self.heading = heading
        self.estimatedDistanceMeters = estimatedDistanceMeters
        self.mediaUrls = mediaUrls
        self.mediaUploadStatus = mediaUploadStatus
        self.status = status
        self.isConfirmed = isConfirmed
        self.interviewTranscriptId = interviewTranscriptId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, latitude, longitude, heading, status
        case incidentId = "incident_id"
        case userId = "user_id"
        case textDescription = "text_description"
        case estimatedDistanceMeters = "estimated_distance_meters"
        case mediaUrls = "media_urls"
        case mediaUploadStatus = "media_upload_status"
        case isConfirmed = "is_confirmed"
        case interviewTranscriptId = "interview_transcript_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - InquiryRequest

/// A "what's happening?" question from a curious bystander.
public nonisolated struct InquiryRequest: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let userId: String?
    public let inquiryType: InquiryType
    public let latitude: Double
    public let longitude: Double
    public let heading: Double?
    public let estimatedDistanceMeters: Int?
    public let targetLatitude: Double?
    public let targetLongitude: Double?
    public let searchRadiusMeters: Int
    public let status: InquiryStatus
    public let matchedIncidentId: String?
    public let responseCount: Int
    public let expiresAt: Date?
    public let createdAt: Date?

    public init(
        id: String = UUID().uuidString,
        userId: String? = nil,
        inquiryType: InquiryType,
        latitude: Double,
        longitude: Double,
        heading: Double? = nil,
        estimatedDistanceMeters: Int? = nil,
        targetLatitude: Double? = nil,
        targetLongitude: Double? = nil,
        searchRadiusMeters: Int = 500,
        status: InquiryStatus = .active,
        matchedIncidentId: String? = nil,
        responseCount: Int = 0,
        expiresAt: Date? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.inquiryType = inquiryType
        self.latitude = latitude
        self.longitude = longitude
        self.heading = heading
        self.estimatedDistanceMeters = estimatedDistanceMeters
        self.targetLatitude = targetLatitude
        self.targetLongitude = targetLongitude
        self.searchRadiusMeters = searchRadiusMeters
        self.status = status
        self.matchedIncidentId = matchedIncidentId
        self.responseCount = responseCount
        self.expiresAt = expiresAt
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, latitude, longitude, heading, status
        case userId = "user_id"
        case inquiryType = "inquiry_type"
        case estimatedDistanceMeters = "estimated_distance_meters"
        case targetLatitude = "target_latitude"
        case targetLongitude = "target_longitude"
        case searchRadiusMeters = "search_radius_meters"
        case matchedIncidentId = "matched_incident_id"
        case responseCount = "response_count"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
    }
}
