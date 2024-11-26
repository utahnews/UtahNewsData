//
//  NewsAlert.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

import SwiftUI


public struct NewsAlert: AssociatedData {
    public var id: UUID
    public var relationships: [Relationship] = []
    public var title: String
    public var message: String
    public var dateIssued: Date
    public var level: AlertLevel

    init(id: UUID = UUID(), title: String, message: String, dateIssued: Date, level: AlertLevel) {
        self.id = id
        self.title = title
        self.message = message
        self.dateIssued = dateIssued
        self.level = level
    }
}

public enum AlertLevel {
    case low
    case medium
    case high
    case critical
}
