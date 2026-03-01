//
//  SupabaseAdModels.swift
//  UtahNewsData
//
//  Ad system models mapping to the `pipeline` schema ad tables.
//  Tables: ad_campaigns, ad_targeting, ad_creatives, ad_events
//

import Foundation

// MARK: - Ad Campaign

/// A row from the `pipeline.ad_campaigns` table.
///
/// Tracks advertiser campaigns with budget, scheduling, and status.
nonisolated public struct SupabaseAdCampaign: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public var advertiserName: String
    public var campaignName: String
    public var status: String
    public var startDate: Date?
    public var endDate: Date?
    public var budgetCents: Int
    public var dailyBudgetCents: Int?
    public var spentCents: Int
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: String,
        advertiserName: String,
        campaignName: String,
        status: String = "draft",
        startDate: Date? = nil,
        endDate: Date? = nil,
        budgetCents: Int = 0,
        dailyBudgetCents: Int? = nil,
        spentCents: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.advertiserName = advertiserName
        self.campaignName = campaignName
        self.status = status
        self.startDate = startDate
        self.endDate = endDate
        self.budgetCents = budgetCents
        self.dailyBudgetCents = dailyBudgetCents
        self.spentCents = spentCents
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, status
        case advertiserName = "advertiser_name"
        case campaignName = "campaign_name"
        case startDate = "start_date"
        case endDate = "end_date"
        case budgetCents = "budget_cents"
        case dailyBudgetCents = "daily_budget_cents"
        case spentCents = "spent_cents"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Campaign Computed Properties

extension SupabaseAdCampaign {
    /// Budget remaining in cents
    public var remainingCents: Int {
        max(0, budgetCents - spentCents)
    }

    /// Budget formatted as dollars
    public var budgetFormatted: String {
        let dollars = Double(budgetCents) / 100.0
        if dollars == 0 { return "Unlimited" }
        return String(format: "$%.2f", dollars)
    }

    /// Spent formatted as dollars
    public var spentFormatted: String {
        String(format: "$%.2f", Double(spentCents) / 100.0)
    }

    /// Whether the campaign is currently active
    public var isActive: Bool {
        status == "active"
    }

    /// Whether the campaign has budget remaining (0 = unlimited)
    public var hasBudget: Bool {
        budgetCents == 0 || spentCents < budgetCents
    }
}

// MARK: - Campaign Status Constants

extension SupabaseAdCampaign {
    nonisolated public enum Status {
        public static let draft = "draft"
        public static let active = "active"
        public static let paused = "paused"
        public static let completed = "completed"
        public static let archived = "archived"
    }
}

// MARK: - Ad Campaign Insert

nonisolated public struct SupabaseAdCampaignInsert: Codable, Sendable {
    public let advertiserName: String
    public let campaignName: String
    public var status: String
    public var startDate: Date?
    public var endDate: Date?
    public var budgetCents: Int
    public var dailyBudgetCents: Int?

    public init(
        advertiserName: String,
        campaignName: String,
        status: String = "draft",
        startDate: Date? = nil,
        endDate: Date? = nil,
        budgetCents: Int = 0,
        dailyBudgetCents: Int? = nil
    ) {
        self.advertiserName = advertiserName
        self.campaignName = campaignName
        self.status = status
        self.startDate = startDate
        self.endDate = endDate
        self.budgetCents = budgetCents
        self.dailyBudgetCents = dailyBudgetCents
    }

    enum CodingKeys: String, CodingKey {
        case status
        case advertiserName = "advertiser_name"
        case campaignName = "campaign_name"
        case startDate = "start_date"
        case endDate = "end_date"
        case budgetCents = "budget_cents"
        case dailyBudgetCents = "daily_budget_cents"
    }
}

// MARK: - Ad Targeting

/// A row from the `pipeline.ad_targeting` table.
///
/// Category and city-based targeting rules for ad campaigns.
nonisolated public struct SupabaseAdTargeting: Codable, Sendable, Identifiable {
    public let id: String
    public let campaignId: String
    public var placement: String
    public var targetCity: String?
    public var targetCategory: String?
    public var priority: Int
    public let createdAt: Date

    public init(
        id: String,
        campaignId: String,
        placement: String,
        targetCity: String? = nil,
        targetCategory: String? = nil,
        priority: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.campaignId = campaignId
        self.placement = placement
        self.targetCity = targetCity
        self.targetCategory = targetCategory
        self.priority = priority
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, placement, priority
        case campaignId = "campaign_id"
        case targetCity = "target_city"
        case targetCategory = "target_category"
        case createdAt = "created_at"
    }
}

// MARK: - Ad Targeting Insert

nonisolated public struct SupabaseAdTargetingInsert: Codable, Sendable {
    public let campaignId: String
    public let placement: String
    public var targetCity: String?
    public var targetCategory: String?
    public var priority: Int

    public init(
        campaignId: String,
        placement: String,
        targetCity: String? = nil,
        targetCategory: String? = nil,
        priority: Int = 0
    ) {
        self.campaignId = campaignId
        self.placement = placement
        self.targetCity = targetCity
        self.targetCategory = targetCategory
        self.priority = priority
    }

    enum CodingKeys: String, CodingKey {
        case placement, priority
        case campaignId = "campaign_id"
        case targetCity = "target_city"
        case targetCategory = "target_category"
    }
}

// MARK: - Placement Constants

extension SupabaseAdTargetingInsert {
    nonisolated public enum Placement {
        public static let homeBanner = "home_banner"
        public static let articleInline = "article_inline"
        public static let videoPreroll = "video_preroll"
        public static let sidebar = "sidebar"
        public static let breakingBanner = "breaking_banner"
    }
}

// MARK: - Ad Creative

/// A row from the `pipeline.ad_creatives` table.
///
/// Creative assets (image/video) with moderation workflow.
nonisolated public struct SupabaseAdCreative: Codable, Sendable, Identifiable {
    public let id: String
    public let campaignId: String
    public var mediaType: String
    public var mediaUrl: String
    public var ctaText: String?
    public var ctaUrl: String?
    public var moderationStatus: String
    public let createdAt: Date

    public init(
        id: String,
        campaignId: String,
        mediaType: String,
        mediaUrl: String,
        ctaText: String? = nil,
        ctaUrl: String? = nil,
        moderationStatus: String = "pending",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.campaignId = campaignId
        self.mediaType = mediaType
        self.mediaUrl = mediaUrl
        self.ctaText = ctaText
        self.ctaUrl = ctaUrl
        self.moderationStatus = moderationStatus
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case campaignId = "campaign_id"
        case mediaType = "media_type"
        case mediaUrl = "media_url"
        case ctaText = "cta_text"
        case ctaUrl = "cta_url"
        case moderationStatus = "moderation_status"
        case createdAt = "created_at"
    }
}

// MARK: - Moderation Status Constants

extension SupabaseAdCreative {
    nonisolated public enum ModerationStatus {
        public static let pending = "pending"
        public static let approved = "approved"
        public static let rejected = "rejected"
    }

    nonisolated public enum MediaType {
        public static let image = "image"
        public static let video = "video"
    }
}

// MARK: - Ad Creative Insert

nonisolated public struct SupabaseAdCreativeInsert: Codable, Sendable {
    public let campaignId: String
    public let mediaType: String
    public let mediaUrl: String
    public var ctaText: String?
    public var ctaUrl: String?

    public init(
        campaignId: String,
        mediaType: String,
        mediaUrl: String,
        ctaText: String? = nil,
        ctaUrl: String? = nil
    ) {
        self.campaignId = campaignId
        self.mediaType = mediaType
        self.mediaUrl = mediaUrl
        self.ctaText = ctaText
        self.ctaUrl = ctaUrl
    }

    enum CodingKeys: String, CodingKey {
        case campaignId = "campaign_id"
        case mediaType = "media_type"
        case mediaUrl = "media_url"
        case ctaText = "cta_text"
        case ctaUrl = "cta_url"
    }
}

// MARK: - Ad Event

/// A row from the `pipeline.ad_events` table.
///
/// Unified impression/click event tracking for all ad interactions.
nonisolated public struct SupabaseAdEvent: Codable, Sendable, Identifiable {
    public let id: String
    public let campaignId: String
    public let creativeId: String?
    public let eventType: String
    public let placement: String?
    public let cityName: String?
    public let deviceType: String?
    public let recordedAt: Date

    public init(
        id: String,
        campaignId: String,
        creativeId: String? = nil,
        eventType: String,
        placement: String? = nil,
        cityName: String? = nil,
        deviceType: String? = nil,
        recordedAt: Date = Date()
    ) {
        self.id = id
        self.campaignId = campaignId
        self.creativeId = creativeId
        self.eventType = eventType
        self.placement = placement
        self.cityName = cityName
        self.deviceType = deviceType
        self.recordedAt = recordedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, placement
        case campaignId = "campaign_id"
        case creativeId = "creative_id"
        case eventType = "event_type"
        case cityName = "city_name"
        case deviceType = "device_type"
        case recordedAt = "recorded_at"
    }
}

// MARK: - Event Type Constants

extension SupabaseAdEvent {
    nonisolated public enum EventType {
        public static let impression = "impression"
        public static let click = "click"
        public static let viewComplete = "view_complete"
    }
}

// MARK: - Ad Event Insert

nonisolated public struct SupabaseAdEventInsert: Codable, Sendable {
    public let campaignId: String
    public var creativeId: String?
    public let eventType: String
    public var placement: String?
    public var cityName: String?
    public var deviceType: String?

    public init(
        campaignId: String,
        creativeId: String? = nil,
        eventType: String,
        placement: String? = nil,
        cityName: String? = nil,
        deviceType: String? = nil
    ) {
        self.campaignId = campaignId
        self.creativeId = creativeId
        self.eventType = eventType
        self.placement = placement
        self.cityName = cityName
        self.deviceType = deviceType
    }

    enum CodingKeys: String, CodingKey {
        case placement
        case campaignId = "campaign_id"
        case creativeId = "creative_id"
        case eventType = "event_type"
        case cityName = "city_name"
        case deviceType = "device_type"
    }
}
