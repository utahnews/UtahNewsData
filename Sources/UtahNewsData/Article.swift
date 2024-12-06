//
//  Article.swift
//  UtahNewsData
//
//  Created by Mark Evans on 11/18/24.
//

import SwiftUI
import Foundation

/// A struct representing an article in the news app.
public struct Article: NewsContent, Identifiable {
    public var id: UUID
    public var title: String
    public var url: String
    public var urlToImage: String?
    public var additionalImages: [String]?
    public var publishedAt: Date
    public var textContent: String?
    public var author: String?
    public var category: String?
    public var videoURL: String?
    public var location: Location?
    

    
   public init?(from scrapeStory: ScrapeStory, baseURL: String?) {
       self.id = UUID()

       guard let title = scrapeStory.title, !title.isEmpty else {
           print("Invalid title in ScrapeStory: \(scrapeStory)")
           return nil
       }
       self.title = title

       if let urlString = scrapeStory.url, !urlString.isEmpty {
           if let validURLString = urlString.constructValidURL(baseURL: baseURL) {
               self.url = validURLString
           } else {
               print("Invalid URL in ScrapeStory: \(scrapeStory)")
               return nil
           }
       } else {
           print("Missing URL in ScrapeStory: \(scrapeStory)")
           return nil
       }

       self.urlToImage = scrapeStory.urlToImage?.constructValidURL(baseURL: baseURL)
       self.textContent = scrapeStory.textContent
       self.author = scrapeStory.author
       self.category = scrapeStory.category
       self.videoURL = scrapeStory.videoURL?.constructValidURL(baseURL: baseURL)

       // Parse date
       if let publishedAtString = scrapeStory.publishedAt {
           let isoFormatter = ISO8601DateFormatter()
           if let date = isoFormatter.date(from: publishedAtString) {
               self.publishedAt = date
           } else {
               print("Invalid date format in ScrapeStory: \(scrapeStory)")
               self.publishedAt = Date()
           }
       } else {
           self.publishedAt = Date()
       }
   }
}

public extension Article {
    init(
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



struct MapResponse: Codable {
    let success: Bool
    let links: [String]
}

