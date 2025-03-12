import XCTest
@testable import UtahNewsData

@MainActor
final class LocalLLMTests: XCTestCase, @unchecked Sendable {
    
    var llmManager: LocalLLMManager!
    
    override func setUp() async throws {
        try await super.setUp()
        let config = StandardLLMConfig(
            baseURL: URL(string: "http://localhost:1234/v1/chat/completions")!,
            simpleTaskModels: ["llama-3.2-3b-instruct"],
            headers: ["Content-Type": "application/json"]
        )
        LLMConfigurationManager.shared.configure(with: config)
        llmManager = LocalLLMManager()
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
    
    func testParallelModelLoading() async throws {
        // Configure with single model name - server will handle parallel instances
        let config = StandardLLMConfig(
            baseURL: URL(string: "http://localhost:1234/v1/chat/completions")!,
            simpleTaskModels: ["llama-3.2-3b-instruct"],
            headers: ["Content-Type": "application/json"]
        )
        
        LLMConfigurationManager.shared.configure(with: config)
        print("Configured LLM with model: \(config.simpleTaskModels[0])")
        
        // Create multiple requests to test parallel processing
        let html = """
        <html>
            <head><title>Test Article</title></head>
            <body>
                <h1>Main Headline</h1>
                <div class="content">Test content</div>
            </body>
        </html>
        """
        
        print("Starting parallel requests...")
        
        // Make multiple concurrent requests with individual error handling
        async let title1 = Task {
            do {
                let result = try await llmManager.extractContent(from: html, contentType: "title")
                print("Request 1 completed successfully")
                return result
            } catch {
                print("Request 1 failed: \(error)")
                throw error
            }
        }.value
        
        async let title2 = Task {
            do {
                let result = try await llmManager.extractContent(from: html, contentType: "title")
                print("Request 2 completed successfully")
                return result
            } catch {
                print("Request 2 failed: \(error)")
                throw error
            }
        }.value
        
        async let title3 = Task {
            do {
                let result = try await llmManager.extractContent(from: html, contentType: "title")
                print("Request 3 completed successfully")
                return result
            } catch {
                print("Request 3 failed: \(error)")
                throw error
            }
        }.value
        
        do {
            let results = try await [title1, title2, title3]
            print("All requests completed successfully")
            
            // Verify all requests completed successfully
            for (index, result) in results.enumerated() {
                XCTAssertFalse(result.isEmpty, "Result \(index + 1) is empty")
                XCTAssertTrue(result.contains("Main Headline"), "Result \(index + 1) does not contain expected content")
            }
        } catch {
            XCTFail("Parallel requests failed: \(error)")
        }
    }
    
    func testParallelComplexContentExtraction() async throws {
        // Configure with single model name for complex tasks
        let config = StandardLLMConfig(
            baseURL: URL(string: "http://localhost:1234/v1/chat/completions")!,
            complexTaskModels: ["mistral-nemo-instruct-2407"],
            headers: ["Content-Type": "application/json"]
        )
        
        LLMConfigurationManager.shared.configure(with: config)
        print("Configured LLM with complex model: \(config.complexTaskModels[0])")
        
        // Create three different articles to test parallel processing
        let article1 = """
        <html><body>
            <article>
                <h1>First Article</h1>
                <div class="content">
                    <p>This is the main content of the first article.</p>
                    <p>It contains multiple paragraphs with important information.</p>
                    <p>The content is unique to this article.</p>
                </div>
            </article>
        </body></html>
        """
        
        let article2 = """
        <html><body>
            <article>
                <h1>Second Article</h1>
                <div class="content">
                    <p>The second article has different content.</p>
                    <p>This ensures we're getting unique responses.</p>
                    <p>Each article should be processed independently.</p>
                </div>
            </article>
        </body></html>
        """
        
        let article3 = """
        <html><body>
            <article>
                <h1>Third Article</h1>
                <div class="content">
                    <p>Finally, the third article has its own content.</p>
                    <p>This helps verify parallel processing.</p>
                    <p>The content should be extracted correctly.</p>
                </div>
            </article>
        </body></html>
        """
        
        print("Starting parallel complex content extraction...")
        
        // Make multiple concurrent requests for content extraction
        async let content1 = Task {
            do {
                let result = try await llmManager.extractContent(from: article1, contentType: "main content")
                print("Complex request 1 completed successfully")
                return result
            } catch {
                print("Complex request 1 failed: \(error)")
                throw error
            }
        }.value
        
        async let content2 = Task {
            do {
                let result = try await llmManager.extractContent(from: article2, contentType: "main content")
                print("Complex request 2 completed successfully")
                return result
            } catch {
                print("Complex request 2 failed: \(error)")
                throw error
            }
        }.value
        
        async let content3 = Task {
            do {
                let result = try await llmManager.extractContent(from: article3, contentType: "main content")
                print("Complex request 3 completed successfully")
                return result
            } catch {
                print("Complex request 3 failed: \(error)")
                throw error
            }
        }.value
        
        do {
            let results = try await [content1, content2, content3]
            print("All complex requests completed successfully")
            
            // Verify each result contains its unique content
            XCTAssertTrue(results[0].contains("first article"), "First result should contain content from first article")
            XCTAssertTrue(results[1].contains("second article"), "Second result should contain content from second article")
            XCTAssertTrue(results[2].contains("third article"), "Third result should contain content from third article")
            
            // Verify results don't contain content from other articles
            XCTAssertFalse(results[0].contains("second article"), "First result should not contain content from second article")
            XCTAssertFalse(results[1].contains("third article"), "Second result should not contain content from third article")
            XCTAssertFalse(results[2].contains("first article"), "Third result should not contain content from first article")
            
            // Print results for inspection
            print("\nExtracted contents:")
            for (index, result) in results.enumerated() {
                print("\nArticle \(index + 1):")
                print(result)
            }
        } catch {
            XCTFail("Parallel complex requests failed: \(error)")
        }
    }
    
    func testParallelRealWorldProcessing() async throws {
        // Configure with both simple and complex models
        let config = StandardLLMConfig(
            baseURL: URL(string: "http://localhost:1234/v1/chat/completions")!,
            simpleTaskModels: ["llama-3.2-3b-instruct"],
            complexTaskModels: ["mistral-nemo-instruct-2407"],
            headers: ["Content-Type": "application/json"]
        )
        
        LLMConfigurationManager.shared.configure(with: config)
        print("Configured LLM with models - Simple: \(config.simpleTaskModels[0]), Complex: \(config.complexTaskModels[0])")
        
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
        
        let networkClient = NetworkClient()
        print("\nStarting parallel processing of \(urls.count) URLs...")
        
        var results: [(String, [String])] = []
        
        try await withThrowingTaskGroup(of: (String, [String]).self) { group in
            for (index, urlString) in urls.enumerated() {
                group.addTask {
                    guard let url = URL(string: urlString) else {
                        throw URLError(.badURL)
                    }
                    
                    let html = try await networkClient.fetchHTML(from: url)
                    print("\nProcessing URL \(index + 1): \(url.lastPathComponent)")
                    
                    // For even indices, use simple tasks (title, author)
                    // For odd indices, use complex tasks (main content, category)
                    if index % 2 == 0 {
                        async let title = self.llmManager.extractContent(from: html, contentType: "title")
                        async let author = self.llmManager.extractContent(from: html, contentType: "author")
                        let taskResults = try await [title, author]
                        print("Simple task results for \(url.lastPathComponent):")
                        print("Title: \(taskResults[0])")
                        print("Author: \(taskResults[1])")
                        return (url.lastPathComponent, taskResults)
                    } else {
                        async let content = self.llmManager.extractContent(from: html, contentType: "main content")
                        async let category = self.llmManager.extractContent(from: html, contentType: "category")
                        let taskResults = try await [content, category]
                        print("Complex task results for \(url.lastPathComponent):")
                        print("Content length: \(taskResults[0].count) characters")
                        print("Category: \(taskResults[1])")
                        return (url.lastPathComponent, taskResults)
                    }
                }
            }
            
            // Collect all results
            for try await result in group {
                results.append(result)
            }
        }
        
        print("\nAll parallel tasks completed successfully")
        print("Processed \(results.count) URLs")
        
        // Verify results
        for (urlPath, content) in results {
            XCTAssertFalse(content.isEmpty, "Content should not be empty for \(urlPath)")
            for item in content {
                XCTAssertFalse(item.isEmpty, "Individual content items should not be empty for \(urlPath)")
            }
        }
    }
} 