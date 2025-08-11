//
//  V2PipelineModels.swift
//  UtahNewsData
//
//  Created for V2 Agent Pipeline Communication
//  Mirrors Python models from app/models/pipeline_models.py
//

import Foundation

// MARK: - Base Protocol for V2 Model Compliance

/// Base protocol ensuring strict schema compliance for OpenAI Agents SDK compatibility
/// Equivalent to Python StrictBaseModel with extra="forbid"
public protocol V2StrictModel: Codable, Sendable {
    /// JSON schema string for this model type
    static var jsonSchema: String { get }
}

// MARK: - Content Type Definitions

/// Content type classification for pipeline processing
/// Maps to Python ContentType Literal
public enum V2ContentType: String, Codable, CaseIterable, Sendable {
    case article = "Article"
    case feed = "Feed"
    case sitemap = "Sitemap"
    case directory = "Directory"
    case list = "List"
    case personProfile = "PersonProfile"
    case organizationProfile = "OrganizationProfile"
    case general = "General"
}

// MARK: - Agent 0 Models (Source Discovery)

/// Input for Agent 0: Source Discovery
public struct Agent0Input: V2StrictModel {
    public let cityName: String
    public let targetCategories: [String]?
    public let existingSources: [[String: String]] // Simplified from Dict[str, Any]
    public let searchQueries: [String]?
    
    public init(
        cityName: String,
        targetCategories: [String]? = nil,
        existingSources: [[String: String]] = [],
        searchQueries: [String]? = nil
    ) {
        self.cityName = cityName
        self.targetCategories = targetCategories
        self.existingSources = existingSources
        self.searchQueries = searchQueries
    }
    
    private enum CodingKeys: String, CodingKey {
        case cityName = "city_name"
        case targetCategories = "target_categories"
        case existingSources = "existing_sources"
        case searchQueries = "search_queries"
    }
    
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "city_name": {"type": "string"},
                "target_categories": {"type": ["array", "null"], "items": {"type": "string"}},
                "existing_sources": {"type": "array", "items": {"type": "object"}},
                "search_queries": {"type": ["array", "null"], "items": {"type": "string"}}
            },
            "required": ["city_name", "existing_sources"],
            "additionalProperties": false
        }
        """
    }
}

// MARK: - Agent 1 Models (Source Validation)

/// Input for Agent 1: Source Validation
public struct Agent1StructuredInput: V2StrictModel {
    public let url: String
    public let title: String?
    public let snippet: String?
    
    public init(url: String, title: String? = nil, snippet: String? = nil) {
        self.url = url
        self.title = title
        self.snippet = snippet
    }
    
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "url": {"type": "string"},
                "title": {"type": ["string", "null"]},
                "snippet": {"type": ["string", "null"]}
            },
            "required": ["url"],
            "additionalProperties": false
        }
        """
    }
}

/// Decision result from source validation
public enum V2ValidationDecision: String, Codable, Sendable {
    case suitable = "SUITABLE"
    case unsuitable = "UNSUITABLE"
}

/// Discovered feed information
public struct V2DiscoveredFeed: Codable, Sendable {
    public let url: String
    public let type: String
    public let title: String?
    
    public init(url: String, type: String, title: String? = nil) {
        self.url = url
        self.type = type
        self.title = title
    }
}

/// Output from Agent 1: Source Validation
public struct Agent1Output: V2StrictModel {
    public let decision: V2ValidationDecision
    public let reason: String
    public let validatedUrl: String?
    public let discoveredFeeds: [V2DiscoveredFeed]
    public let identifiedContentType: V2ContentType?
    public let newsCategory: String?
    
    public init(
        decision: V2ValidationDecision,
        reason: String,
        validatedUrl: String? = nil,
        discoveredFeeds: [V2DiscoveredFeed] = [],
        identifiedContentType: V2ContentType? = nil,
        newsCategory: String? = nil
    ) {
        self.decision = decision
        self.reason = reason
        self.validatedUrl = validatedUrl
        self.discoveredFeeds = discoveredFeeds
        self.identifiedContentType = identifiedContentType
        self.newsCategory = newsCategory
    }
    
    private enum CodingKeys: String, CodingKey {
        case decision
        case reason
        case validatedUrl = "validated_url"
        case discoveredFeeds = "discovered_feeds"
        case identifiedContentType = "identified_content_type"
        case newsCategory = "news_category"
    }
    
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "decision": {"type": "string", "enum": ["SUITABLE", "UNSUITABLE"]},
                "reason": {"type": "string"},
                "validated_url": {"type": ["string", "null"]},
                "discovered_feeds": {"type": "array", "items": {"$ref": "#/definitions/DiscoveredFeed"}},
                "identified_content_type": {"type": ["string", "null"]},
                "news_category": {"type": ["string", "null"]}
            },
            "required": ["decision", "reason", "discovered_feeds"],
            "additionalProperties": false
        }
        """
    }
}

// MARK: - Agent 2 Models (Data Ingestion)

/// Fetched content result from data ingestion
public struct V2FetchedContentResult: Codable, Sendable {
    public let status: String
    public let sourceUrl: String
    public let contentId: String?
    public let contentType: String?
    public let discoveredUrls: [String]?
    public let errorMessage: String?
    
    public init(
        status: String,
        sourceUrl: String,
        contentId: String? = nil,
        contentType: String? = nil,
        discoveredUrls: [String]? = nil,
        errorMessage: String? = nil
    ) {
        self.status = status
        self.sourceUrl = sourceUrl
        self.contentId = contentId
        self.contentType = contentType
        self.discoveredUrls = discoveredUrls
        self.errorMessage = errorMessage
    }
    
    private enum CodingKeys: String, CodingKey {
        case status
        case sourceUrl = "source_url"
        case contentId = "content_id"
        case contentType = "content_type"
        case discoveredUrls = "discovered_urls"
        case errorMessage = "error_message"
    }
}

/// Output from Agent 2: Data Ingestion
public struct Agent2Output: V2StrictModel {
    public let fetchResult: V2FetchedContentResult
    public let identifiedContentType: V2ContentType?
    public let discoveredUrls: [String]?
    
    public init(
        fetchResult: V2FetchedContentResult,
        identifiedContentType: V2ContentType? = nil,
        discoveredUrls: [String]? = nil
    ) {
        self.fetchResult = fetchResult
        self.identifiedContentType = identifiedContentType
        self.discoveredUrls = discoveredUrls
    }
    
    private enum CodingKeys: String, CodingKey {
        case fetchResult = "fetch_result"
        case identifiedContentType = "identified_content_type"
        case discoveredUrls = "discovered_urls"
    }
    
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "fetch_result": {"$ref": "#/definitions/FetchedContentResult"},
                "identified_content_type": {"type": ["string", "null"]},
                "discovered_urls": {"type": ["array", "null"], "items": {"type": "string"}}
            },
            "required": ["fetch_result"],
            "additionalProperties": false
        }
        """
    }
}

// MARK: - Agent 3 Models (Moderation & Cleaning)

/// Output from Agent 3: Moderation & Cleaning
public struct Agent3Output: V2StrictModel {
    public let moderationPassed: Bool
    public let flaggedCategories: [String]
    public let needsHumanReview: Bool
    public let statusMessage: String
    public let cleanedText: String?
    public let errorMessage: String?
    
    public init(
        moderationPassed: Bool,
        flaggedCategories: [String] = [],
        needsHumanReview: Bool,
        statusMessage: String,
        cleanedText: String? = nil,
        errorMessage: String? = nil
    ) {
        self.moderationPassed = moderationPassed
        self.flaggedCategories = flaggedCategories
        self.needsHumanReview = needsHumanReview
        self.statusMessage = statusMessage
        self.cleanedText = cleanedText
        self.errorMessage = errorMessage
    }
    
    private enum CodingKeys: String, CodingKey {
        case moderationPassed = "moderation_passed"
        case flaggedCategories = "flagged_categories"
        case needsHumanReview = "needs_human_review"
        case statusMessage = "status_message"
        case cleanedText = "cleaned_text"
        case errorMessage = "error_message"
    }
    
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "moderation_passed": {"type": "boolean"},
                "flagged_categories": {"type": "array", "items": {"type": "string"}},
                "needs_human_review": {"type": "boolean"},
                "status_message": {"type": "string"},
                "cleaned_text": {"type": ["string", "null"]},
                "error_message": {"type": ["string", "null"]}
            },
            "required": ["moderation_passed", "flagged_categories", "needs_human_review", "status_message"],
            "additionalProperties": false
        }
        """
    }
}

// MARK: - Agent 5 Models (Entity Extraction)

/// Output from Agent 5: Entity Extraction
public struct Agent5Output: V2StrictModel {
    public let entitiesJson: String?
    public let topics: [String]?
    public let cleanedText: String?
    public let extractionStatus: String
    public let errorMessage: String?
    
    public init(
        entitiesJson: String? = nil,
        topics: [String]? = nil,
        cleanedText: String? = nil,
        extractionStatus: String,
        errorMessage: String? = nil
    ) {
        self.entitiesJson = entitiesJson
        self.topics = topics
        self.cleanedText = cleanedText
        self.extractionStatus = extractionStatus
        self.errorMessage = errorMessage
    }
    
    private enum CodingKeys: String, CodingKey {
        case entitiesJson = "entities_json"
        case topics
        case cleanedText = "cleaned_text"
        case extractionStatus = "extraction_status"
        case errorMessage = "error_message"
    }
    
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "entities_json": {"type": ["string", "null"]},
                "topics": {"type": ["array", "null"], "items": {"type": "string"}},
                "cleaned_text": {"type": ["string", "null"]},
                "extraction_status": {"type": "string"},
                "error_message": {"type": ["string", "null"]}
            },
            "required": ["extraction_status"],
            "additionalProperties": false
        }
        """
    }
}

// MARK: - Agent 6 Models (Geocoding)

/// Geocoding result structure
public struct V2GeocodeResult: Codable, Sendable {
    public let query: String?
    public let status: String?
    public let latitude: Double?
    public let longitude: Double?
    public let address: String?
    public let confidence: Double?
    
    public init(
        query: String? = nil,
        status: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        address: String? = nil,
        confidence: Double? = nil
    ) {
        self.query = query
        self.status = status
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.confidence = confidence
    }
}

/// Output from Agent 6: Geocoding Analysis
public struct Agent6Output: V2StrictModel {
    public let identifiedLocations: [String]?
    public let geocodedLocations: [V2GeocodeResult]?
    public let cleanedText: String?
    public let entitiesJson: String?
    public let topics: [String]?
    
    public init(
        identifiedLocations: [String]? = nil,
        geocodedLocations: [V2GeocodeResult]? = nil,
        cleanedText: String? = nil,
        entitiesJson: String? = nil,
        topics: [String]? = nil
    ) {
        self.identifiedLocations = identifiedLocations
        self.geocodedLocations = geocodedLocations
        self.cleanedText = cleanedText
        self.entitiesJson = entitiesJson
        self.topics = topics
    }
    
    private enum CodingKeys: String, CodingKey {
        case identifiedLocations = "identified_locations"
        case geocodedLocations = "geocoded_locations"
        case cleanedText = "cleaned_text"
        case entitiesJson = "entities_json"
        case topics
    }
    
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "identified_locations": {"type": ["array", "null"], "items": {"type": "string"}},
                "geocoded_locations": {"type": ["array", "null"], "items": {"$ref": "#/definitions/GeocodeResult"}},
                "cleaned_text": {"type": ["string", "null"]},
                "entities_json": {"type": ["string", "null"]},
                "topics": {"type": ["array", "null"], "items": {"type": "string"}}
            },
            "additionalProperties": false
        }
        """
    }
}

// MARK: - Agent 7 Models (Sentiment & Relevance)

/// Sentiment analysis result
public struct V2SentimentAnalysisOutput: Codable, Sendable {
    public let sentimentLabel: String
    public let sentimentScore: Double
    public let confidence: Double?
    
    public init(sentimentLabel: String, sentimentScore: Double, confidence: Double? = nil) {
        self.sentimentLabel = sentimentLabel
        self.sentimentScore = sentimentScore
        self.confidence = confidence
    }
    
    private enum CodingKeys: String, CodingKey {
        case sentimentLabel = "sentiment_label"
        case sentimentScore = "sentiment_score"
        case confidence
    }
}

/// Relevance assessment result
public struct V2RelevanceOutput: Codable, Sendable {
    public let isRelevant: Bool
    public let relevanceScore: Double
    public let reason: String?
    
    public init(isRelevant: Bool, relevanceScore: Double, reason: String? = nil) {
        self.isRelevant = isRelevant
        self.relevanceScore = relevanceScore
        self.reason = reason
    }
    
    private enum CodingKeys: String, CodingKey {
        case isRelevant = "is_relevant"
        case relevanceScore = "relevance_score"
        case reason
    }
}

/// Output from Agent 7: Sentiment & Relevance Analysis
public struct Agent7Output: V2StrictModel {
    public let sentimentResult: V2SentimentAnalysisOutput?
    public let relevanceResult: V2RelevanceOutput?
    public let cleanedText: String?
    public let entitiesJson: String?
    public let topics: [String]?
    public let identifiedLocations: [String]?
    public let geocodedLocations: [V2GeocodeResult]?
    
    public init(
        sentimentResult: V2SentimentAnalysisOutput? = nil,
        relevanceResult: V2RelevanceOutput? = nil,
        cleanedText: String? = nil,
        entitiesJson: String? = nil,
        topics: [String]? = nil,
        identifiedLocations: [String]? = nil,
        geocodedLocations: [V2GeocodeResult]? = nil
    ) {
        self.sentimentResult = sentimentResult
        self.relevanceResult = relevanceResult
        self.cleanedText = cleanedText
        self.entitiesJson = entitiesJson
        self.topics = topics
        self.identifiedLocations = identifiedLocations
        self.geocodedLocations = geocodedLocations
    }
    
    private enum CodingKeys: String, CodingKey {
        case sentimentResult = "sentiment_result"
        case relevanceResult = "relevance_result"
        case cleanedText = "cleaned_text"
        case entitiesJson = "entities_json"
        case topics
        case identifiedLocations = "identified_locations"
        case geocodedLocations = "geocoded_locations"
    }
    
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "sentiment_result": {"$ref": "#/definitions/SentimentAnalysisOutput"},
                "relevance_result": {"$ref": "#/definitions/RelevanceOutput"},
                "cleaned_text": {"type": ["string", "null"]},
                "entities_json": {"type": ["string", "null"]},
                "topics": {"type": ["array", "null"], "items": {"type": "string"}},
                "identified_locations": {"type": ["array", "null"], "items": {"type": "string"}},
                "geocoded_locations": {"type": ["array", "null"], "items": {"$ref": "#/definitions/GeocodeResult"}}
            },
            "additionalProperties": false
        }
        """
    }
}

// MARK: - Agent 8 Models (Relationship Mapping)

/// Identified relationship structure
public struct V2IdentifiedRelationship: Codable, Sendable {
    public let subject: String?
    public let predicate: String?
    public let object: String?
    public let confidence: Double?
    public let context: String?
    
    public init(
        subject: String? = nil,
        predicate: String? = nil,
        object: String? = nil,
        confidence: Double? = nil,
        context: String? = nil
    ) {
        self.subject = subject
        self.predicate = predicate
        self.object = object
        self.confidence = confidence
        self.context = context
    }
}

/// Output from Agent 8: Relationship Mapping
public struct Agent8Output: V2StrictModel {
    public let mappedRelationships: [V2IdentifiedRelationship]?
    public let sentimentResult: V2SentimentAnalysisOutput?
    public let relevanceResult: V2RelevanceOutput?
    public let cleanedText: String?
    public let entitiesJson: String?
    public let topics: [String]?
    public let identifiedLocations: [String]?
    public let geocodedLocations: [V2GeocodeResult]?
    
    public init(
        mappedRelationships: [V2IdentifiedRelationship]? = nil,
        sentimentResult: V2SentimentAnalysisOutput? = nil,
        relevanceResult: V2RelevanceOutput? = nil,
        cleanedText: String? = nil,
        entitiesJson: String? = nil,
        topics: [String]? = nil,
        identifiedLocations: [String]? = nil,
        geocodedLocations: [V2GeocodeResult]? = nil
    ) {
        self.mappedRelationships = mappedRelationships
        self.sentimentResult = sentimentResult
        self.relevanceResult = relevanceResult
        self.cleanedText = cleanedText
        self.entitiesJson = entitiesJson
        self.topics = topics
        self.identifiedLocations = identifiedLocations
        self.geocodedLocations = geocodedLocations
    }
    
    private enum CodingKeys: String, CodingKey {
        case mappedRelationships = "mapped_relationships"
        case sentimentResult = "sentiment_result"
        case relevanceResult = "relevance_result"
        case cleanedText = "cleaned_text"
        case entitiesJson = "entities_json"
        case topics
        case identifiedLocations = "identified_locations"
        case geocodedLocations = "geocoded_locations"
    }
    
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "mapped_relationships": {"type": ["array", "null"], "items": {"$ref": "#/definitions/IdentifiedRelationship"}},
                "sentiment_result": {"$ref": "#/definitions/SentimentAnalysisOutput"},
                "relevance_result": {"$ref": "#/definitions/RelevanceOutput"},
                "cleaned_text": {"type": ["string", "null"]},
                "entities_json": {"type": ["string", "null"]},
                "topics": {"type": ["array", "null"], "items": {"type": "string"}},
                "identified_locations": {"type": ["array", "null"], "items": {"type": "string"}},
                "geocoded_locations": {"type": ["array", "null"], "items": {"$ref": "#/definitions/GeocodeResult"}}
            },
            "additionalProperties": false
        }
        """
    }
}

// MARK: - Agent 9 Models (Data Preparation)

/// Enhanced Final Data Payload with V2 metadata
/// This extends the existing FinalDataPayload with V2-specific tracking
public struct V2FinalDataPayload: V2StrictModel {
    // Core fields from original FinalDataPayload
    public let url: String
    public let processingTimestamp: String
    public let cleanedText: String?
    public let summary: String?
    public let topics: [String]?
    public let sentimentLabel: String?
    public let sentimentScore: Double?
    public let isRelevantToUtah: Bool?
    public let relevanceScore: Double?
    public let entitiesJson: String?
    public let relationships: [FinalRelationship]?
    public let locations: [FinalLocation]?
    
    // V2-specific metadata
    public let pipelineVersion: String
    public let pipelineId: String?
    public let processingMethod: String // "hybrid", "openai-only", "local-only"
    public let totalProcessingTimeMs: Int?
    public let agentsCompleted: [String]
    public let tokenUsage: V2TokenUsageMetadata?
    public let costMetadata: V2CostMetadata?
    public let dataQualityScore: Double?
    
    public init(
        url: String,
        processingTimestamp: String,
        cleanedText: String? = nil,
        summary: String? = nil,
        topics: [String]? = nil,
        sentimentLabel: String? = nil,
        sentimentScore: Double? = nil,
        isRelevantToUtah: Bool? = nil,
        relevanceScore: Double? = nil,
        entitiesJson: String? = nil,
        relationships: [FinalRelationship]? = nil,
        locations: [FinalLocation]? = nil,
        pipelineVersion: String = "v2",
        pipelineId: String? = nil,
        processingMethod: String = "hybrid",
        totalProcessingTimeMs: Int? = nil,
        agentsCompleted: [String] = [],
        tokenUsage: V2TokenUsageMetadata? = nil,
        costMetadata: V2CostMetadata? = nil,
        dataQualityScore: Double? = nil
    ) {
        self.url = url
        self.processingTimestamp = processingTimestamp
        self.cleanedText = cleanedText
        self.summary = summary
        self.topics = topics
        self.sentimentLabel = sentimentLabel
        self.sentimentScore = sentimentScore
        self.isRelevantToUtah = isRelevantToUtah
        self.relevanceScore = relevanceScore
        self.entitiesJson = entitiesJson
        self.relationships = relationships
        self.locations = locations
        self.pipelineVersion = pipelineVersion
        self.pipelineId = pipelineId
        self.processingMethod = processingMethod
        self.totalProcessingTimeMs = totalProcessingTimeMs
        self.agentsCompleted = agentsCompleted
        self.tokenUsage = tokenUsage
        self.costMetadata = costMetadata
        self.dataQualityScore = dataQualityScore
    }
    
    private enum CodingKeys: String, CodingKey {
        case url
        case processingTimestamp = "processing_timestamp"
        case cleanedText = "cleaned_text"
        case summary
        case topics
        case sentimentLabel = "sentiment_label"
        case sentimentScore = "sentiment_score"
        case isRelevantToUtah = "is_relevant_to_utah"
        case relevanceScore = "relevance_score"
        case entitiesJson = "entities_json"
        case relationships
        case locations
        case pipelineVersion = "pipeline_version"
        case pipelineId = "pipeline_id"
        case processingMethod = "processing_method"
        case totalProcessingTimeMs = "total_processing_time_ms"
        case agentsCompleted = "agents_completed"
        case tokenUsage = "token_usage"
        case costMetadata = "cost_metadata"
        case dataQualityScore = "data_quality_score"
    }
    
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "url": {"type": "string"},
                "processing_timestamp": {"type": "string"},
                "cleaned_text": {"type": ["string", "null"]},
                "summary": {"type": ["string", "null"]},
                "topics": {"type": ["array", "null"], "items": {"type": "string"}},
                "sentiment_label": {"type": ["string", "null"], "enum": ["positive", "negative", "neutral", null]},
                "sentiment_score": {"type": ["number", "null"]},
                "is_relevant_to_utah": {"type": ["boolean", "null"]},
                "relevance_score": {"type": ["number", "null"]},
                "entities_json": {"type": ["string", "null"]},
                "relationships": {"type": ["array", "null"], "items": {"$ref": "#/definitions/FinalRelationship"}},
                "locations": {"type": ["array", "null"], "items": {"$ref": "#/definitions/FinalLocation"}},
                "pipeline_version": {"type": "string"},
                "pipeline_id": {"type": ["string", "null"]},
                "processing_method": {"type": "string"},
                "total_processing_time_ms": {"type": ["integer", "null"]},
                "agents_completed": {"type": "array", "items": {"type": "string"}},
                "token_usage": {"$ref": "#/definitions/V2TokenUsageMetadata"},
                "cost_metadata": {"$ref": "#/definitions/V2CostMetadata"},
                "data_quality_score": {"type": ["number", "null"]}
            },
            "required": ["url", "processing_timestamp", "pipeline_version", "processing_method", "agents_completed"],
            "additionalProperties": false
        }
        """
    }
}

// MARK: - V2 Metadata Models

/// Token usage breakdown for V2 hybrid architecture
public struct V2TokenUsageMetadata: Codable, Sendable {
    public let openaiTokens: Int
    public let localLlmTokens: Int
    public let totalTokens: Int
    public let tokenReductionPercentage: Double
    
    public init(openaiTokens: Int, localLlmTokens: Int, totalTokens: Int, tokenReductionPercentage: Double) {
        self.openaiTokens = openaiTokens
        self.localLlmTokens = localLlmTokens
        self.totalTokens = totalTokens
        self.tokenReductionPercentage = tokenReductionPercentage
    }
    
    private enum CodingKeys: String, CodingKey {
        case openaiTokens = "openai_tokens"
        case localLlmTokens = "local_llm_tokens"
        case totalTokens = "total_tokens"
        case tokenReductionPercentage = "token_reduction_percentage"
    }
}

/// Cost metadata for V2 pipeline processing
public struct V2CostMetadata: Codable, Sendable {
    public let openaiCostUsd: Double
    public let localLlmCostUsd: Double
    public let totalCostUsd: Double
    public let v1EstimatedCostUsd: Double
    public let costSavingsPercentage: Double
    
    public init(
        openaiCostUsd: Double,
        localLlmCostUsd: Double,
        totalCostUsd: Double,
        v1EstimatedCostUsd: Double,
        costSavingsPercentage: Double
    ) {
        self.openaiCostUsd = openaiCostUsd
        self.localLlmCostUsd = localLlmCostUsd
        self.totalCostUsd = totalCostUsd
        self.v1EstimatedCostUsd = v1EstimatedCostUsd
        self.costSavingsPercentage = costSavingsPercentage
    }
    
    private enum CodingKeys: String, CodingKey {
        case openaiCostUsd = "openai_cost_usd"
        case localLlmCostUsd = "local_llm_cost_usd"
        case totalCostUsd = "total_cost_usd"
        case v1EstimatedCostUsd = "v1_estimated_cost_usd"
        case costSavingsPercentage = "cost_savings_percentage"
    }
}