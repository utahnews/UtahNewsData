//
//  StatisticalData.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

import SwiftUI


public struct StatisticalData: AssociatedData {
    public var id: UUID
    public var relationships: [Relationship] = []
    public var title: String
    public var dataPoints: [DataPoint] = []
    public var source: Source
    public var date: Date

    init(id: UUID = UUID(), title: String, source: Source, date: Date) {
        self.id = id
        self.title = title
        self.source = source
        self.date = date
    }
}

public struct DataPoint {
    public var label: String
    public var value: Double
}
