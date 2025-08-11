//
//  FinalDataPayload.swift
//  UtahNewsData
//
//  Created for alignment with backend Agent 9 output structure
//  Corresponds to app/models/pipeline_models.py:FinalDataPayload
//

import Foundation

/// Represents a relationship between entities extracted from content
public struct FinalRelationship: Codable, Sendable {
    public var subject: String?
    public var predicate: String?
    public var objectValue: String?
    public var confidence: Double?
    
    public init(
        subject: String? = nil,
        predicate: String? = nil,
        objectValue: String? = nil,
        confidence: Double? = nil
    ) {
        self.subject = subject
        self.predicate = predicate
        self.objectValue = objectValue
        self.confidence = confidence
    }
    
    private enum CodingKeys: String, CodingKey {
        case subject
        case predicate
        case objectValue = "object_value"
        case confidence
    }
}

/// Represents a geocoded location from the pipeline
public struct FinalLocation: Codable, Sendable {
    public var query: String?
    public var status: String?
    public var latitude: Double?
    public var longitude: Double?
    public var address: String?
    
    public init(
        query: String? = nil,
        status: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        address: String? = nil
    ) {
        self.query = query
        self.status = status
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
    }
}

/// Final output payload from Agent 9 in the pipeline
/// Aligns with backend FinalDataPayload structure
public struct FinalDataPayload: Codable, Sendable, JSONSchemaProvider {
    public var url: String
    public var processingTimestamp: String?
    public var cleanedText: String?
    public var summary: String?
    public var topics: [String]?
    public var sentimentLabel: String?
    public var sentimentScore: Double?
    public var isRelevantToUtah: Bool?
    public var relevanceScore: Double?
    public var entitiesJson: String?
    public var relationships: [FinalRelationship]?
    public var locations: [FinalLocation]?
    
    public init(
        url: String,
        processingTimestamp: String? = nil,
        cleanedText: String? = nil,
        summary: String? = nil,
        topics: [String]? = nil,
        sentimentLabel: String? = nil,
        sentimentScore: Double? = nil,
        isRelevantToUtah: Bool? = nil,
        relevanceScore: Double? = nil,
        entitiesJson: String? = nil,
        relationships: [FinalRelationship]? = nil,
        locations: [FinalLocation]? = nil
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
    }
    
    // MARK: - JSON Schema Provider
    
    public static var jsonSchema: String {
        return """
            {
                "type": "object",
                "properties": {
                    "url": {"type": "string"},
                    "processing_timestamp": {"type": ["string", "null"]},
                    "cleaned_text": {"type": ["string", "null"]},
                    "summary": {"type": ["string", "null"]},
                    "topics": {"type": ["array", "null"], "items": {"type": "string"}},
                    "sentiment_label": {"type": ["string", "null"], "enum": ["positive", "negative", "neutral", "unknown", null]},
                    "sentiment_score": {"type": ["number", "null"]},
                    "is_relevant_to_utah": {"type": ["boolean", "null"]},
                    "relevance_score": {"type": ["number", "null"]},
                    "entities_json": {"type": ["string", "null"]},
                    "relationships": {
                        "type": ["array", "null"],
                        "items": {
                            "type": "object",
                            "properties": {
                                "subject": {"type": ["string", "null"]},
                                "predicate": {"type": ["string", "null"]},
                                "object_value": {"type": ["string", "null"]},
                                "confidence": {"type": ["number", "null"]}
                            }
                        }
                    },
                    "locations": {
                        "type": ["array", "null"],
                        "items": {
                            "type": "object",
                            "properties": {
                                "query": {"type": ["string", "null"]},
                                "status": {"type": ["string", "null"]},
                                "latitude": {"type": ["number", "null"]},
                                "longitude": {"type": ["number", "null"]},
                                "address": {"type": ["string", "null"]}
                            }
                        }
                    }
                },
                "required": ["url"]
            }
            """
    }
}