//
//  NewsEvent.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

import SwiftUI



public struct NewsEvent: AssociatedData {
    public var id: String
    public var relationships: [Relationship] = []
    public var title: String
    public var date: Date
    public var quotes: [Quote] = []
    public var facts: [Fact] = []
    public var statisticalData: [StatisticalData] = []
    public var categories: [Category] = []

    init(id: String = UUID().uuidString, title: String, date: Date) {
        self.id = id
        self.title = title
        self.date = date
    }
}
