//
//  AssociatedData.swift
//  UtahNewsData
//
//  Created by Mark Evans on 11/26/24.
//

import Foundation


import SwiftUI
import Foundation

public protocol AssociatedData {
    var id: String { get }
    var relationships: [Relationship] { get set }
}

public struct Relationship: Codable, Hashable {
    public let id: String
    public let type: AssociatedDataType
    public var displayName: String?
}

public enum AssociatedDataType: String, Codable {
    case person = "persons"
    case organization = "organizations"
    case location = "locations"
    case category = "categories"
    case source = "sources"
    case mediaItem = "mediaItems"
    case newsEvent = "newsEvents"
    case newsStory = "newsStories"
    case quote = "quotes"
    case fact = "facts"
    case statisticalData = "statisticalData"
    case calendarEvent = "calendarEvents"
    case legalDocument = "legalDocuments"
    case socialMediaPost = "socialMediaPosts"
    case expertAnalysis = "expertAnalyses"
    case poll = "polls"
    case alert = "alerts"
    // Add other types as needed
}

