//
//  SocialMediaPost.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

/*
 # SocialMediaPost Model
 
 This file defines the SocialMediaPost model, which represents social media content
 in the UtahNewsData system. Social media posts can include tweets, Facebook posts,
 Instagram posts, and other content from social platforms that are relevant to news coverage.
 
 ## Key Features:
 
 1. Author attribution
 2. Platform identification
 3. Timing information (datePosted)
 4. Content access (url)
 5. Relationship tracking with other entities
 
 ## Usage:
 
 ```swift
 // Create a social media post
 let politician = Person(name: "Jane Smith", details: "State Senator")
 
 let tweet = SocialMediaPost(
     author: politician,
     platform: "Twitter",
     datePosted: Date(),
     content: "Proud to announce that the water conservation bill passed today with bipartisan support!"
 )
 
 // Set the URL to the original post
 tweet.url = URL(string: "https://twitter.com/janesmith/status/1234567890")
 
 // Associate with related entities
 let billRelationship = Relationship(
     id: senateBill101.id,
     type: .legalDocument,
     displayName: "References"
 )
 tweet.relationships.append(billRelationship)
 ```
 
 The SocialMediaPost model implements AssociatedData, allowing it to maintain
 relationships with other entities in the system, such as people, organizations,
 and topics mentioned in the post.
 */

import SwiftUI

/// Represents a social media post in the news system.
/// Social media posts can include tweets, Facebook posts, Instagram posts,
/// and other content from social platforms that are relevant to news coverage.
public struct SocialMediaPost: AssociatedData {
    /// Unique identifier for the social media post
    public var id: String
    
    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []
    
    /// Person or entity who created the post
    public var author: Person
    
    /// Social media platform where the post was published (e.g., "Twitter", "Facebook")
    public var platform: String
    
    /// When the post was published
    public var datePosted: Date
    
    /// URL to the original post
    public var url: URL?
    
    /// The name property required by the AssociatedData protocol.
    /// Returns a descriptive name based on the author and platform.
    public var name: String {
        return "\(author.name)'s \(platform) post"
    }
    
    /// Text content of the post
    public var content: String?
    
    /// URLs to media (images, videos) included in the post
    public var mediaURLs: [String]?
    
    /// Number of likes/favorites the post received
    public var likeCount: Int?
    
    /// Number of shares/retweets the post received
    public var shareCount: Int?
    
    /// Number of comments/replies the post received
    public var commentCount: Int?
    
    /// Creates a new social media post with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the post (defaults to a new UUID string)
    ///   - author: Person or entity who created the post
    ///   - platform: Social media platform where the post was published
    ///   - datePosted: When the post was published
    ///   - url: URL to the original post
    ///   - content: Text content of the post
    ///   - mediaURLs: URLs to media included in the post
    ///   - likeCount: Number of likes/favorites the post received
    ///   - shareCount: Number of shares/retweets the post received
    ///   - commentCount: Number of comments/replies the post received
    public init(
        id: String = UUID().uuidString,
        author: Person,
        platform: String,
        datePosted: Date,
        url: URL? = nil,
        content: String? = nil,
        mediaURLs: [String]? = nil,
        likeCount: Int? = nil,
        shareCount: Int? = nil,
        commentCount: Int? = nil
    ) {
        self.id = id
        self.author = author
        self.platform = platform
        self.datePosted = datePosted
        self.url = url
        self.content = content
        self.mediaURLs = mediaURLs
        self.likeCount = likeCount
        self.shareCount = shareCount
        self.commentCount = commentCount
    }
}
