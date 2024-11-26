//
//  Article.swift
//  UtahNewsData
//
//  Created by Mark Evans on 11/18/24.
//

import Foundation

/// A struct representing an article in the news app.
public struct Article: NewsContent {
    public var id: UUID
    public var title: String
    public var url: String
    public var urlToImage: String?
    public var publishedAt: Date
    public var textContent: String?
    public var author: String?
    public var category: String?
    public var location: Location?
    
    public init(
        id: UUID = UUID(),
        title: String,
        url: String,
        urlToImage: String? = "https://picsum.photos/800/1200",
        publishedAt: Date = Date(),
        textContent: String? = nil,
        author: String? = nil,
        category: String? = nil,
        location: Location? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.urlToImage = urlToImage
        self.publishedAt = publishedAt
        self.textContent = textContent
        self.author = author
        self.category = category
        self.location = location
    }
}

public extension Article {
    /// An example instance of `Article` for previews and testing.
    @MainActor static let example = Article(
        title: "Utah News App Launches Today: Get the Latest News, Sports, and Weather",
        url: "https://www.utahnews.com",
        urlToImage: "https://picsum.photos/800/1200",
        textContent: """
        Utah News is a news app for Utah. Get the latest news, sports, and weather from Utah News. Stay informed about local events and stories that matter to you.
        """,
        author: "Mark Evans",
        category: "News"
    )
}


public struct Location: Codable, Identifiable, Hashable {
    public var id: String
    
    public var latitude: Double
    public var longitude: Double
    public var name: String
}
