import Foundation

/// A manager class for handling interactions with a local LLM
@MainActor
public class LocalLLMManager: @unchecked Sendable {
    /// The shared instance of the LLM manager
    public static let shared = LocalLLMManager()
    
    /// The endpoint URL for the LLM service
    private let endpoint: URL
    
    /// Initialize with endpoint URL
    public init(endpoint: String = "http://localhost:1234/v1/chat/completions") {
        self.endpoint = URL(string: endpoint)!
    }
    
    /// Extract content from HTML using the LLM
    /// - Parameters:
    ///   - html: The HTML content to process
    ///   - contentType: The type of content to extract
    /// - Returns: The extracted content
    public func extractContent(from html: String, contentType: String) async throws -> String {
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
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "model": contentType.lowercased() == "main content" ? "mistral-nemo-instruct-2407" : "llama-3.2-3b-instruct",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.2,
            "max_tokens": -1,
            "stream": false
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
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