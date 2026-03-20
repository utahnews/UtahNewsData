//
//  SupabaseEvent.swift
//  UtahNewsData
//
//  Structured calendar/meeting event from Supabase `events` table.
//  Populated by V2PipelineTester's FeedIngestionService from parsed iCal feeds.
//  Consumed by UtahNews's LocalEventsView for community event display.
//

import Foundation

/// Event record from the Supabase `pipeline.events` table.
/// Represents a parsed iCal event from institutional feeds.
public nonisolated struct SupabaseEvent: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let uid: String?
    public let title: String
    public let description: String?
    public let startDate: Date
    public let endDate: Date?
    public let allDay: Bool
    public let location: String?
    public let organizer: String?
    public let eventType: String?
    public let category: String?
    public let recurrenceRule: String?
    public let eventUrl: String?
    public let sourceFeedUrl: String?
    public let institutionId: String?
    public let cityName: String
    public let isCancelled: Bool
    public let extractedAt: Date?
    public let createdAt: Date?
    public let updatedAt: Date?

    public enum CodingKeys: String, CodingKey {
        case id, uid, title, description, location, organizer, category
        case startDate = "start_date"
        case endDate = "end_date"
        case allDay = "all_day"
        case eventType = "event_type"
        case recurrenceRule = "recurrence_rule"
        case eventUrl = "event_url"
        case sourceFeedUrl = "source_feed_url"
        case institutionId = "institution_id"
        case cityName = "city_name"
        case isCancelled = "is_cancelled"
        case extractedAt = "extracted_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: SupabaseEvent, rhs: SupabaseEvent) -> Bool {
        lhs.id == rhs.id
    }
}

/// Insert model for upserting events (excludes auto-generated fields)
public nonisolated struct SupabaseEventInsert: Codable, Sendable {
    public let uid: String?
    public let title: String
    public let description: String?
    public let startDate: String
    public let endDate: String?
    public let allDay: Bool
    public let location: String?
    public let organizer: String?
    public let eventType: String?
    public let category: String?
    public let recurrenceRule: String?
    public let eventUrl: String?
    public let sourceFeedUrl: String?
    public let institutionId: String?
    public let cityName: String
    public let isCancelled: Bool

    public enum CodingKeys: String, CodingKey {
        case uid, title, description, location, organizer, category
        case startDate = "start_date"
        case endDate = "end_date"
        case allDay = "all_day"
        case eventType = "event_type"
        case recurrenceRule = "recurrence_rule"
        case eventUrl = "event_url"
        case sourceFeedUrl = "source_feed_url"
        case institutionId = "institution_id"
        case cityName = "city_name"
        case isCancelled = "is_cancelled"
    }

    public init(
        uid: String?,
        title: String,
        description: String?,
        startDate: String,
        endDate: String?,
        allDay: Bool = false,
        location: String?,
        organizer: String?,
        eventType: String?,
        category: String?,
        recurrenceRule: String?,
        eventUrl: String?,
        sourceFeedUrl: String?,
        institutionId: String?,
        cityName: String,
        isCancelled: Bool = false
    ) {
        self.uid = uid
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.allDay = allDay
        self.location = location
        self.organizer = organizer
        self.eventType = eventType
        self.category = category
        self.recurrenceRule = recurrenceRule
        self.eventUrl = eventUrl
        self.sourceFeedUrl = sourceFeedUrl
        self.institutionId = institutionId
        self.cityName = cityName
        self.isCancelled = isCancelled
    }
}
