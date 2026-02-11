//
//  SupabaseTables.swift
//  UtahNewsData
//
//  Canonical list of all Supabase table names in the `pipeline` schema.
//  Use these constants instead of hardcoded strings to prevent typos.
//
//  All 24 tables identified in the Pipeline Audit Report (2026-02-10).
//

import Foundation

// MARK: - Table Names

/// All Supabase table names in the `pipeline` schema.
///
/// Usage:
/// ```swift
/// let items = try await client
///     .from(SupabaseTable.urlQueue.rawValue)
///     .schema(SupabaseConfig.schema)
///     .select()
///     .execute()
/// ```
public enum SupabaseTable: String, CaseIterable, Sendable {

    // MARK: - Core Pipeline Tables

    /// Primary processing queue for V2 pipeline URL intake
    case urlQueue = "url_queue"

    /// V2 pipeline output: fully processed content with metadata
    case processedItems = "processed_items"

    /// Published articles created through editorial workflow
    case articles = "articles"

    /// Human review queue bridging pipeline output to editorial
    case editorialQueue = "editorial_queue"

    // MARK: - Source Registry

    /// Per-city news source registry (flattened from Firestore subcollections)
    case citySources = "city_sources"

    /// Feed URLs (RSS, Atom, sitemap) associated with sources
    case sourceFeeds = "source_feeds"

    /// Legacy flat source registry
    case sources = "sources"

    /// Non-Utah sources filtered from processing
    case nonUtahSources = "non_utah_sources"

    // MARK: - Entity Knowledge Graph

    /// Canonical person records for entity matching
    case people = "people"

    /// Canonical organization records for entity matching
    case organizations = "organizations"

    /// Entity mention tracking across articles
    case entityMentions = "entity_mentions"

    /// Alternative name mappings for entity resolution
    case entityAliases = "entity_aliases"

    /// Entities pending manual review or auto-creation
    case unmatchedEntities = "unmatched_entities"

    // MARK: - Trend Detection

    /// Detected trending topics and patterns
    case trends = "trends"

    /// Currently trending topics (live snapshot)
    case trendingNow = "trending_now"

    // MARK: - Supplementary Pipeline

    /// URLs deferred for later retry (blocked domains, rate limits)
    case deferredUrls = "deferred_urls"

    /// URLs requiring specialized extraction (calendars, video, audio)
    case specialProcessingUrls = "special_processing_urls"

    /// Extracted structured data (JSON-LD, OpenGraph, etc.)
    case structuredData = "structured_data"

    /// User-submitted URLs with tracking
    case userSubmissions = "user_submissions"

    /// Content stream for new/changed items with 7-day TTL
    case freshContent = "fresh_content"

    // MARK: - Scan Coordination

    /// Source scan value scoring for prioritization
    case scanValues = "scan_values"

    /// Historical scan value scores
    case scanValueHistory = "scan_value_history"

    /// Scan execution audit trail
    case scanHistory = "scan_history"

    /// Multi-device scan coordination locks
    case scanCoordinator = "scan_coordinator"

    // MARK: - Settings

    /// AI pipeline configuration settings
    case intelligenceSettings = "intelligence_settings"

    // MARK: - Media (read-only from Supabase perspective)

    /// Video content metadata (primary storage may be CloudKit)
    case videos = "videos"

    /// Audio/podcast content metadata
    case audios = "audios"
}
