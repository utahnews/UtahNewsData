//
//  NewsEvent.swift
//  UtahNewsData
//
//  Created by Mark Evans on 2/12/25.
//

/*
 # NewsEvent Model
 
 This file defines the NewsEvent model, which represents significant events covered in the news
 in the UtahNewsData system. NewsEvents can be associated with articles, people, organizations,
 and locations, providing a way to track and organize coverage of specific occurrences.
 
 ## Key Features:
 
 1. Core event information (title, date)
 2. Associated content (quotes, facts, statistical data)
 3. Categorization
 4. Relationships to other entities
 
 ## Usage:
 
 ```swift
 // Create a basic news event
 let basicEvent = NewsEvent(
     title: "Utah State Fair",
     date: Date() // September 5, 2023
 )
 
 // Create a detailed news event with associated content
 let detailedEvent = NewsEvent(
     title: "Utah Legislative Session 2023",
     date: Date() // January 17, 2023
 )
 
 // Add quotes to the event
 let governorQuote = Quote(
     text: "This legislative session will focus on water conservation and education funding.",
     speaker: governor // Person entity
 )
 detailedEvent.quotes.append(governorQuote)
 
 // Add facts to the event
 let budgetFact = Fact(
     statement: "The proposed state budget includes $200 million for water infrastructure."
 )
 detailedEvent.facts.append(budgetFact)
 
 // Add statistical data to the event
 let educationStat = StatisticalData(
     title: "Education Funding",
     value: "7.8",
     unit: "billion dollars"
 )
 detailedEvent.statisticalData.append(educationStat)
 
 // Add categories to the event
 let politicsCategory = Category(name: "Politics")
 let budgetCategory = Category(name: "Budget")
 detailedEvent.categories = [politicsCategory, budgetCategory]
 
 // Create relationships with other entities
 let articleRelationship = Relationship(
     fromEntity: detailedEvent,
     toEntity: legislativeArticle, // Article entity
     type: .describes
 )
 detailedEvent.relationships.append(articleRelationship)
 ```
 
 The NewsEvent model implements AssociatedData, allowing it to be linked with
 other entities in the UtahNewsData system through relationships.
 */

import Foundation

/// Represents a significant event covered in the news in the UtahNewsData system.
/// NewsEvents can be associated with articles, people, organizations, and locations,
/// providing a way to track and organize coverage of specific occurrences.
public struct NewsEvent: Codable, Identifiable, Hashable, Equatable, AssociatedData {
    /// Unique identifier for the news event
    public var id: String
    
    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []
    
    /// The name or headline of the event
    public var title: String
    
    /// When the event occurred
    public var date: Date
    
    /// Direct quotations related to the event
    public var quotes: [Quote] = []
    
    /// Verified facts related to the event
    public var facts: [Fact] = []
    
    /// Statistical data points related to the event
    public var statisticalData: [StatisticalData] = []
    
    /// Categories that the event belongs to
    public var categories: [Category] = []
    
    /// Creates a new NewsEvent with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the news event (defaults to a new UUID string)
    ///   - title: The name or headline of the event
    ///   - date: When the event occurred
    public init(id: String = UUID().uuidString, title: String, date: Date) {
        self.id = id
        self.title = title
        self.date = date
    }
}
