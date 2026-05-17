//
//  Article.swift
//  UtahNewsDataModels
//
//  Created by Mark Evans on 01/29/25
//
//  Summary: Defines the Article model which represents a news article in the UtahNewsDataModels system.
//           Lightweight version without HTML parsing capabilities.

import Foundation

/// A struct representing an article in the news app.
/// Articles are a type of news content that can maintain relationships with other entities.
public struct Article: NewsContent, AssociatedData, JSONSchemaProvider, Sendable {
    /// Unique identifier for the article
    public var id: String

    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []

    /// Title or headline of the article
    public var title: String

    /// URL where the article can be accessed
    public var url: String

    /// URL to a featured image for the article
    public var urlToImage: String?

    /// Additional images associated with the article
    public var additionalImages: [String]?

    /// When the article was published
    public var publishedAt: Date

    /// The main text content of the article
    public var textContent: String?

    /// Author or writer of the article
    public var author: String?

    /// Category or section the article belongs to
    public var category: String?

    /// URL to a video associated with the article
    public var videoURL: String?

    /// Geographic location associated with the article
    public var location: Location?
    
    /// Indicates if the article is relevant to Utah (used for filtering)
    public var isRelevantToUtah: Bool
    
    /// Indicates if this content was AI-generated (vs ingested from source)
    public var generated: Bool
    
    /// Type of content (e.g., "ingested", "generated", "curated")
    public var contentType: String
    
    /// ISO timestamp when the article was processed by the pipeline
    public var processingTimestamp: String?
    
    /// Array of related article IDs for cross-referencing
    public var relatedArticleIds: [String]

    // MARK: - Sprint AA: signal-trigger / link-out card support

    /// Type of article: full original-reporting piece or a link-out card
    /// pointing at a news-outlet signal while our primary-source investigation
    /// is in progress. nil for legacy articles (treat as fullArticle).
    public var articleType: ArticleType?

    /// Outlet display name when articleType == .linkOutCard ("KSL", "Park Record").
    /// Retained after upgrade to fullArticle as an "Also reported by" footer.
    public var attributionOutletName: String?

    /// Source URL the card links out to. Reader taps the card to open this.
    /// Same as `url` for cards; may differ post-upgrade.
    public var attributionUrl: String?

    /// When the outlet originally published the story.
    public var attributionPublishedAt: Date?

    /// When a link-out card was upgraded to a full article (Sprint AA.4).
    /// nil for cards still awaiting primaries, or articles created from
    /// primary sources directly.
    public var upgradedAt: Date?

    /// Whether this article should be rendered as a card vs full article.
    public var isLinkOutCard: Bool {
        articleType == .linkOutCard
    }

    // MARK: - Initializers

    /// Creates a new article with the specified properties.
    public init(
        id: String = UUID().uuidString,
        title: String,
        url: String,
        urlToImage: String? = nil,
        additionalImages: [String]? = nil,
        publishedAt: Date = Date(),
        textContent: String? = nil,
        author: String? = nil,
        category: String? = nil,
        videoURL: String? = nil,
        location: Location? = nil,
        relationships: [Relationship] = [],
        isRelevantToUtah: Bool = true,
        generated: Bool = false,
        contentType: String = "ingested",
        processingTimestamp: String? = nil,
        relatedArticleIds: [String] = [],
        articleType: ArticleType? = nil,
        attributionOutletName: String? = nil,
        attributionUrl: String? = nil,
        attributionPublishedAt: Date? = nil,
        upgradedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.urlToImage = urlToImage
        self.additionalImages = additionalImages
        self.publishedAt = publishedAt
        self.textContent = textContent
        self.author = author
        self.category = category
        self.videoURL = videoURL
        self.location = location
        self.relationships = relationships
        self.isRelevantToUtah = isRelevantToUtah
        self.generated = generated
        self.contentType = contentType
        self.processingTimestamp = processingTimestamp
        self.relatedArticleIds = relatedArticleIds
        self.articleType = articleType
        self.attributionOutletName = attributionOutletName
        self.attributionUrl = attributionUrl
        self.attributionPublishedAt = attributionPublishedAt
        self.upgradedAt = upgradedAt
    }

    // MARK: - Methods

    /// Determines the appropriate MediaType for this Article.
    public func determineMediaType() -> MediaType {
        return .text
    }

    // MARK: - JSON Schema Provider

    /// Provides the JSON schema for Article.
    public static var jsonSchema: String {
        return """
            {
                "type": "object",
                "properties": {
                    "id": {"type": "string"},
                    "title": {"type": "string"},
                    "url": {"type": "string"},
                    "urlToImage": {"type": ["string", "null"]},
                    "additionalImages": {"type": ["array", "null"], "items": {"type": "string"}},
                    "publishedAt": {"type": "string", "format": "date-time"},
                    "textContent": {"type": ["string", "null"]},
                    "author": {"type": ["string", "null"]},
                    "category": {"type": ["string", "null"]},
                    "videoURL": {"type": ["string", "null"]},
                    "location": {"type": ["object", "null"]}
                },
                "required": ["id", "title", "url", "publishedAt"]
            }
            """
    }
}

/// Extension providing an example Article for previews and testing.
public extension Article {
    /// An example instance of `Article` for previews and testing.
    static let example = Article(
        title: "Utah News App Launches Today: Get the Latest News, Sports, and Weather",
        url: "https://www.utahnews.com",
        urlToImage: "https://picsum.photos/800/1200",
        textContent: """
            Utah News is a news app for Utah. Get the latest news, sports, and weather from Utah News.
            Stay informed about local events and stories that matter to you.
            """,
        author: "Mark Evans",
        category: "News"
    )
}