//
//  NewsEvent.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

import SwiftUI



public struct NewsEvent: AssociatedData {
    public var id: UUID
    public var relationships: [Relationship] = []
    public var title: String
    public var date: Date
    public var mediaItems: [MediaItem] = []
    public var quotes: [Quote] = []
    public var facts: [Fact] = []
    public var statisticalData: [StatisticalData] = []
    public var categories: [Category] = []

    init(id: UUID = UUID(), title: String, date: Date) {
        self.id = id
        self.title = title
        self.date = date
    }
}
