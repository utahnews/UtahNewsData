//
//  HTMLParsingTests.swift
//  UtahNewsDataTests
//
//  Created by Mark Evans on 3/21/24
//
//  Summary: Tests for HTML parsing functionality.

import XCTest
import SwiftSoup
@testable import UtahNewsData

/// A mock LLM manager for testing
final class MockLLMManager: LocalLLMManager, @unchecked Sendable {
    override func extractContent(from html: String, contentType: String) async throws -> String {
        switch contentType {
        case "title":
            return "Mock Title"
        case "main content":
            return "Mock Content"
        case "author":
            return "Mock Author"
        case "publication date":
            return "2024-03-21T10:00:00Z"
        case "category":
            return "Mock Category"
        default:
            return "Mock Content"
        }
    }
}

final class HTMLParsingTests: XCTestCase {
    
    // MARK: - Test Data
    
    let sampleHTML = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Test Article</title>
        <meta property="og:title" content="Social Media Title">
        <meta property="og:image" content="https://example.com/image.jpg">
        <meta property="article:published_time" content="2024-03-21T10:00:00Z">
        <meta property="article:section" content="Technology">
        <meta property="og:url" content="https://example.com/article">
        <meta property="og:site_name" content="Test Organization">
        <meta name="description" content="Organization description">
        <meta property="place:location:latitude" content="40.7608">
        <meta property="place:location:longitude" content="-111.8910">
        <meta name="jurisdiction-type" content="city">
    </head>
    <body>
        <article>
            <h1 class="article-title">Test Article Headline</h1>
            <div class="author">John Doe</div>
            <div class="article-content">
                <p>This is the first paragraph of the article.</p>
                <p>This is the second paragraph with some <b>bold text</b>.</p>
                <img src="https://example.com/image2.jpg" alt="Additional Image">
            </div>
        </article>
        
        <div class="organization" itemscope itemtype="http://schema.org/Organization">
            <h2 itemprop="name">Test Organization</h2>
            <p itemprop="description">A test organization description</p>
            <a itemprop="url" href="https://example.com">Website</a>
            <img itemprop="logo" src="https://example.com/logo.jpg" alt="Logo">
            <div itemprop="location">
                <div itemprop="address">
                    <span itemprop="streetAddress">123 Main St</span>
                    <span itemprop="addressLocality">Salt Lake City</span>
                    <span itemprop="addressRegion">UT</span>
                    <span itemprop="postalCode">84111</span>
                </div>
            </div>
        </div>
        
        <div class="poll" itemscope itemtype="http://schema.org/Question">
            <h3 itemprop="question">What is your favorite color?</h3>
            <div class="poll-options">
                <div itemprop="option" data-votes="10">Red</div>
                <div itemprop="option" data-votes="15">Blue</div>
                <div itemprop="option" data-votes="8">Green</div>
            </div>
            <div itemprop="sourceOrganization">Test Polling Inc.</div>
            <div itemprop="datePublished">2024-03-21T10:00:00Z</div>
            <div class="margin-of-error">3.5%</div>
            <div class="sample-size">1000</div>
            <div class="demographics">Adults 18+</div>
        </div>
        
        <div class="location" itemscope itemtype="http://schema.org/Place">
            <div itemprop="address">
                <span itemprop="streetAddress">123 Main St</span>
                <span itemprop="addressLocality">Salt Lake City</span>
                <span itemprop="addressRegion">UT</span>
                <span itemprop="postalCode">84111</span>
                <span itemprop="addressCountry">United States</span>
            </div>
            <div itemprop="geo">
                <meta itemprop="latitude" content="40.7608" />
                <meta itemprop="longitude" content="-111.8910" />
            </div>
        </div>
        
        <div class="jurisdiction" itemscope>
            <h2 itemprop="name">Salt Lake City</h2>
            <div itemprop="jurisdictionType">City</div>
            <a itemprop="url" href="https://www.slc.gov">Website</a>
            <div itemprop="location">
                <div itemprop="address">
                    <span itemprop="streetAddress">451 S State St</span>
                    <span itemprop="addressLocality">Salt Lake City</span>
                    <span itemprop="addressRegion">UT</span>
                    <span itemprop="postalCode">84111</span>
                </div>
            </div>
        </div>
        
        <div class="source" itemscope itemtype="http://schema.org/Organization">
            <h2 itemprop="name">Test News Network</h2>
            <p itemprop="description">A trusted news source</p>
            <a itemprop="url" href="https://example.com/news">Website</a>
            <div itemprop="category">News</div>
            <meta itemprop="inLanguage" content="en-US">
        </div>
        
        <div class="alert" itemscope itemtype="http://schema.org/NewsArticle">
            <h2 itemprop="headline">Breaking: Important News Alert</h2>
            <div itemprop="articleBody">This is an important news alert content.</div>
            <div itemprop="alertType">Breaking News</div>
            <div itemprop="severity">High</div>
            <div itemprop="datePublished">2024-03-21T10:00:00Z</div>
            <div itemprop="publisher">Test News Network</div>
        </div>
    </body>
    </html>
    """
    
    // MARK: - Selector Discovery Tests
    
    func testSelectorDiscovery() throws {
        let document = try SwiftSoup.parse(sampleHTML)
        
        // Test title selectors
        let titleSelectors = try SelectorDiscovery.discoverSelectors(in: document, for: .title)
        XCTAssertFalse(titleSelectors.isEmpty, "Should find title selectors")
        XCTAssertTrue(titleSelectors.contains { $0.selector == "h1.article-title" })
        
        // Test content selectors
        let contentSelectors = try SelectorDiscovery.discoverSelectors(in: document, for: .mainContent)
        XCTAssertFalse(contentSelectors.isEmpty, "Should find content selectors")
        XCTAssertTrue(contentSelectors.contains { $0.selector == ".article-content" })
        
        // Test author selectors
        let authorSelectors = try SelectorDiscovery.discoverSelectors(in: document, for: .author)
        XCTAssertFalse(authorSelectors.isEmpty, "Should find author selectors")
        XCTAssertTrue(authorSelectors.contains { $0.selector == ".author" })
    }
    
    // MARK: - Content Validation Tests
    
    func testContentValidation() {
        // Test title validation
        let titleResult = ContentValidator.validate("Test Article Headline", type: .title)
        XCTAssertTrue(titleResult.isValid, "Title should be valid")
        XCTAssertGreaterThan(titleResult.score, 0.5)
        
        // Test content validation
        let contentResult = ContentValidator.validate(
            "This is the first paragraph of the article. This is the second paragraph with some bold text.",
            type: .mainContent
        )
        XCTAssertTrue(contentResult.isValid, "Content should be valid")
        
        // Test author validation
        let authorResult = ContentValidator.validate("John Doe", type: .author)
        XCTAssertTrue(authorResult.isValid, "Author should be valid")
        
        // Test date validation
        let dateResult = ContentValidator.validate("2024-03-21T10:00:00Z", type: .date)
        XCTAssertTrue(dateResult.isValid, "Date should be valid")
    }
    
    // MARK: - Test Cases
    
    func testArticleParsing() throws {
        let document = try SwiftSoup.parse(sampleHTML)
        let article = try Article.parse(from: document)
        
        XCTAssertEqual(article.title, "Test Article Headline")
        XCTAssertEqual(article.author, "John Doe")
        XCTAssertEqual(article.category, "Technology")
        XCTAssertEqual(article.urlToImage, "https://example.com/image.jpg")
        XCTAssertNotNil(article.textContent)
        XCTAssertTrue(article.textContent?.contains("first paragraph") ?? false)
        XCTAssertNotNil(article.additionalImages)
        XCTAssertEqual(article.additionalImages?.count, 1)
        XCTAssertEqual(article.additionalImages?.first, "https://example.com/image2.jpg")
    }
    
    func testAdaptiveParser() async throws {
        let parser = await AdaptiveParser(llmManager: MockLLMManager())
        let url = URL(string: "https://example.com/article")!
        
        let result = try await parser.parseWithFallback(html: sampleHTML, from: url, as: Article.self)
        
        switch result {
        case .success(let article, source: let source):
            XCTAssertEqual(source, .htmlParsing)
            XCTAssertEqual(article.title, "Test Article Headline")
            XCTAssertEqual(article.author, "John Doe")
            XCTAssertEqual(article.category, "Technology")
            XCTAssertEqual(article.urlToImage, "https://example.com/image.jpg")
            XCTAssertNotNil(article.textContent)
            XCTAssertTrue(article.textContent?.contains("first paragraph") ?? false)
            XCTAssertNotNil(article.additionalImages)
            XCTAssertEqual(article.additionalImages?.count, 1)
            XCTAssertEqual(article.additionalImages?.first, "https://example.com/image2.jpg")
            
        case .failure(let error):
            XCTFail("Parsing should succeed: \(error)")
        }
    }
    
    func testLLMFallback() async throws {
        let parser = await AdaptiveParser(llmManager: await MockLLMManager())
        let url = URL(string: "https://example.com/article")!
        let invalidHTML = "<invalid>HTML"
        
        let result = try await parser.parseWithFallback(html: invalidHTML, from: url, as: Article.self)
        
        switch result {
        case .success(let article, source: let source):
            XCTAssertEqual(source, .llmExtraction)
            XCTAssertEqual(article.title, "Mock Title")
            XCTAssertEqual(article.textContent, "Mock Content")
            XCTAssertEqual(article.author, "Mock Author")
            XCTAssertEqual(article.category, "Mock Category")
            
        case .failure(let error):
            XCTFail("LLM fallback should succeed: \(error)")
        }
    }
    
    func testOrganizationParsing() throws {
        let document = try SwiftSoup.parse(sampleHTML)
        let organization = try Organization.parse(from: document)
        
        XCTAssertEqual(organization.name, "Test Organization")
        XCTAssertEqual(organization.orgDescription, "A test organization description")
        XCTAssertEqual(organization.website, "https://example.com")
        XCTAssertEqual(organization.logoURL, "https://example.com/logo.jpg")
        XCTAssertNotNil(organization.location)
        XCTAssertEqual(organization.location?.city, "Salt Lake City")
        XCTAssertEqual(organization.location?.state, "UT")
        XCTAssertEqual(organization.location?.zipCode, "84111")
    }
    
    func testPollParsing() throws {
        let document = try SwiftSoup.parse(sampleHTML)
        let poll = try Poll.parse(from: document)
        
        XCTAssertEqual(poll.question, "What is your favorite color?")
        XCTAssertEqual(poll.options.count, 3)
        XCTAssertEqual(poll.options[0].text, "Red")
        XCTAssertEqual(poll.options[1].text, "Blue")
        XCTAssertEqual(poll.options[2].text, "Green")
        XCTAssertEqual(poll.source, "Test Polling Inc.")
        XCTAssertEqual(poll.marginOfError, 3.5)
        XCTAssertEqual(poll.sampleSize, 1000)
        XCTAssertEqual(poll.demographics, "Adults 18+")
    }
    
    func testLocationParsing() throws {
        let document = try SwiftSoup.parse(sampleHTML)
        let location = try Location.parse(from: document)
        
        XCTAssertEqual(location.address, "123 Main St, Salt Lake City, UT, 84111")
        XCTAssertEqual(location.city, "Salt Lake City")
        XCTAssertEqual(location.state, "UT")
        XCTAssertEqual(location.zipCode, "84111")
        XCTAssertEqual(location.country, "United States")
        XCTAssertEqual(location.latitude, 40.7608)
        XCTAssertEqual(location.longitude, -111.8910)
    }
    
    func testJurisdictionParsing() throws {
        let document = try SwiftSoup.parse(sampleHTML)
        let jurisdiction = try Jurisdiction.parse(from: document)
        
        XCTAssertEqual(jurisdiction.name, "Salt Lake City")
        XCTAssertEqual(jurisdiction.type, .city)
        XCTAssertEqual(jurisdiction.website, "https://www.slc.gov")
        XCTAssertNotNil(jurisdiction.location)
        XCTAssertEqual(jurisdiction.location?.city, "Salt Lake City")
        XCTAssertEqual(jurisdiction.location?.state, "UT")
        XCTAssertEqual(jurisdiction.location?.zipCode, "84111")
    }
    
    func testSourceParsing() throws {
        let document = try SwiftSoup.parse(sampleHTML)
        let source = try Source.parse(from: document)
        
        XCTAssertEqual(source.name, "Test News Network")
        XCTAssertEqual(source.description, "A trusted news source")
        XCTAssertEqual(source.url, "https://example.com/news")
        XCTAssertEqual(source.category, "News")
        XCTAssertEqual(source.language, "en-US")
    }
    
    func testNewsAlertParsing() throws {
        let document = try SwiftSoup.parse(sampleHTML)
        let alert = try NewsAlert.parse(from: document)
        
        XCTAssertEqual(alert.title, "Breaking: Important News Alert")
        XCTAssertEqual(alert.content, "This is an important news alert content.")
        XCTAssertEqual(alert.alertType, "Breaking News")
        XCTAssertEqual(alert.severity, .high)
        XCTAssertEqual(alert.source, "Test News Network")
        
        // Verify date parsing
        let expectedDate = DateFormatter.iso8601Full.date(from: "2024-03-21T10:00:00Z")
        XCTAssertEqual(alert.publishedAt, expectedDate)
    }
} 