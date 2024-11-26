//
//  File.swift
//  UtahNewsData
//
//  Created by Mark Evans on 11/26/24.
//

import Foundation



extension String {
    /// Constructs a fully qualified URL using the base URL if needed.
    /// - Parameter baseURL: The base URL to use if the URL string is relative.
    /// - Returns: A fully qualified URL string if valid, else `nil`.
    func constructValidURL(baseURL: String?) -> String? {
        if let url = URL(string: self), url.scheme != nil, url.host != nil {
            return self
        }
        if let baseURL = baseURL, let base = URL(string: baseURL) {
            if let fullURL = URL(string: self, relativeTo: base)?.absoluteURL {
                return fullURL.absoluteString
            }
        }
        return nil
    }
}
