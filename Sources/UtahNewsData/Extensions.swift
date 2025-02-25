//
//  Extensions.swift
//  UtahNewsData
//
//  Created by Mark Evans on 11/26/24.
//

/*
 # Extensions
 
 This file contains extensions to standard Swift types that provide additional
 functionality specific to the UtahNewsData system. These extensions enhance
 the capabilities of built-in types to better support the needs of news data
 processing and management.
 
 ## Key Extensions:
 
 1. String Extensions:
    - URL construction and validation
    - Text processing utilities
 
 ## Usage:
 
 ```swift
 // Using the constructValidURL extension
 let relativeURL = "articles/utah-economy.html"
 let baseURL = "https://www.utahnews.com"
 
 if let fullURL = relativeURL.constructValidURL(baseURL: baseURL) {
     // Use the fully qualified URL: "https://www.utahnews.com/articles/utah-economy.html"
     fetchArticle(from: fullURL)
 } else {
     // Handle invalid URL
     print("Could not construct a valid URL")
 }
 ```
 
 These extensions are designed to simplify common operations in the UtahNewsData
 system and provide consistent behavior across the codebase.
 */

import Foundation

/// Extensions to the String type for URL handling and text processing.
extension String {
    /// Constructs a fully qualified URL using the base URL if needed.
    /// This method handles both absolute URLs (which are returned as-is if valid)
    /// and relative URLs (which are combined with the base URL).
    ///
    /// - Parameter baseURL: The base URL to use if the URL string is relative.
    /// - Returns: A fully qualified URL string if valid, else `nil`.
    ///
    /// - Example:
    ///   ```swift
    ///   // Absolute URL (returned as-is)
    ///   "https://example.com/page.html".constructValidURL(baseURL: "https://base.com")
    ///   // Returns: "https://example.com/page.html"
    ///
    ///   // Relative URL (combined with base URL)
    ///   "page.html".constructValidURL(baseURL: "https://example.com")
    ///   // Returns: "https://example.com/page.html"
    ///   ```
    func constructValidURL(baseURL: String?) -> String? {
        // If the string is already a valid absolute URL, return it as-is
        if let url = URL(string: self), url.scheme != nil, url.host != nil {
            return self
        }
        
        // If we have a base URL, try to combine it with this string as a relative path
        if let baseURL = baseURL, let base = URL(string: baseURL) {
            if let fullURL = URL(string: self, relativeTo: base)?.absoluteURL {
                return fullURL.absoluteString
            }
        }
        
        // If we couldn't construct a valid URL, return nil
        return nil
    }
}
