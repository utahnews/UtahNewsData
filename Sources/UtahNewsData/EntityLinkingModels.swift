//
//  EntityLinkingModels.swift
//  UtahNewsData
//
//  Data models for entity matching, mentions, and knowledge graph linking
//  Used by V2PipelineTester, UtahNews, NewsCapture for entity-article relationships
//
//  Collections:
//  - people/{personId}/mentions - Article mentions of people
//  - organizations/{orgId}/mentions - Article mentions of organizations
//  - entity_aliases - Alias mappings for name resolution
//  - unmatched_entities - Entities pending auto-creation
//

import Foundation
import CommonCrypto

// MARK: - Match Type

/// How an entity was matched to the knowledge graph
public enum MatchType: String, Codable, Sendable {
    /// Exact name match: "Spencer Cox" → "Spencer Cox"
    case exact
    /// Normalized match (case/spacing): "SPENCER COX" → "Spencer Cox"
    case normalized
    /// Alias match: "Gov. Cox" → "Spencer Cox"
    case alias
}

// MARK: - Unmatched Status

/// Status of unmatched entity tracking in `unmatched_entities` collection
public enum UnmatchedStatus: String, Codable, Sendable {
    /// Still being tracked for potential creation
    case tracking
    /// Entity was auto-created
    case created
    /// Entity was manually rejected
    case rejected
}

// MARK: - Alias Source

/// Source of an entity alias
public enum AliasSource: String, Codable, Sendable {
    /// Automatically generated from name patterns
    case auto
    /// Manually added by user/admin
    case manual
}

// MARK: - Entity Mention

/// Record of an entity mention in an article
/// Stored in `people/{personId}/mentions` or `organizations/{orgId}/mentions` subcollections
public struct EntityMention: Codable, Identifiable, Sendable {
    /// Unique ID combining article and entity (computed from articleId_entityId)
    public var id: String { "\(articleId)_\(entityId)" }

    /// ID of the entity being mentioned
    public let entityId: String

    /// Type of entity: "person", "organization", "location"
    public let entityType: String

    /// ID of the article containing the mention
    public let articleId: String

    /// URL of the article
    public let articleUrl: String

    /// Title of the article
    public let articleTitle: String

    /// When the mention was recorded
    public let mentionedAt: Date

    /// Original text as extracted
    public let extractedText: String

    /// How the match was made
    public let matchType: MatchType

    /// Confidence score (0.0 - 1.0)
    public let confidence: Double

    /// Surrounding text snippet (optional, for context)
    public let contextSnippet: String?

    public init(
        entityId: String,
        entityType: String,
        articleId: String,
        articleUrl: String,
        articleTitle: String,
        extractedText: String,
        matchType: MatchType,
        confidence: Double,
        contextSnippet: String? = nil
    ) {
        self.entityId = entityId
        self.entityType = entityType
        self.articleId = articleId
        self.articleUrl = articleUrl
        self.articleTitle = articleTitle
        self.mentionedAt = Date()
        self.extractedText = extractedText
        self.matchType = matchType
        self.confidence = confidence
        self.contextSnippet = contextSnippet
    }
}

// MARK: - Entity Alias

/// Alias mapping for entity name resolution
/// Stored in `entity_aliases` collection
public struct EntityAlias: Codable, Identifiable, Sendable {
    /// Unique ID (hash of normalized alias) - computed property
    public var id: String { normalizedAlias.sha1Hash() }

    /// ID of the canonical entity this alias points to
    public let canonicalId: String

    /// Type of canonical entity: "person" or "organization"
    public let canonicalType: String

    /// The alias text (normalized)
    public let normalizedAlias: String

    /// Original alias text before normalization
    public let originalAlias: String

    /// When the alias was added
    public let addedAt: Date

    /// Source of the alias
    public let source: AliasSource

    public init(
        canonicalId: String,
        canonicalType: String,
        alias: String,
        normalizedAlias: String,
        source: AliasSource
    ) {
        self.canonicalId = canonicalId
        self.canonicalType = canonicalType
        self.originalAlias = alias
        self.normalizedAlias = normalizedAlias
        self.addedAt = Date()
        self.source = source
    }
}

// MARK: - Unmatched Entity

/// Entity that couldn't be matched to existing people/organizations
/// Stored in `unmatched_entities` collection for tracking and potential auto-creation
public struct UnmatchedEntity: Codable, Sendable, Identifiable {
    /// Unique ID based on normalized text hash
    public var id: String { normalizedText.sha1Hash() }

    /// Original extracted text
    public let text: String

    /// Normalized version for matching
    public let normalizedText: String

    /// Entity type: "person", "organization", "location"
    public let type: String

    /// Confidence from extraction (0.0 - 1.0)
    public let confidence: Double

    /// Number of articles mentioning this entity
    public var articleCount: Int

    /// IDs of articles mentioning this entity
    public var articleIds: [String]

    /// When first seen
    public let firstSeen: Date

    /// When last seen
    public var lastSeen: Date

    /// Tracking status
    public var status: UnmatchedStatus

    public init(
        text: String,
        normalizedText: String,
        type: String,
        confidence: Double,
        articleId: String
    ) {
        self.text = text
        self.normalizedText = normalizedText
        self.type = type
        self.confidence = confidence
        self.articleCount = 1
        self.articleIds = [articleId]
        self.firstSeen = Date()
        self.lastSeen = Date()
        self.status = .tracking
    }

    /// Check if entity qualifies for auto-creation
    /// Requirements: confidence >= 0.8, appears in 2+ articles, is person or organization
    public var qualifiesForAutoCreation: Bool {
        confidence >= 0.8 &&
        articleCount >= 2 &&
        (type == "person" || type == "organization") &&
        status == .tracking
    }
}

// MARK: - Name Normalization Patterns

/// Common patterns for name normalization during entity matching
public enum NameNormalization {
    /// Title prefixes to strip (with and without periods)
    public static let titlePrefixes: Set<String> = [
        "gov", "gov.", "governor",
        "sen", "sen.", "senator",
        "rep", "rep.", "representative",
        "dr", "dr.", "doctor",
        "mr", "mr.", "mister",
        "mrs", "mrs.",
        "ms", "ms.",
        "miss",
        "prof", "prof.", "professor",
        "rev", "rev.", "reverend",
        "hon", "hon.", "honorable",
        "pres", "pres.", "president",
        "vp", "vice president",
        "ceo", "cfo", "coo", "cto",
        "mayor",
        "chief",
        "director",
        "commissioner",
        "councilman", "councilwoman", "councilmember",
        "chairman", "chairwoman", "chair"
    ]

    /// Suffixes to strip
    public static let suffixes: Set<String> = [
        "jr", "jr.",
        "sr", "sr.",
        "ii", "iii", "iv", "v",
        "phd", "ph.d", "ph.d.",
        "md", "m.d", "m.d.",
        "esq", "esq.",
        "llc", "inc", "corp"
    ]

    /// Utah-specific location abbreviations
    public static let utahAbbreviations: [String: [String]] = [
        "salt lake city": ["slc", "salt lake"],
        "st george": ["saint george", "st. george"],
        "st. george": ["saint george", "st george"],
        "provo": ["provo city"],
        "ogden": ["ogden city"],
        "sandy": ["sandy city"],
        "west valley city": ["west valley", "wvc"],
        "west jordan": ["west jordan city"],
        "orem": ["orem city"],
        "layton": ["layton city"],
        "lehi": ["lehi city"],
        "south jordan": ["south jordan city"],
        "logan": ["logan city"],
        "murray": ["murray city"],
        "draper": ["draper city"],
        "bountiful": ["bountiful city"],
        "riverton": ["riverton city"],
        "herriman": ["herriman city"],
        "spanish fork": ["spanish fork city"],
        "pleasant grove": ["pleasant grove city", "pg"],
        "american fork": ["american fork city", "af"],
        "roy": ["roy city"],
        "clearfield": ["clearfield city"],
        "syracuse": ["syracuse city"],
        "kaysville": ["kaysville city"],
        "farmington": ["farmington city"],
        "centerville": ["centerville city"],
        "north salt lake": ["nsl", "n salt lake"],
        "woods cross": ["woods cross city"],
        "park city": ["park city utah"]
    ]
}

// MARK: - String Extension for SHA1 Hashing

extension String {
    /// Computes SHA-1 hash of the string for generating consistent document IDs
    public func sha1Hash() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}
