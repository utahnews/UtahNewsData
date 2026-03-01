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

    // MARK: - Observability & Audit

    /// Pipeline execution audit trail with AI cost tracking
    case pipelineRuns = "pipeline_runs"

    // MARK: - Knowledge Graph Extensions

    /// Relationships between entities (people ↔ orgs ↔ locations)
    case entityRelationships = "entity_relationships"

    // MARK: - Citation & Legal

    /// Source domain license and fair-use metadata
    case sourceLicenses = "source_licenses"

    // MARK: - Ad System

    /// Ad campaign management with budget tracking
    case adCampaigns = "ad_campaigns"

    /// Category and city-based ad targeting rules
    case adTargeting = "ad_targeting"

    /// Creative assets with moderation workflow
    case adCreatives = "ad_creatives"

    /// Unified impression/click event tracking
    case adEvents = "ad_events"

    // MARK: - Community

    /// Discussion forum categories
    case discussionCategories = "discussion_categories"

    /// Discussion conversation threads
    case discussionThreads = "discussion_threads"

    /// Individual discussion posts
    case discussionPosts = "discussion_posts"

    /// User reactions to posts
    case discussionReactions = "discussion_reactions"

    /// Community user profiles
    case discussionUsers = "discussion_users"

    // MARK: - Editorial Extensions

    /// Geographic jurisdiction reference data
    case jurisdictions = "jurisdictions"

    /// Editorial story assignments
    case storyAssignments = "story_assignments"

    /// Story version history
    case storyVersions = "story_versions"

    /// News alert configurations
    case newsAlerts = "news_alerts"

    /// Citizen journalism submissions
    case userContributions = "user_contributions"

    /// Review tracking for submissions
    case submissionReviews = "submission_reviews"

    /// Contributor profiles
    case contributorProfiles = "contributor_profiles"

    /// Extracted claims from submissions
    case extractedClaims = "extracted_claims"

    /// Contribution trend analytics
    case contributionTrends = "contribution_trends"

    // MARK: - Device Health

    /// Device-level pipeline health metrics
    case devicePipelineHealth = "device_pipeline_health"

    /// Device generation health tracking
    case deviceGenerationHealth = "device_generation_health"
}
