//
//  SupabaseEntityRelationship.swift
//  UtahNewsData
//
//  Relationships between entities in the knowledge graph.
//  Maps to the `pipeline.entity_relationships` table.
//

import Foundation

/// A relationship between two entities (person ↔ org, org ↔ location, etc.)
nonisolated public struct SupabaseEntityRelationship: Codable, Sendable, Identifiable {
    public let id: String
    public let entityIdA: String
    public let entityTypeA: String
    public let entityIdB: String
    public let entityTypeB: String
    public let relationshipType: String
    public var confidence: Double
    public var sourceArticleId: String?
    public var metadata: [String: String]?
    public let createdAt: Date
    public var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, confidence, metadata
        case entityIdA = "entity_id_a"
        case entityTypeA = "entity_type_a"
        case entityIdB = "entity_id_b"
        case entityTypeB = "entity_type_b"
        case relationshipType = "relationship_type"
        case sourceArticleId = "source_article_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Insert model for creating entity relationships.
nonisolated public struct SupabaseEntityRelationshipInsert: Codable, Sendable {
    public let entityIdA: String
    public let entityTypeA: String
    public let entityIdB: String
    public let entityTypeB: String
    public let relationshipType: String
    public var confidence: Double
    public var sourceArticleId: String?

    public init(
        entityIdA: String,
        entityTypeA: String,
        entityIdB: String,
        entityTypeB: String,
        relationshipType: String,
        confidence: Double = 0.0,
        sourceArticleId: String? = nil
    ) {
        self.entityIdA = entityIdA
        self.entityTypeA = entityTypeA
        self.entityIdB = entityIdB
        self.entityTypeB = entityTypeB
        self.relationshipType = relationshipType
        self.confidence = confidence
        self.sourceArticleId = sourceArticleId
    }

    enum CodingKeys: String, CodingKey {
        case confidence
        case entityIdA = "entity_id_a"
        case entityTypeA = "entity_type_a"
        case entityIdB = "entity_id_b"
        case entityTypeB = "entity_type_b"
        case relationshipType = "relationship_type"
        case sourceArticleId = "source_article_id"
    }
}

/// Well-known relationship types
extension SupabaseEntityRelationshipInsert {
    nonisolated public enum RelationshipType {
        public static let employedBy = "employed_by"
        public static let foundedBy = "founded_by"
        public static let locatedIn = "located_in"
        public static let partnerOf = "partner_of"
        public static let memberOf = "member_of"
        public static let subsidiaryOf = "subsidiary_of"
        public static let electedTo = "elected_to"
        public static let headOf = "head_of"
        public static let spouseOf = "spouse_of"
        public static let relatedTo = "related_to"
    }
}
