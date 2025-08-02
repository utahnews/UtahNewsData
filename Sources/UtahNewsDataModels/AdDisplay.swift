//
//  AdDisplay.swift
//  UtahNewsData
//
//  Created by Claude on 1/28/25.
//
//  Minimal advertisement display model for cross-app sharing.
//  This lightweight model is used by consumer apps to display ads
//  without needing to know about business logic or targeting details.
//

import Foundation

/// A minimal advertisement model for display in consumer applications
public struct AdDisplay: Codable, Identifiable, Hashable, Sendable {
    /// Unique identifier for the advertisement
    public let id: String
    
    /// Display title for the advertisement
    public let title: String
    
    /// URL for the advertisement image
    public let imageURL: String
    
    /// URL to open when the ad is tapped
    public let destinationURL: String
    
    /// Optional text content for the ad
    public let text: String?
    
    /// The type of advertisement display
    public let type: AdDisplayType
    
    /// Date when this ad should stop being displayed
    public let validUntil: Date
    
    /// Priority for ad display (higher = more important)
    public let priority: Int
    
    /// Optional video URL for video ads
    public let videoURL: String?
    
    /// Analytics tracking ID
    public let trackingID: String?
    
    public init(
        id: String,
        title: String,
        imageURL: String,
        destinationURL: String,
        text: String? = nil,
        type: AdDisplayType,
        validUntil: Date,
        priority: Int = 0,
        videoURL: String? = nil,
        trackingID: String? = nil
    ) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
        self.destinationURL = destinationURL
        self.text = text
        self.type = type
        self.validUntil = validUntil
        self.priority = priority
        self.videoURL = videoURL
        self.trackingID = trackingID
    }
}

/// Types of advertisement displays supported
public enum AdDisplayType: String, Codable, CaseIterable, Sendable {
    /// Small banner advertisement
    case banner = "banner"
    
    /// Inline advertisement within content
    case inline = "inline"
    
    /// Full screen interstitial advertisement
    case fullscreen = "fullscreen"
    
    /// Video advertisement
    case video = "video"
    
    /// Native content advertisement
    case native = "native"
}

// MARK: - Extensions

extension AdDisplay {
    /// Check if the ad is still valid for display
    public var isValid: Bool {
        validUntil > Date()
    }
}

// MARK: - Mock Data

#if DEBUG
extension AdDisplay {
    /// Sample ad display for previews and testing
    public static let sample = AdDisplay(
        id: "sample-ad-001",
        title: "Visit Utah's Best Restaurant",
        imageURL: "https://picsum.photos/800/400",
        destinationURL: "https://example.com/restaurant",
        text: "Experience fine dining with a view of the mountains",
        type: .banner,
        validUntil: Date().addingTimeInterval(86400 * 30), // 30 days
        priority: 5
    )
    
    /// Sample video ad for testing
    public static let sampleVideo = AdDisplay(
        id: "sample-ad-002",
        title: "Utah Adventure Tours",
        imageURL: "https://picsum.photos/800/600",
        destinationURL: "https://example.com/tours",
        text: "Book your next adventure today",
        type: .video,
        validUntil: Date().addingTimeInterval(86400 * 14), // 14 days
        priority: 8,
        videoURL: "https://example.com/video.mp4"
    )
    
    /// Array of sample ads for testing
    public static let samples = [
        sample,
        sampleVideo,
        AdDisplay(
            id: "sample-ad-003",
            title: "Shop Local Utah",
            imageURL: "https://picsum.photos/400/400",
            destinationURL: "https://example.com/shop",
            type: .inline,
            validUntil: Date().addingTimeInterval(86400 * 7),
            priority: 3
        )
    ]
}
#endif