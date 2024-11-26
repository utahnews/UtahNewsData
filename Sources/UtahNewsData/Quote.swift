//
//  Quote.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

import SwiftUI


public struct Quote: AssociatedData {
    public var id: UUID
    public var relationships: [Relationship] = []
    public var author: Person
    public var date: Date?
    public var mediaItems: [MediaItem] = [] // Typically contains TextMedia

    init(id: UUID = UUID(), author: Person, date: Date? = nil) {
        self.id = id
        self.author = author
        self.date = date
    }
}
