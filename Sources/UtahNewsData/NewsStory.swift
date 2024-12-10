//
//  NewsStory.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

import SwiftUI

public struct NewsStory: AssociatedData {
    public var id: String
    public var relationships: [Relationship] = []
    public var headline: String
    public var author: Person
    public var publishedDate: Date
    public var mediaItems: [MediaItem] = []
    public var categories: [Category] = []
    public var sources: [Source] = []

    init(id: String = UUID().uuidString, headline: String, author: Person, publishedDate: Date) {
        self.id = id
        self.headline = headline
        self.author = author
        self.publishedDate = publishedDate
    }
}
