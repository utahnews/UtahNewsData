//
//  HTMLParsingTests.swift
//  UtahNewsDataTests
//
//  Created by Mark Evans on 01/29/25
//
//  Summary: Comprehensive tests for HTML parsing functionality using SwiftSoup.
//           Tests all HTMLParsable conforming types and error handling.

import Foundation
import Testing
import SwiftSoup
@testable import UtahNewsData
@testable import UtahNewsDataModels

@Suite("HTML Parsing Tests")
struct HTMLParsingTests {
    
    // MARK: - Basic HTML Parsing Tests
    
    @Test("Article HTML parsing")
    func testArticleHTMLParsing() throws {
        let htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Test Article Title</title>
            <meta property="og:url" content="https://example.com/test-article" />
            <meta property="og:image" content="https://example.com/image.jpg" />
            <meta name="author" content="John Doe" />
            <meta name="description" content="This is a test article description." />
        </head>
        <body>
            <h1>Test Article Title</h1>
            <div class="article-content">
                <p>This is the main content of the test article.</p>
                <p>It contains multiple paragraphs for testing.</p>
            </div>
            <time datetime="2024-01-15T10:30:00Z">January 15, 2024</time>
            <div class="category">News</div>
        </body>
        </html>
        """
        
        let article = try Article.parse(from: htmlContent)
        
        // Verify parsed content
        #expect(!article.id.isEmpty)
        #expect(!article.title.isEmpty)
        #expect(article.title.contains("Test Article"))
        #expect(article.textContent != nil)
        #expect(article.textContent!.contains("main content"))
        
        // Verify the article conforms to our protocols
        TestUtilities.validateBaseEntity(article)
        TestUtilities.validateNewsContent(article)
        try TestUtilities.validateCodableConformance(article)
    }
    
    @Test("Video HTML parsing")
    func testVideoHTMLParsing() throws {
        let htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Test Video Title</title>
            <meta property="og:url" content="https://example.com/test-video" />
            <meta property="og:image" content="https://example.com/video-thumb.jpg" />
            <meta property="og:video:duration" content="300" />
        </head>
        <body>
            <h1>Test Video Title</h1>
            <video src="https://example.com/video.mp4" duration="300">
                <p>Video description content goes here.</p>
            </video>
            <div class="author">Jane Smith</div>
            <div class="category">Video News</div>
        </body>
        </html>
        """
        
        let video = try Video.parse(from: htmlContent)
        
        #expect(!video.id.isEmpty)
        #expect(!video.title.isEmpty)
        #expect(video.title.contains("Test Video"))
        
        TestUtilities.validateBaseEntity(video)
        TestUtilities.validateNewsContent(video)
        try TestUtilities.validateCodableConformance(video)
    }
    
    @Test("Audio HTML parsing")
    func testAudioHTMLParsing() throws {
        let htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Test Podcast Episode</title>
            <meta property="og:url" content="https://example.com/test-podcast" />
            <meta property="og:image" content="https://example.com/podcast-thumb.jpg" />
            <meta property="og:audio:duration" content="1800" />
        </head>
        <body>
            <h1>Test Podcast Episode</h1>
            <audio src="https://example.com/podcast.mp3" duration="1800">
                <p>Podcast episode description.</p>
            </audio>
            <div class="host">Mike Johnson</div>
            <div class="category">Podcast</div>
        </body>
        </html>
        """
        
        let audio = try Audio.parse(from: htmlContent)
        
        #expect(!audio.id.isEmpty)
        #expect(!audio.title.isEmpty)
        #expect(audio.title.contains("Test Podcast"))
        
        TestUtilities.validateBaseEntity(audio)
        TestUtilities.validateNewsContent(audio)
        try TestUtilities.validateCodableConformance(audio)
    }
    
    // MARK: - Complex HTML Structure Tests
    
    @Test("Nested HTML structure parsing")
    func testNestedHTMLStructure() throws {
        let complexHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Complex Article Structure</title>
            <meta property="og:url" content="https://example.com/complex-article" />
            <meta property="og:image" content="https://example.com/complex-image.jpg" />
        </head>
        <body>
            <article>
                <header>
                    <h1>Complex Article Structure</h1>
                    <div class="meta">
                        <span class="author">Complex Author</span>
                        <time datetime="2024-01-20T15:45:00Z">January 20, 2024</time>
                    </div>
                </header>
                <div class="article-content">
                    <p>First paragraph of content.</p>
                    <div class="quote-block">
                        <blockquote>"This is a quoted section."</blockquote>
                        <cite>Quote Source</cite>
                    </div>
                    <p>Second paragraph with <a href="https://example.com">a link</a>.</p>
                    <ul>
                        <li>List item one</li>
                        <li>List item two</li>
                    </ul>
                </div>
                <aside class="sidebar">
                    <h3>Related Information</h3>
                    <p>Additional context information.</p>
                </aside>
            </article>
        </body>
        </html>
        """
        
        let article = try Article.parse(from: complexHTML)
        
        #expect(article.title == "Complex Article Structure")
        #expect(article.textContent != nil)
        #expect(article.textContent!.contains("First paragraph"))
        #expect(article.textContent!.contains("Second paragraph"))
        
        try TestUtilities.validateCodableConformance(article)
    }
    
    @Test("HTML with special characters and entities")
    func testHTMLWithSpecialCharacters() throws {
        let htmlWithEntities = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Article with &quot;Special&quot; Characters &amp; Entities</title>
            <meta property="og:url" content="https://example.com/special-chars" />
        </head>
        <body>
            <h1>Article with &quot;Special&quot; Characters &amp; Entities</h1>
            <div class="article-content">
                <p>Content with &lt;encoded&gt; HTML entities and émojis 🎉.</p>
                <p>Unicode characters: 世界, مرحبا, Здравствуй</p>
                <p>Mathematical symbols: ∑, ∞, π, ≠, ≤, ≥</p>
            </div>
        </body>
        </html>
        """
        
        let article = try Article.parse(from: htmlWithEntities)
        
        #expect(article.title.contains("Special"))
        #expect(article.title.contains("Characters"))
        #expect(article.title.contains("&"))
        #expect(article.textContent != nil)
        #expect(article.textContent!.contains("encoded"))
        #expect(article.textContent!.contains("🎉"))
        #expect(article.textContent!.contains("世界"))
        
        try TestUtilities.validateCodableConformance(article)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Invalid HTML handling")
    func testInvalidHTMLHandling() throws {
        let invalidHTML = "<html><body><h1>Broken HTML without closing tags"
        
        #expect(throws: ParsingError.self) {
            try Article.parse(from: invalidHTML)
        }
    }
    
    @Test("Empty HTML handling")
    func testEmptyHTMLHandling() throws {
        let emptyHTML = ""
        
        #expect(throws: ParsingError.self) {
            try Article.parse(from: emptyHTML)
        }
    }
    
    @Test("HTML without required elements")
    func testHTMLWithoutRequiredElements() throws {
        let incompleteHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <!-- No title -->
        </head>
        <body>
            <!-- No content -->
        </body>
        </html>
        """
        
        #expect(throws: ParsingError.self) {
            try Article.parse(from: incompleteHTML)
        }
    }
    
    @Test("Malformed HTML structure")
    func testMalformedHTMLStructure() throws {
        let malformedHTML = """
        <html>
        <head>
        <title>Test</title>
        <body>
        <p>Missing proper structure
        </html>
        """
        
        // SwiftSoup is forgiving, but we should still handle it gracefully
        do {
            let article = try Article.parse(from: malformedHTML)
            #expect(article.title == "Test")
        } catch {
            // It's acceptable to throw an error for malformed HTML
            #expect(error is ParsingError)
        }
    }
    
    // MARK: - HTMLParsable Protocol Tests
    
    @Test("HTMLParsable default implementations")
    func testHTMLParsableDefaults() throws {
        let testHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Protocol Test</title>
        </head>
        <body>
            <h1 class="main-title">Protocol Test Title</h1>
            <p class="content">Test content paragraph.</p>
            <a href="https://example.com" class="test-link">Test Link</a>
            <img src="https://example.com/image.jpg" alt="Test Image" class="test-image">
        </body>
        </html>
        """
        
        let document = try SwiftSoup.parse(testHTML)
        
        // Test extractText method
        let titleText = try Article.extractText(from: document, selector: "h1.main-title")
        #expect(titleText == "Protocol Test Title")
        
        let contentText = try Article.extractText(from: document, selector: "p.content")
        #expect(contentText == "Test content paragraph.")
        
        // Test extractAttribute method
        let linkHref = try Article.extractAttribute(from: document, selector: "a.test-link", attribute: "href")
        #expect(linkHref == "https://example.com")
        
        let imageSrc = try Article.extractAttribute(from: document, selector: "img.test-image", attribute: "src")
        #expect(imageSrc == "https://example.com/image.jpg")
        
        let imageAlt = try Article.extractAttribute(from: document, selector: "img.test-image", attribute: "alt")
        #expect(imageAlt == "Test Image")
    }
    
    @Test("HTMLParsable validation methods")
    func testHTMLParsableValidation() throws {
        // Test validateRequiredField
        #expect(throws: ParsingError.self) {
            try Article.validateRequiredField(nil, fieldName: "title")
        }
        
        #expect(throws: ParsingError.self) {
            try Article.validateRequiredField("", fieldName: "title")
        }
        
        // Should not throw for valid field
        try Article.validateRequiredField("Valid Title", fieldName: "title")
        
        // Test validateOptionalField
        let nilResult = Article.validateOptionalField(nil)
        #expect(nilResult == nil)
        
        let emptyResult = Article.validateOptionalField("")
        #expect(emptyResult == nil)
        
        let validResult = Article.validateOptionalField("Valid Content")
        #expect(validResult == "Valid Content")
    }
    
    // MARK: - Real-World HTML Tests
    
    @Test("News article HTML structure")
    func testNewsArticleHTMLStructure() throws {
        let newsHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Utah News: Major Development in Salt Lake City</title>
            <meta name="description" content="A comprehensive report on recent developments in Salt Lake City.">
            <meta name="author" content="Sarah Johnson">
            <meta property="og:title" content="Utah News: Major Development in Salt Lake City">
            <meta property="og:description" content="A comprehensive report on recent developments in Salt Lake City.">
            <meta property="og:image" content="https://example.com/utah-news-image.jpg">
            <meta property="og:url" content="https://utahnews.example.com/article/major-development">
            <meta name="twitter:card" content="summary_large_image">
            <meta name="publish-date" content="2024-01-25T09:00:00-07:00">
        </head>
        <body>
            <article>
                <header>
                    <h1>Utah News: Major Development in Salt Lake City</h1>
                    <div class="article-meta">
                        <span class="author">Sarah Johnson</span>
                        <time datetime="2024-01-25T09:00:00-07:00">January 25, 2024</time>
                        <span class="category">Local News</span>
                    </div>
                </header>

                <div class="article-content">
                    <p class="lead">Salt Lake City officials announced a major development project that will transform the downtown area over the next five years.</p>
                    
                    <p>The project, valued at $2.5 billion, includes residential, commercial, and public spaces designed to accommodate the city's growing population.</p>
                    
                    <h2>Project Details</h2>
                    <p>The development will include:</p>
                    <ul>
                        <li>500 new residential units</li>
                        <li>100,000 square feet of commercial space</li>
                        <li>A new public park</li>
                        <li>Improved public transportation access</li>
                    </ul>
                    
                    <blockquote>
                        <p>"This project represents the future of Salt Lake City," said Mayor Jane Smith.</p>
                        <cite>Mayor Jane Smith</cite>
                    </blockquote>
                    
                    <h2>Community Impact</h2>
                    <p>Local residents have expressed mixed reactions to the proposed development, with some praising the economic benefits while others raise concerns about gentrification.</p>
                </div>
                
                <footer class="article-footer">
                    <div class="tags">
                        <span class="tag">Salt Lake City</span>
                        <span class="tag">Development</span>
                        <span class="tag">Urban Planning</span>
                    </div>
                </footer>
            </article>
        </body>
        </html>
        """
        
        let article = try Article.parse(from: newsHTML)
        
        #expect(article.title.contains("Utah News"))
        #expect(article.title.contains("Salt Lake City"))
        #expect(article.author == "Sarah Johnson")
        #expect(article.category == "Local News")
        #expect(article.textContent != nil)
        #expect(article.textContent!.contains("$2.5 billion"))
        #expect(article.textContent!.contains("Mayor Jane Smith"))
        
        TestUtilities.validateNewsContent(article)
        try TestUtilities.validateCodableConformance(article)
    }
    
    @Test("Video content HTML parsing")
    func testVideoContentHTMLParsing() throws {
        let videoHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Utah Weather Report - January 2024</title>
            <meta property="og:url" content="https://example.com/weather-report" />
            <meta property="og:type" content="video">
            <meta property="og:description" content="Chief Meteorologist Mike Davis provides the latest weather forecast for Utah, including expected snowfall in the mountains and temperature trends for the Salt Lake Valley.">
            <meta property="og:video:url" content="https://example.com/weather-report.mp4">
            <meta property="og:video:duration" content="180">
            <meta property="og:image" content="https://example.com/weather-thumb.jpg">
            <meta name="author" content="Mike Davis">
        </head>
        <body>
            <article>
                <h1>Utah Weather Report - January 2024</h1>
                <div class="video-container">
                    <video controls width="800" height="450" duration="180">
                        <source src="https://example.com/weather-report.mp4" type="video/mp4">
                        <p>Your browser doesn't support HTML5 video. Here's a description of the weather report content.</p>
                    </video>
                </div>
                <div class="metadata">
                    <span class="category">Weather</span>
                    <time datetime="2024-01-26T18:00:00-07:00">January 26, 2024</time>
                </div>
            </article>
        </body>
        </html>
        """

        let video = try Video.parse(from: videoHTML)

        #expect(video.title.contains("Utah Weather Report"))
        #expect(video.author == "Mike Davis")
        #expect(video.textContent != nil)
        #expect(video.textContent!.contains("Chief Meteorologist"))
        
        TestUtilities.validateNewsContent(video)
        try TestUtilities.validateCodableConformance(video)
    }
    
    // MARK: - Performance Tests
    
    @Test("Large HTML document parsing performance")
    func testLargeHTMLParsingPerformance() throws {
        // Generate a large HTML document
        var largeHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Large Document Test</title>
            <meta property="og:url" content="https://example.com/large-document" />
        </head>
        <body>
            <h1>Large Document Test</h1>
            <div class="article-content">
        """

        // Add many paragraphs
        for i in 0..<1000 {
            largeHTML += "<p>This is paragraph number \(i) with some content for testing parsing performance. "
            largeHTML += "It contains enough text to make the document substantial for performance testing.</p>\n"
        }

        largeHTML += """
            </div>
        </body>
        </html>
        """
        
        let startTime = Date()
        let article = try Article.parse(from: largeHTML)
        let parsingTime = Date().timeIntervalSince(startTime)
        
        #expect(parsingTime < 2.0, "Large document parsing should complete within 2 seconds")
        #expect(article.title == "Large Document Test")
        #expect(article.textContent != nil)
        #expect(article.textContent!.contains("paragraph number 999"))
        
        try TestUtilities.validateCodableConformance(article)
    }
    
    // MARK: - Edge Cases
    
    @Test("HTML with no text content")
    func testHTMLWithNoTextContent() throws {
        let noContentHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>No Content Test</title>
            <meta property="og:url" content="https://example.com/no-content" />
        </head>
        <body>
            <h1>No Content Test</h1>
            <!-- Only comments and empty elements -->
            <div></div>
            <p></p>
            <span></span>
        </body>
        </html>
        """
        
        let article = try Article.parse(from: noContentHTML)
        
        #expect(article.title == "No Content Test")
        // textContent might be nil or empty, both are acceptable
        if let content = article.textContent {
            #expect(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || content.contains("No Content Test"))
        }
        
        try TestUtilities.validateCodableConformance(article)
    }
    
    @Test("HTML with only whitespace content")
    func testHTMLWithWhitespaceContent() throws {
        let whitespaceHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Whitespace Test</title>
            <meta property="og:url" content="https://example.com/whitespace-test" />
        </head>
        <body>
            <h1>Whitespace Test</h1>
            <p>   </p>
            <p>\n\t\r</p>
            <div>
            
            
            </div>
        </body>
        </html>
        """
        
        let article = try Article.parse(from: whitespaceHTML)
        
        #expect(article.title == "Whitespace Test")
        
        // The parser should handle whitespace appropriately
        if let content = article.textContent {
            let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
            // Content should either be empty or contain the title
            #expect(trimmedContent.isEmpty || trimmedContent.contains("Whitespace Test"))
        }
        
        try TestUtilities.validateCodableConformance(article)
    }
}