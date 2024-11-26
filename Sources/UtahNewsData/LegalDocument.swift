//
//  LegalDocument.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

import SwiftUI


public struct LegalDocument: AssociatedData {
    var id: UUID
    var relationships: [Relationship] = []
    var title: String
    var dateIssued: Date
    var mediaItems: [MediaItem] = [] // Contains DocumentMedia or TextMedia

    init(id: UUID = UUID(), title: String, dateIssued: Date) {
        self.id = id
        self.title = title
        self.dateIssued = dateIssued
    }
}
