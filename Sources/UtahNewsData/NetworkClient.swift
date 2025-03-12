import Foundation
import WebKit

/// A client for fetching HTML content from URLs
@MainActor
public final class NetworkClient: @unchecked Sendable {
    /// Shared instance for convenience
    public static let shared = NetworkClient()
    
    /// URLSession for making network requests
    private let session: URLSession
    
    /// WebPageLoader for dynamic content
    private let webLoader: WebPageLoader
    
    /// List of domains known to require JavaScript
    private let dynamicDomains = [
        "fox13now.com",
        "kutv.com",
        "abc4.com",
        "deseret.com"
    ]
    
    /// Creates a new network client
    /// - Parameters:
    ///   - session: URLSession to use (defaults to shared session)
    ///   - webLoader: WebPageLoader to use (defaults to shared instance)
    public init(session: URLSession = .shared, webLoader: WebPageLoader = .shared) {
        self.session = session
        self.webLoader = webLoader
    }
    
    /// Fetches HTML content from a URL
    /// - Parameter url: The URL to fetch from
    /// - Returns: The HTML content as a string
    /// - Throws: Network or decoding errors
    public func fetchHTML(from url: URL) async throws -> String {
        // Check if this is a dynamic site that requires JavaScript
        if let host = url.host?.replacingOccurrences(of: "www.", with: ""),
           dynamicDomains.contains(host) {
            return try await webLoader.loadPage(url: url)
        }
        
        // For static sites, use regular URLSession
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw NetworkError.invalidData
        }
        
        // Clean the HTML content
        return try webLoader.cleanHTMLContent(html)
    }
}

/// Errors that can occur during network operations
public enum NetworkError: Error {
    case invalidResponse
    case httpError(statusCode: Int)
    case invalidData
} 