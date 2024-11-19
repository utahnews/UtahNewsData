//
//  NewsContent.swift
//  UtahNewsData
//
//  Created by Mark Evans on 11/18/24.
//

import Foundation

/// A protocol defining the common properties and methods for news content types.
public protocol NewsContent: Identifiable, Codable, Equatable, Hashable {
    var id: UUID { get set }
    var title: String { get set }
    var url: String { get set }
    var urlToImage: String? { get set }
    var publishedAt: Date { get set }
    var textContent: String? { get set }
    var author: String? { get set }
    
    func basicInfo() -> String
}

public extension NewsContent {
    func basicInfo() -> String {
        return "Title: \(title), Published At: \(publishedAt)"
    }
}
