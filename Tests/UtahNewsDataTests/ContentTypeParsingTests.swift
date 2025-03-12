//
//  ContentTypeParsingTests.swift
//  UtahNewsDataTests
//
//  Created by Mark Evans on 3/21/24
//
//  Summary: Tests for HTML parsing functionality of various content types.

import XCTest
import SwiftSoup
@testable import UtahNewsData

final class ContentTypeParsingTests: XCTestCase {
    
    // MARK: - Test Data
    
    let sampleVideoHTML = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Test Video</title>
        <meta property="og:title" content="Sample Video Title">
        <meta property="og:image" content="https://example.com/thumbnail.jpg">
        <meta property="video:duration" content="300">
        <meta property="og:video:width" content="1920">
        <meta property="og:video:height" content="1080">
        <meta property="og:description" content="A sample video description">
        <meta property="article:published_time" content="2024-03-21T10:00:00Z">
        <meta property="og:url" content="https://example.com/video">
    </head>
    <body>
        <div itemprop="author">Jane Smith</div>
    </body>
    </html>
    """
    
    let sampleAudioHTML = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Test Audio</title>
        <meta property="og:title" content="Sample Audio Title">
        <meta property="og:image" content="https://example.com/cover.jpg">
        <meta property="audio:duration" content="240">
        <meta property="audio:bitrate" content="256">
        <meta property="og:description" content="A sample audio description">
        <meta property="article:published_time" content="2024-03-21T10:00:00Z">
        <meta property="og:url" content="https://example.com/audio">
    </head>
    <body>
        <div itemprop="author">John Doe</div>
    </body>
    </html>
    """
    
    let sampleNewsStoryHTML = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Test News Story</title>
        <meta property="og:title" content="Breaking News Story">
        <meta property="og:image" content="https://example.com/story.jpg">
        <meta property="article:published_time" content="2024-03-21T10:00:00Z">
        <meta property="og:url" content="https://example.com/story">
    </head>
    <body>
        <h1 class="story-headline">Major Event Unfolds</h1>
        <div class="story-content">
            <p>This is a breaking news story about a major event.</p>
            <p>More details are emerging as the situation develops.</p>
        </div>
        <div itemprop="author">Sarah Johnson</div>
    </body>
    </html>
    """
    
    let sampleStatisticalDataHTML = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Statistical Report</title>
        <meta property="article:published_time" content="2024-03-21T10:00:00Z">
    </head>
    <body>
        <h1 class="stat-title">Utah Employment Rate</h1>
        <div itemprop="value" class="stat-value">96.5</div>
        <div itemprop="unitText" class="stat-unit">percent</div>
        <div itemprop="sourceOrganization" class="stat-source">Utah Department of Workforce Services</div>
        <div itemprop="methodology" class="stat-methodology">Monthly survey of employers</div>
        <div itemprop="marginOfError" class="stat-margin">±0.5</div>
    </body>
    </html>
    """
    
    // MARK: - Video Parsing Tests
    
    func testVideoParsing() throws {
        let document = try SwiftSoup.parse(sampleVideoHTML)
        let video = try Video.parse(from: document)
        
        XCTAssertEqual(video.title, "Sample Video Title")
        XCTAssertEqual(video.url, "https://example.com/video")
        XCTAssertEqual(video.urlToImage, "https://example.com/thumbnail.jpg")
        XCTAssertEqual(video.author, "Jane Smith")
        XCTAssertEqual(video.duration, 300)
        XCTAssertEqual(video.resolution, "1920x1080")
        XCTAssertEqual(video.textContent, "A sample video description")
    }
    
    // MARK: - Audio Parsing Tests
    
    func testAudioParsing() throws {
        let document = try SwiftSoup.parse(sampleAudioHTML)
        let audio = try Audio.parse(from: document)
        
        XCTAssertEqual(audio.title, "Sample Audio Title")
        XCTAssertEqual(audio.url, "https://example.com/audio")
        XCTAssertEqual(audio.urlToImage, "https://example.com/cover.jpg")
        XCTAssertEqual(audio.author, "John Doe")
        XCTAssertEqual(audio.duration, 240)
        XCTAssertEqual(audio.bitrate, 256)
        XCTAssertEqual(audio.textContent, "A sample audio description")
    }
    
    // MARK: - News Story Parsing Tests
    
    func testNewsStoryParsing() throws {
        let document = try SwiftSoup.parse(sampleNewsStoryHTML)
        let story = try NewsStory.parse(from: document)
        
        XCTAssertEqual(story.headline, "Major Event Unfolds")
        XCTAssertEqual(story.url, "https://example.com/story")
        XCTAssertEqual(story.featuredImageURL, "https://example.com/story.jpg")
        XCTAssertEqual(story.author.name, "Sarah Johnson")
        XCTAssertTrue(story.content?.contains("breaking news story") ?? false)
        XCTAssertTrue(story.content?.contains("situation develops") ?? false)
    }
    
    // MARK: - Statistical Data Parsing Tests
    
    func testStatisticalDataParsing() throws {
        let document = try SwiftSoup.parse(sampleStatisticalDataHTML)
        let stats = try StatisticalData.parse(from: document)
        
        XCTAssertEqual(stats.title, "Utah Employment Rate")
        XCTAssertEqual(stats.value, "96.5")
        XCTAssertEqual(stats.unit, "percent")
        XCTAssertEqual(stats.source?.name, "Utah Department of Workforce Services")
        XCTAssertEqual(stats.methodology, "Monthly survey of employers")
        XCTAssertEqual(stats.marginOfError, "±0.5")
    }
    
    // MARK: - Invalid HTML Tests
    
    func testInvalidHTML() throws {
        let invalidHTML = "<invalid>HTML"
        
        XCTAssertThrowsError(try Video.parse(from: invalidHTML)) { error in
            XCTAssertEqual(error as? ParsingError, .invalidHTML)
        }
        
        XCTAssertThrowsError(try Audio.parse(from: invalidHTML)) { error in
            XCTAssertEqual(error as? ParsingError, .invalidHTML)
        }
        
        XCTAssertThrowsError(try NewsStory.parse(from: invalidHTML)) { error in
            XCTAssertEqual(error as? ParsingError, .invalidHTML)
        }
        
        XCTAssertThrowsError(try StatisticalData.parse(from: invalidHTML)) { error in
            XCTAssertEqual(error as? ParsingError, .invalidHTML)
        }
    }
    
    // MARK: - Missing Required Fields Tests
    
    func testMissingRequiredFields() throws {
        let emptyHTML = """
        <!DOCTYPE html>
        <html>
        <head></head>
        <body></body>
        </html>
        """
        
        XCTAssertThrowsError(try Video.parse(from: emptyHTML)) { error in
            XCTAssertEqual(error as? ParsingError, .invalidHTML)
        }
        
        XCTAssertThrowsError(try Audio.parse(from: emptyHTML)) { error in
            XCTAssertEqual(error as? ParsingError, .invalidHTML)
        }
        
        XCTAssertThrowsError(try NewsStory.parse(from: emptyHTML)) { error in
            XCTAssertEqual(error as? ParsingError, .invalidHTML)
        }
        
        XCTAssertThrowsError(try StatisticalData.parse(from: emptyHTML)) { error in
            XCTAssertEqual(error as? ParsingError, .invalidHTML)
        }
    }
    
    // MARK: - Adaptive Parser Integration Tests
    
    func testAdaptiveParserWithDifferentTypes() async throws {
        let parser = await AdaptiveParser(llmManager: MockLLMManager())
        
        // Test with Video
        let videoURL = URL(string: "https://example.com/video")!
        let videoResult = try await parser.parseWithFallback(html: sampleVideoHTML, from: videoURL, as: Video.self)
        if case .success(let video, source: let source) = videoResult {
            XCTAssertEqual(source, .htmlParsing)
            XCTAssertEqual(video.title, "Sample Video Title")
        } else {
            XCTFail("Video parsing should succeed")
        }
        
        // Test with Audio
        let audioURL = URL(string: "https://example.com/audio")!
        let audioResult = try await parser.parseWithFallback(html: sampleAudioHTML, from: audioURL, as: Audio.self)
        if case .success(let audio, source: let source) = audioResult {
            XCTAssertEqual(source, .htmlParsing)
            XCTAssertEqual(audio.title, "Sample Audio Title")
        } else {
            XCTFail("Audio parsing should succeed")
        }
        
        // Test with NewsStory
        let storyURL = URL(string: "https://example.com/story")!
        let storyResult = try await parser.parseWithFallback(html: sampleNewsStoryHTML, from: storyURL, as: NewsStory.self)
        if case .success(let story, source: let source) = storyResult {
            XCTAssertEqual(source, .htmlParsing)
            XCTAssertEqual(story.headline, "Major Event Unfolds")
        } else {
            XCTFail("NewsStory parsing should succeed")
        }
        
        // Test with StatisticalData
        let statsURL = URL(string: "https://example.com/stats")!
        let statsResult = try await parser.parseWithFallback(html: sampleStatisticalDataHTML, from: statsURL, as: StatisticalData.self)
        if case .success(let stats, source: let source) = statsResult {
            XCTAssertEqual(source, .htmlParsing)
            XCTAssertEqual(stats.title, "Utah Employment Rate")
        } else {
            XCTFail("StatisticalData parsing should succeed")
        }
    }
    
    // MARK: - Real-World URL Tests
    
    @MainActor
    func testRealWorldURLParsing() async throws {
        // Use real LLM manager instead of mock
        let parser = await AdaptiveParser(llmManager: LocalLLMManager())
        let networkClient = NetworkClient()
        
        // Site-specific selector sets
        let selectorSets: [String: AdaptiveParser.SelectorSet] = [
            "deseret.com": AdaptiveParser.SelectorSet(
                title: "h1.headline, h1.article-headline, meta[property='og:title']",
                content: "article.article-content, [itemprop='articleBody'], .article-body",
                author: ".author-name, .byline, meta[name='author']",
                date: "time[datetime], meta[property='article:published_time']",
                image: ".article-featured-image img, meta[property='og:image']",
                category: ".article-category, meta[property='article:section']"
            ),
            
            "heraldextra.com": AdaptiveParser.SelectorSet(
                title: "h1.article-headline, h1.headline, meta[property='og:title']",
                content: ".article-body, [itemprop='articleBody']",
                author: ".author-name, .byline, meta[name='author']",
                date: "time[datetime], meta[property='article:published_time']",
                image: ".article-image img, meta[property='og:image']",
                category: ".article-category, meta[property='article:section']"
            )
        ]
        
        let urls = [
            // Deseret News Articles
            "https://www.deseret.com/politics/2025/03/08/profanity-donald-trump-anderson-cooper-anora/",
            "https://www.deseret.com/sports/2025/03/04/byu-basketball-beats-iowa-state/",
            "https://www.deseret.com/sports/2025/03/05/tj-otzelberger-iowa-state-loss-against-byu/",
            "https://www.deseret.com/politics/2025/03/07/celeste-maloy-wants-to-end-daylight-saving/",
            
            // Herald Extra Articles
            "https://www.heraldextra.com/news/local/2025/mar/08/hundreds-learn-cutting-edge-research-at-uvus-autism-conference/",
            "https://www.heraldextra.com/news/local/2025/mar/07/lindon-city-council-denies-proposal-to-scrap-future-roadway-plan/",
            "https://www.heraldextra.com/news/local/2025/mar/07/utah-county-commission-approves-pay-raises-for-county-employees-elected-officals/"
        ]
        
        for urlString in urls {
            guard let url = URL(string: urlString) else {
                XCTFail("Invalid URL: \(urlString)")
                continue
            }
            
            do {
                // Get the domain-specific selector set
                if let domain = url.host?.replacingOccurrences(of: "www.", with: ""),
                   let selectorSet = selectorSets[domain] {
                    parser.learn(selectors: selectorSet, for: domain)
                }
                
                // Fetch real HTML content
                let html = try await networkClient.fetchHTML(from: url)
                print("\n--- Processing \(url.lastPathComponent) ---")
                
                // First try HTML parsing
                do {
                    let document = try SwiftSoup.parse(html)
                    if let article = try? Article.parse(from: document) {
                        print("HTML Parsing succeeded:")
                        print("Title: \(article.title)")
                        print("Author: \(article.author ?? "Unknown")")
                        print("Category: \(article.category ?? "Unknown")")
                        print("Content length: \(article.textContent?.count ?? 0) characters")
                        continue
                    }
                } catch {
                    print("HTML parsing failed, falling back to LLM")
                }
                
                // If HTML parsing fails, try LLM extraction
                let result = try await parser.parseWithFallback(html: html, from: url, as: Article.self)
                switch result {
                case .success(let article, source: let source):
                    print("LLM Extraction succeeded:")
                    print("Title: \(article.title)")
                    print("Author: \(article.author ?? "Unknown")")
                    print("Category: \(article.category ?? "Unknown")")
                    print("Content length: \(article.textContent?.count ?? 0) characters")
                    print("Source: \(source)")
                    
                    // Validate the extracted content
                    XCTAssertFalse(article.title.isEmpty, "Title should not be empty")
                    XCTAssertFalse(article.textContent?.isEmpty ?? true, "Content should not be empty")
                    XCTAssertNotNil(article.author, "Author should be extracted")
                    XCTAssertNotNil(article.category, "Category should be extracted")
                    
                case .failure(let error):
                    XCTFail("Failed to parse article: \(error)")
                }
                
                print("---")
            } catch {
                XCTFail("Failed to process \(urlString): \(error)")
            }
        }
    }
} 