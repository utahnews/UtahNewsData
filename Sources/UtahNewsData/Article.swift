//
//  Article.swift
//  UtahNewsData
//
//  Created by Mark Evans on 11/18/24.
//

import SwiftUI
import Foundation

/// A struct representing an article in the news app.
public struct Article: NewsContent {
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
        // Generate a unique ID
        self.id = UUID()

        self.title = scrapeStory.title ?? "No Title"
        self.urlToImage = scrapeStory.urlToImage?.constructValidURL(baseURL: baseURL) ?? "https://picsum.photos/800/1200"
        self.textContent = scrapeStory.textContent ?? ""
        self.author = scrapeStory.author
        self.category = scrapeStory.category
        self.videoURL = scrapeStory.videoURL?.constructValidURL(baseURL: baseURL)

        // Construct valid URL for 'url'
        if let urlString = scrapeStory.url, !urlString.isEmpty {
            if let validURLString = urlString.constructValidURL(baseURL: baseURL) {
                self.url = validURLString
            } else {
                return nil // Cannot construct valid URL
            }
        } else {
            return nil // No URL
        }

        // Simplified date parsing
        if let publishedAtString = scrapeStory.publishedAt, !publishedAtString.isEmpty {
            let isoFormatter = ISO8601DateFormatter()
            if let date = isoFormatter.date(from: publishedAtString) {
                self.publishedAt = date
            } else {
                // Attempt alternative standard formats
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

                // Try common date formats
                let dateFormats = [
                    "yyyy-MM-dd'T'HH:mm:ssZ",
                    "yyyy-MM-dd",
                    "MM/dd/yyyy",
                    "MMMM d, yyyy",
                    "d MMM yyyy"
                ]

                var parsedDate: Date? = nil
                for format in dateFormats {
                    dateFormatter.dateFormat = format
                    if let date = dateFormatter.date(from: publishedAtString) {
                        parsedDate = date
                        break
                    }
                }

                if let date = parsedDate {
                    self.publishedAt = date
                } else {
                    // Could not parse date; set to nil
                    print("Failed to parse publishedAt string: \(publishedAtString)")
                    self.publishedAt = Date()
                }
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



