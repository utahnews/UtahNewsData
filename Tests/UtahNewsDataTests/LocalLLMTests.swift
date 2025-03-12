import XCTest
@testable import UtahNewsData

@MainActor
final class LocalLLMTests: XCTestCase, @unchecked Sendable {
    
    var llmManager: LocalLLMManager!
    
    override func setUp() async throws {
        try await super.setUp()
        llmManager = LocalLLMManager(endpoint: "http://localhost:1234/v1/chat/completions")
    }
    
    override func tearDown() async throws {
        llmManager = nil
        try await super.tearDown()
    }
    
    func testTitleExtraction() async throws {
        let html = """
        <html>
            <head>
                <title>Website Title</title>
                <meta property="og:title" content="OpenGraph Title">
            </head>
            <body>
                <h1 class="article-headline">Main Article Headline</h1>
                <div class="content">
                    <p>Article content goes here.</p>
                </div>
            </body>
        </html>
        """
        
        let title = try await llmManager.extractContent(from: html, contentType: "title")
        XCTAssertFalse(title.isEmpty)
        XCTAssertTrue(title.contains("Main Article Headline") || title.contains("OpenGraph Title") || title.contains("Website Title"))
    }
    
    func testContentExtraction() async throws {
        let html = """
        <html>
            <body>
                <h1>Test Article</h1>
                <div class="article-content">
                    <p>This is the main content of the article.</p>
                    <p>It contains multiple paragraphs with important information.</p>
                </div>
                <div class="sidebar">
                    <p>This is sidebar content that should be ignored.</p>
                </div>
            </body>
        </html>
        """
        
        let content = try await llmManager.extractContent(from: html, contentType: "main content")
        XCTAssertFalse(content.isEmpty)
        XCTAssertTrue(content.contains("main content of the article"))
        XCTAssertTrue(content.contains("important information"))
    }
    
    func testAuthorExtraction() async throws {
        let html = """
        <html>
            <body>
                <article>
                    <h1>Article Title</h1>
                    <div class="author-info">
                        <span class="author-name">John Smith</span>
                        <span class="author-title">Senior Reporter</span>
                    </div>
                    <div class="content">Article content here.</div>
                </article>
            </body>
        </html>
        """
        
        let author = try await llmManager.extractContent(from: html, contentType: "author")
        XCTAssertFalse(author.isEmpty)
        XCTAssertTrue(author.contains("John Smith"))
    }
    
    func testDateExtraction() async throws {
        let html = """
        <html>
            <head>
                <meta property="article:published_time" content="2024-03-21T10:00:00Z">
            </head>
            <body>
                <article>
                    <time class="published-date">March 21, 2024</time>
                    <div class="content">Article content here.</div>
                </article>
            </body>
        </html>
        """
        
        let date = try await llmManager.extractContent(from: html, contentType: "publication date")
        XCTAssertFalse(date.isEmpty)
        XCTAssertTrue(date.contains("2024"))
        XCTAssertTrue(date.contains("March") || date.contains("03") || date.contains("21"))
    }
    
    func testCategoryExtraction() async throws {
        let html = """
        <html>
            <body>
                <article>
                    <div class="category-tags">
                        <span class="category">Technology</span>
                        <span class="tag">AI</span>
                        <span class="tag">Machine Learning</span>
                    </div>
                    <div class="content">Article content here.</div>
                </article>
            </body>
        </html>
        """
        
        let category = try await llmManager.extractContent(from: html, contentType: "category")
        XCTAssertFalse(category.isEmpty)
        XCTAssertTrue(category.contains("Technology"))
    }
    
    func testMultipleFieldExtraction() async throws {
        let html = """
        <html>
            <head>
                <title>Complex Article</title>
                <meta property="article:published_time" content="2024-03-21T10:00:00Z">
            </head>
            <body>
                <article>
                    <h1>Main Headline</h1>
                    <div class="author-info">By Jane Doe</div>
                    <div class="category">Science</div>
                    <div class="content">
                        <p>First paragraph of content.</p>
                        <p>Second paragraph with more details.</p>
                    </div>
                </article>
            </body>
        </html>
        """
        
        async let title = llmManager.extractContent(from: html, contentType: "title")
        async let content = llmManager.extractContent(from: html, contentType: "main content")
        async let author = llmManager.extractContent(from: html, contentType: "author")
        async let category = llmManager.extractContent(from: html, contentType: "category")
        
        let results = try await [title, content, author, category]
        
        print("Extracted title: \(results[0])")
        print("Extracted content: \(results[1])")
        print("Extracted author: \(results[2])")
        print("Extracted category: \(results[3])")
        
        XCTAssertTrue(results[0].contains("Main Headline"), "Expected title to contain 'Main Headline', but got: \(results[0])")
        XCTAssertTrue(results[1].contains("paragraph"), "Expected content to contain 'paragraph', but got: \(results[1])")
        XCTAssertTrue(results[2].contains("Jane Doe"), "Expected author to contain 'Jane Doe', but got: \(results[2])")
        XCTAssertTrue(results[3].contains("Science"), "Expected category to contain 'Science', but got: \(results[3])")
    }
} 