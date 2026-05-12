//
//  Shareable.swift
//  UtahNewsDataModels
//
//  Canonical share-URL builders for platform-owned content.
//
//  Per the platform editorial thesis (primary sources, not aggregation),
//  Article / Video / Audio are owned by utah.news — their canonical
//  share URL is `https://utah.news/<route>/<id>`, NOT the upstream news
//  outlet URL.
//
//  These URLs are registered for Universal Links via the iOS app's
//  Associated Domains entitlement and the apple-app-site-association
//  file served from utah.news/.well-known/.
//

import Foundation

/// Centralized canonical-host configuration for share URLs.
///
/// Single source of truth for the base URL used to build shareable
/// links to platform-owned content. Update here if the canonical host
/// ever moves (e.g. to a regional NetworkNews subdomain).
public enum ShareableHost {
    /// HTTPS base for all share URLs (no trailing slash).
    public static let base = "https://utah.news"
}

// MARK: - Article

public extension Article {
    /// Canonical universal-link URL for sharing this article.
    ///
    /// Format: `https://utah.news/article/{id}` — registered as a
    /// Universal Link by the UtahNews iOS app, so recipients with the
    /// app installed open the article in-app, and recipients without
    /// the app see the web reader.
    var shareableURL: URL {
        // Force-unwrap is safe — base + path-encoded id always produce a
        // valid URL. id is a String (platform convention), never empty
        // for persisted articles.
        URL(string: "\(ShareableHost.base)/article/\(id.urlPathEncoded)")!
    }
}

// MARK: - Video

public extension Video {
    /// Canonical universal-link URL for sharing this video.
    ///
    /// Format: `https://utah.news/v/{id}`.
    var shareableURL: URL {
        URL(string: "\(ShareableHost.base)/v/\(id.urlPathEncoded)")!
    }
}

// MARK: - Audio

public extension Audio {
    /// Canonical universal-link URL for sharing this audio episode.
    ///
    /// Format: `https://utah.news/a/{id}`.
    var shareableURL: URL {
        URL(string: "\(ShareableHost.base)/a/\(id.urlPathEncoded)")!
    }
}

// MARK: - Internal Helpers

extension String {
    /// Percent-encodes a String for safe inclusion as a URL path
    /// component. Falls back to the raw string if the encoding set
    /// somehow rejects the input (shouldn't happen for IDs).
    fileprivate var urlPathEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? self
    }
}
