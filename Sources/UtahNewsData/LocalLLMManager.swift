import Foundation
import SwiftSoup

/// A manager class for handling interactions with a local LLM
@MainActor
public class LocalLLMManager: @unchecked Sendable {
    /// The shared instance of the LLM manager
    public static let shared = LocalLLMManager()
    
    /// The configuration manager
    private let configManager: LLMConfigurationManager
    
    /// Initialize with configuration manager
    public init(configManager: LLMConfigurationManager = .shared) {
        self.configManager = configManager
    }
    
    /// Process multiple URLs in parallel, extracting specified content from each
    /// - Parameters:
    ///   - requests: Array of (URL, content type) pairs to process
    /// - Returns: Array of extracted content in the same order as the requests
    public func extractContentBatch(requests: [(html: String, contentType: String)]) async throws -> [String] {
        // Create an array of async tasks, one for each request
        let tasks = requests.map { request in
            Task {
                try await extractContent(from: request.html, contentType: request.contentType)
            }
        }
        
        // Wait for all tasks to complete and collect results
        var results: [String] = []
        for task in tasks {
            do {
                let result = try await task.value
                results.append(result)
            } catch {
                results.append("") // Or handle error as needed
            }
        }
        
        return results
    }
    
    /// Extract content from HTML using the LLM
    /// - Parameters:
    ///   - html: The HTML content to process
    ///   - contentType: The type of content to extract
    /// - Returns: The extracted content
    public func extractContent(from html: String, contentType: String) async throws -> String {
        // First clean and focus the HTML based on the content type
        let processedHTML = try preprocessHTML(html, for: contentType)
        print("🧹 Preprocessed HTML length: \(processedHTML.count) characters")
        
        let config = try configManager.currentConfig()
        let model = try configManager.nextModel(isComplexTask: contentType.lowercased() == "main content")
        
        let systemPrompt = """
        You are an expert at extracting information from HTML content.
        Extract only the requested information, nothing more.
        Return the raw value without any labels, prefixes, or formatting.
        
        Follow these specific rules for each content type:
        
        For titles:
        1. ALWAYS prioritize <h1> tags within <article> or main content area - this is the most important rule
        2. If no <h1> in article, look for meta tags (og:title, twitter:title)
        3. ONLY use <title> tag if no <h1> or meta tags are found
        4. Return ONLY the text content of the most relevant tag
        5. NEVER return the <title> tag content if an <h1> tag exists
        
        Examples for title extraction:
        - If HTML has: <title>Site Title</title> and <h1>Main Headline</h1>
          Return: "Main Headline"
        - If HTML has: <title>Site Title</title> and no <h1>
          Return: "Site Title"
        - If HTML has: <title>Site Title</title>, <h1>Main Headline</h1>, and <meta property="og:title" content="OG Title">
          Return: "Main Headline"
        
        For main content:
        1. Focus on content within <article> or main content area
        2. Include only substantive paragraphs
        3. Exclude navigation, headers, footers, and sidebars
        
        For authors:
        1. Look for bylines and author information
        2. Return only the author's name without titles or prefixes
        
        For publication dates:
        1. Prefer machine-readable dates (meta tags, data attributes)
        2. Convert to ISO 8601 format when possible
        3. Return only the date without labels
        
        For categories:
        1. Look for category or section indicators
        2. Return only the primary category name
        
        Do not include any explanatory text or field names in your response.
        """
        
        let userPrompt = """
        Extract the \(contentType) from the following HTML content.
        Return only the extracted value, without any labels or formatting:
        
        \(processedHTML)
        """
        
        var request = URLRequest(url: config.baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add any additional headers from configuration
        for (key, value) in config.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        request.timeoutInterval = config.timeoutInterval
        
        let parameters: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.2,
            "max_tokens": -1,
            "stream": false
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        
        print("Sending request to \(config.baseURL) with model: \(model)")
        print("Request headers: \(request.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            if let httpResponse = response as? HTTPURLResponse {
                print("Request failed with status code: \(httpResponse.statusCode)")
                if let responseData = String(data: data, encoding: .utf8) {
                    print("Response body: \(responseData)")
                }
            }
            throw LLMError.requestFailed
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw LLMError.invalidResponse
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Private HTML Preprocessing Methods
    
    /// Preprocess HTML content before sending to LLM
    /// - Parameters:
    ///   - html: Raw HTML content
    ///   - contentType: Type of content to extract
    /// - Returns: Cleaned and focused HTML
    private func preprocessHTML(_ html: String, for contentType: String) throws -> String {
        let document = try SwiftSoup.parse(html)
        
        // Remove unnecessary elements
        try document.select("script, style, iframe, noscript, svg, form").remove()
        
        // Focus on relevant content based on type
        switch contentType.lowercased() {
        case "title":
            return try extractTitleHTML(from: document)
        case "main content":
            return try extractMainContentHTML(from: document)
        case "author":
            return try extractAuthorHTML(from: document)
        case "publication date":
            return try extractDateHTML(from: document)
        case "category":
            return try extractCategoryHTML(from: document)
        default:
            return try document.html()
        }
    }
    
    private func extractTitleHTML(from document: Document) throws -> String {
        var titleHTML = "<head>\n"
        
        // Get meta title tags
        if let metaTitle = try document.select("meta[property='og:title'], meta[name='twitter:title']").first() {
            titleHTML += try metaTitle.outerHtml() + "\n"
        }
        
        titleHTML += "</head>\n<body>\n"
        
        // Get h1 tags within article or main content
        let h1Elements = try document.select("article h1, main h1, .article-title, .story-title, h1")
        if !h1Elements.isEmpty() {
            titleHTML += try h1Elements.array().map { try $0.outerHtml() }.joined(separator: "\n")
        } else if let title = try document.select("title").first() {
            titleHTML += try title.outerHtml()
        }
        
        titleHTML += "\n</body>"
        return titleHTML
    }
    
    private func extractMainContentHTML(from document: Document) throws -> String {
        var contentHTML = "<body>\n"
        
        // Try to find main content container
        let contentSelectors = [
            "article",
            "[itemprop='articleBody']",
            ".article-content",
            ".story-content",
            "main",
            ".post-content"
        ]
        
        var foundContent = false
        for selector in contentSelectors {
            let elements = try document.select(selector)
            if !elements.isEmpty() {
                // Instead of taking the entire container, just extract paragraphs and headings
                let contentElements = try elements.first()?.select("p, h2, h3, h4, h5, h6")
                if let contentElements = contentElements, !contentElements.isEmpty() {
                    // Filter out short paragraphs and boilerplate
                    let substantiveElements = try contentElements.filter { element in
                        let text = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
                        return text.count > 30 && // Longer than 30 chars
                               !text.lowercased().contains("cookie") && // Not cookie notices
                               !text.lowercased().contains("subscribe") && // Not subscription prompts
                               !text.lowercased().contains("sign up") && // Not signup prompts
                               !text.lowercased().contains("advertisement") // Not ads
                    }
                    
                    if !substantiveElements.isEmpty {
                        contentHTML += try substantiveElements.map { try $0.outerHtml() }.joined(separator: "\n") + "\n"
                        foundContent = true
                        break
                    }
                }
            }
        }
        
        // If no main content found, try to find substantive paragraphs directly
        if !foundContent {
            let paragraphs = try document.select("body p").filter { element in
                let text = try? element.text().trimmingCharacters(in: .whitespacesAndNewlines)
                return (text?.count ?? 0) > 50 && // Longer paragraphs only
                       !(text?.lowercased().contains("cookie") ?? false) &&
                       !(text?.lowercased().contains("subscribe") ?? false) &&
                       !(text?.lowercased().contains("sign up") ?? false) &&
                       !(text?.lowercased().contains("advertisement") ?? false)
            }
            
            if !paragraphs.isEmpty {
                contentHTML += try paragraphs.map { try $0.outerHtml() }.joined(separator: "\n")
            }
        }
        
        contentHTML += "\n</body>"
        return contentHTML
    }
    
    private func extractAuthorHTML(from document: Document) throws -> String {
        var authorHTML = "<body>\n"
        
        // Get author meta tags
        let metaAuthors = try document.select("meta[name='author'], meta[property='article:author']")
        if !metaAuthors.isEmpty() {
            authorHTML += try metaAuthors.array().map { try $0.outerHtml() }.joined(separator: "\n") + "\n"
        }
        
        // Get author elements
        let authorSelectors = [
            ".author",
            ".byline",
            "[itemprop='author']",
            ".article-author",
            ".story-author"
        ]
        
        for selector in authorSelectors {
            let elements = try document.select(selector)
            if !elements.isEmpty() {
                authorHTML += try elements.array().map { try $0.outerHtml() }.joined(separator: "\n") + "\n"
            }
        }
        
        authorHTML += "\n</body>"
        return authorHTML
    }
    
    private func extractDateHTML(from document: Document) throws -> String {
        var dateHTML = "<head>\n"
        
        // Get date meta tags
        let metaDates = try document.select("meta[property='article:published_time'], meta[name='publication-date']")
        if !metaDates.isEmpty() {
            dateHTML += try metaDates.array().map { try $0.outerHtml() }.joined(separator: "\n") + "\n"
        }
        
        dateHTML += "</head>\n<body>\n"
        
        // Get date elements
        let dateSelectors = [
            "time",
            "[itemprop='datePublished']",
            ".published-date",
            ".article-date",
            ".story-date"
        ]
        
        for selector in dateSelectors {
            let elements = try document.select(selector)
            if !elements.isEmpty() {
                dateHTML += try elements.array().map { try $0.outerHtml() }.joined(separator: "\n") + "\n"
            }
        }
        
        dateHTML += "\n</body>"
        return dateHTML
    }
    
    private func extractCategoryHTML(from document: Document) throws -> String {
        var categoryHTML = "<head>\n"
        
        // Get category meta tags
        let metaCategories = try document.select("meta[property='article:section'], meta[name='category']")
        if !metaCategories.isEmpty() {
            categoryHTML += try metaCategories.array().map { try $0.outerHtml() }.joined(separator: "\n") + "\n"
        }
        
        categoryHTML += "</head>\n<body>\n"
        
        // Get category elements
        let categorySelectors = [
            "[itemprop='articleSection']",
            ".category",
            ".article-category",
            ".story-category",
            ".section-name"
        ]
        
        for selector in categorySelectors {
            let elements = try document.select(selector)
            if !elements.isEmpty() {
                categoryHTML += try elements.array().map { try $0.outerHtml() }.joined(separator: "\n") + "\n"
            }
        }
        
        categoryHTML += "\n</body>"
        return categoryHTML
    }
}

/// Errors that can occur during LLM operations
public enum LLMError: Error {
    case requestFailed
    case invalidResponse
    case preprocessingFailed(String)
} 