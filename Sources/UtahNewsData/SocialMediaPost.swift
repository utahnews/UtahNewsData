//
//  SocialMediaPost.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

import SwiftUI


public struct SocialMediaPost: AssociatedData {
    public var id: String
    public var relationships: [Relationship] = []
    public var author: Person
    public var platform: String
    public var datePosted: Date
    public var url: URL?
    public var mediaItems: [MediaItem] = [] // Could include TextMedia, ImageMedia, etc.

    init(id: String = UUID().uuidString, author: Person, platform: String, datePosted: Date) {
        self.id = id
        self.author = author
        self.platform = platform
        self.datePosted = datePosted
    }
}
