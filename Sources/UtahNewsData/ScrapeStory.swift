//
//  File.swift
//  UtahNewsData
//
//  Created by Mark Evans on 11/26/24.
//

import Foundation


// MARK: - StoryExtract
public struct StoryExtract: Codable {
    public let stories: [ScrapeStory]
}

// MARK: - ScrapeStory
public struct ScrapeStory: Codable, Sendable {
//    var id: String
    public var title: String?
    public var textContent: String?
    public var url: String?
    public var urlToImage: String?
    public var additionalImages: [String]?
    public var publishedAt: String?
    public var author: String?
    public var category: String?
    public var videoURL: String?
}


public struct SingleStoryResponse: Codable {
    public let success: Bool
    public let data: SingleStoryData
}

// MARK: - SingleStoryData
public struct SingleStoryData: Codable {
    public let extract: ScrapeStory
}


// MARK: - FirecrawlResponse
public struct FirecrawlResponse: Codable {
    public let success: Bool
    public let data: FirecrawlData
}

// MARK: - FirecrawlData
public struct FirecrawlData: Codable {
    public let extract: StoryExtract
}
