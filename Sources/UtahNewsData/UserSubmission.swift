//
//  File.swift
//  UtahNewsData
//
//  Created by Mark Evans on 1/28/25.
//

import Foundation


public struct UserSubmission: AssociatedData, Codable, Identifiable, Hashable {
    public var id: String
    public var relationships: [Relationship] = []
    public var title: String
    public var description: String
    public var dateSubmitted: Date
    public var user: Person
    public var text: [TextMedia]
    public var images: [ImageMedia]
    public var videos: [VideoMedia]
    public var audio: [AudioMedia]
    public var documents: [DocumentMedia]
    
    init(
        id: String,
        relationships: [Relationship],
        title: String,
        description: String = "",
        dateSubmitted: Date = Date(),
        user: Person,
        text: [TextMedia] = [],
        images: [ImageMedia] = [],
        videos: [VideoMedia] = [],
        audio: [AudioMedia] = [],
        documents: [DocumentMedia] = []
    ) {
        self.id = id
        self.relationships = relationships
        self.title = title
        self.description = description
        self.dateSubmitted = dateSubmitted
        self.user = user
        self.text = text
        self.images = images
        self.videos = videos
        self.audio = audio
        self.documents = documents
    }
}
