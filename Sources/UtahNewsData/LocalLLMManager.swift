import Foundation

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
        
        \(html)
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
}

/// Errors that can occur during LLM operations
public enum LLMError: Error {
    case requestFailed
    case invalidResponse
} 