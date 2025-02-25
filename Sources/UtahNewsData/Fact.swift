//
//  Fact.swift
//  UtahNewsData
//
//  Created by Mark Evans on 2/12/25.
//

/*
 # Fact Model
 
 This file defines the Fact model, which represents verified pieces of information
 in the UtahNewsData system. Facts can be associated with articles, news events, and other
 content types, providing verified data points with proper attribution.
 
 ## Key Features:
 
 1. Core content (statement of the fact)
 2. Verification status and confidence level
 3. Source attribution
 4. Contextual information (date, topic, category)
 5. Related entities
 
 ## Usage:
 
 ```swift
 // Create a basic fact
 let basicFact = Fact(
     statement: "Utah has the highest birth rate in the United States.",
     sources: [censusBureau] // Organization entity
 )
 
 // Create a detailed fact with verification
 let detailedFact = Fact(
     statement: "Utah's population grew by 18.4% between 2010 and 2020, making it the fastest-growing state in the nation.",
     sources: [censusBureau, utahDemographicOffice], // Organization entities
     verificationStatus: .verified,
     confidenceLevel: .high,
     date: Date(),
     topics: ["Demographics", "Population Growth"],
     category: demographicsCategory, // Category entity
     relatedEntities: [saltLakeCity, utahState] // Location entities
 )
 
 // Associate fact with an article
 let article = Article(
     title: "Utah's Population Boom Continues",
     body: ["Utah continues to lead the nation in population growth..."]
 )
 
 // Create relationship between fact and article
 let relationship = Relationship(
     fromEntity: detailedFact,
     toEntity: article,
     type: .supportedBy
 )
 
 detailedFact.relationships.append(relationship)
 article.relationships.append(relationship)
 ```
 
 The Fact model implements EntityDetailsProvider, allowing it to generate
 rich text descriptions for RAG (Retrieval Augmented Generation) systems.
 */

import Foundation

/// Represents the verification status of a fact
public enum VerificationStatus: String, Codable {
    case verified
    case unverified
    case disputed
    case retracted
}

/// Represents the confidence level in a fact's accuracy
public enum ConfidenceLevel: String, Codable {
    case high
    case medium
    case low
}

/// Represents a verified piece of information in the UtahNewsData system.
/// Facts can be associated with articles, news events, and other content types,
/// providing verified data points with proper attribution.
public struct Fact: AssociatedData, EntityDetailsProvider {
    /// Unique identifier for the fact
    public var id: String = UUID().uuidString
    
    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []
    
    /// The factual statement
    public var statement: String
    
    /// Organizations or persons that are the source of this fact
    public var sources: [EntityDetailsProvider]?
    
    /// Current verification status of the fact
    public var verificationStatus: VerificationStatus?
    
    /// Confidence level in the fact's accuracy
    public var confidenceLevel: ConfidenceLevel?
    
    /// When the fact was established or reported
    public var date: Date?
    
    /// Subject areas or keywords related to the fact
    public var topics: [String]?
    
    /// Formal category the fact belongs to
    public var category: Category?
    
    /// Entities (people, organizations, locations) related to this fact
    public var relatedEntities: [EntityDetailsProvider]?
    
    /// Creates a new Fact with the specified properties.
    ///
    /// - Parameters:
    ///   - statement: The factual statement
    ///   - sources: Organizations or persons that are the source of this fact
    ///   - verificationStatus: Current verification status of the fact
    ///   - confidenceLevel: Confidence level in the fact's accuracy
    ///   - date: When the fact was established or reported
    ///   - topics: Subject areas or keywords related to the fact
    ///   - category: Formal category the fact belongs to
    ///   - relatedEntities: Entities (people, organizations, locations) related to this fact
    public init(
        statement: String,
        sources: [EntityDetailsProvider]? = nil,
        verificationStatus: VerificationStatus? = nil,
        confidenceLevel: ConfidenceLevel? = nil,
        date: Date? = nil,
        topics: [String]? = nil,
        category: Category? = nil,
        relatedEntities: [EntityDetailsProvider]? = nil
    ) {
        self.statement = statement
        self.sources = sources
        self.verificationStatus = verificationStatus
        self.confidenceLevel = confidenceLevel
        self.date = date
        self.topics = topics
        self.category = category
        self.relatedEntities = relatedEntities
    }
    
    /// Generates a detailed text description of the fact for use in RAG systems.
    /// The description includes the statement, verification status, sources, and contextual information.
    ///
    /// - Returns: A formatted string containing the fact's details
    public func getDetailedDescription() -> String {
        var description = "FACT: \(statement)"
        
        if let verificationStatus = verificationStatus {
            description += "\nVerification Status: \(verificationStatus.rawValue)"
        }
        
        if let confidenceLevel = confidenceLevel {
            description += "\nConfidence Level: \(confidenceLevel.rawValue)"
        }
        
        if let sources = sources, !sources.isEmpty {
            description += "\nSources:"
            for source in sources {
                if let person = source as? Person {
                    description += "\n- \(person.name)"
                } else if let organization = source as? Organization {
                    description += "\n- \(organization.name)"
                }
            }
        }
        
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            description += "\nDate: \(formatter.string(from: date))"
        }
        
        if let category = category {
            description += "\nCategory: \(category.name)"
        }
        
        if let topics = topics, !topics.isEmpty {
            description += "\nTopics: \(topics.joined(separator: ", "))"
        }
        
        return description
    }
}

public enum Verification: String, CaseIterable {
    case none = "None"
    case human = "Human"
    case ai = "AI"
}
