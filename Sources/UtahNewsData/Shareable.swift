//
//  Shareable.swift
//  UtahNewsData
//
//  Canonical share-URL builders for the FULL Article / Audio types
//  defined in this package (separate from the lightweight versions in
//  UtahNewsDataModels).
//
//  See `UtahNewsDataModels/Shareable.swift` for the source of truth on
//  the canonical host (`https://utah.news`) and route conventions. This
//  file simply mirrors the extensions onto the parsing-flavored types
//  so consumers that import `UtahNewsData` can use `article.shareableURL`
//  whether they hold a `UtahNewsData.Article` or a
//  `UtahNewsDataModels.Article`.
//

import Foundation
import UtahNewsDataModels

// MARK: - Article (full / parsing version)

public extension Article {
    /// Canonical universal-link URL for sharing this article.
    /// Format: `https://utah.news/article/{id}`.
    var shareableURL: URL {
        URL(string: "\(ShareableHost.base)/article/\(id.urlPathEncodedShareID)")!
    }
}

// MARK: - Audio (full version)

public extension Audio {
    /// Canonical universal-link URL for sharing this audio episode.
    /// Format: `https://utah.news/a/{id}`.
    var shareableURL: URL {
        URL(string: "\(ShareableHost.base)/a/\(id.urlPathEncodedShareID)")!
    }
}

// MARK: - Internal Helper

extension String {
    /// Same percent-encoding helper as the Models version (renamed
    /// to avoid colliding with the fileprivate one in the Models target).
    fileprivate var urlPathEncodedShareID: String {
        addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? self
    }
}
