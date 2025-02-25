//
//  StatisticalData.swift
//  UtahNewsData
//
//  Created by Mark Evans on 2/12/25.
//

/*
 # StatisticalData Model
 
 This file defines the StatisticalData model, which represents numerical data points
 in the UtahNewsData system. StatisticalData can be associated with articles, news events,
 and other content types, providing quantitative information with proper attribution.
 
 ## Key Features:
 
 1. Core data (title, value, unit)
 2. Source attribution
 3. Contextual information (date, methodology, margin of error)
 4. Visualization hints
 5. Related entities
 
 ## Usage:
 
 ```swift
 // Create a basic statistical data point
 let basicStat = StatisticalData(
     title: "Utah Population",
     value: "3.3",
     unit: "million people"
 )
 
 // Create a detailed statistical data point
 let detailedStat = StatisticalData(
     title: "Utah Unemployment Rate",
     value: "2.1",
     unit: "percent",
     source: laborDepartment, // Organization entity
     date: Date(),
     methodology: "Based on monthly survey of employers",
     marginOfError: "±0.2",
     visualizationType: .lineChart,
     comparisonValue: "3.5", // National average
     topics: ["Economy", "Employment"],
     relatedEntities: [saltLakeCounty, utahState] // Location entities
 )
 
 // Associate statistical data with an article
 let article = Article(
     title: "Utah's Economy Continues Strong Performance",
     body: ["Utah's economy showed strong performance in the latest economic indicators..."]
 )
 
 // Create relationship between statistical data and article
 let relationship = Relationship(
     fromEntity: detailedStat,
     toEntity: article,
     type: .supportedBy
 )
 
 detailedStat.relationships.append(relationship)
 article.relationships.append(relationship)
 ```
 
 The StatisticalData model implements EntityDetailsProvider, allowing it to generate
 rich text descriptions for RAG (Retrieval Augmented Generation) systems.
 */

import Foundation

/// Represents the type of visualization suitable for the statistical data
public enum VisualizationType: String, Codable {
    case barChart
    case lineChart
    case pieChart
    case scatterPlot
    case table
    case other
}

/// Represents a numerical data point in the UtahNewsData system.
/// StatisticalData can be associated with articles, news events, and other content types,
/// providing quantitative information with proper attribution.
public struct StatisticalData: Codable, Identifiable, Hashable, Equatable, EntityDetailsProvider {
    /// Unique identifier for the statistical data
    public var id: String = UUID().uuidString
    
    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []
    
    /// The name or description of the statistical data
    public var title: String
    
    /// The numerical value of the statistic
    public var value: String
    
    /// The unit of measurement (e.g., "percent", "million dollars")
    public var unit: String
    
    /// Organization or person that is the source of this data
    public var source: EntityDetailsProvider?
    
    /// When the data was collected or published
    public var date: Date?
    
    /// Information about how the data was collected or calculated
    public var methodology: String?
    
    /// Statistical margin of error if applicable
    public var marginOfError: String?
    
    /// Recommended visualization type for this data
    public var visualizationType: VisualizationType?
    
    /// A comparison value for context (e.g., previous year, national average)
    public var comparisonValue: String?
    
    /// Subject areas or keywords related to the data
    public var topics: [String]?
    
    /// Entities (people, organizations, locations) related to this data
    public var relatedEntities: [EntityDetailsProvider]?
    
    /// Creates a new StatisticalData with the specified properties.
    ///
    /// - Parameters:
    ///   - title: The name or description of the statistical data
    ///   - value: The numerical value of the statistic
    ///   - unit: The unit of measurement (e.g., "percent", "million dollars")
    ///   - source: Organization or person that is the source of this data
    ///   - date: When the data was collected or published
    ///   - methodology: Information about how the data was collected or calculated
    ///   - marginOfError: Statistical margin of error if applicable
    ///   - visualizationType: Recommended visualization type for this data
    ///   - comparisonValue: A comparison value for context (e.g., previous year, national average)
    ///   - topics: Subject areas or keywords related to the data
    ///   - relatedEntities: Entities (people, organizations, locations) related to this data
    public init(
        title: String,
        value: String,
        unit: String,
        source: EntityDetailsProvider? = nil,
        date: Date? = nil,
        methodology: String? = nil,
        marginOfError: String? = nil,
        visualizationType: VisualizationType? = nil,
        comparisonValue: String? = nil,
        topics: [String]? = nil,
        relatedEntities: [EntityDetailsProvider]? = nil
    ) {
        self.title = title
        self.value = value
        self.unit = unit
        self.source = source
        self.date = date
        self.methodology = methodology
        self.marginOfError = marginOfError
        self.visualizationType = visualizationType
        self.comparisonValue = comparisonValue
        self.topics = topics
        self.relatedEntities = relatedEntities
    }
    
    /// Generates a detailed text description of the statistical data for use in RAG systems.
    /// The description includes the title, value, unit, source, and contextual information.
    ///
    /// - Returns: A formatted string containing the statistical data's details
    public func getDetailedDescription() -> String {
        var description = "STATISTICAL DATA: \(title)"
        description += "\nValue: \(value) \(unit)"
        
        if let marginOfError = marginOfError {
            description += " (±\(marginOfError))"
        }
        
        if let source = source {
            if let organization = source as? Organization {
                description += "\nSource: \(organization.name)"
            } else if let person = source as? Person {
                description += "\nSource: \(person.name)"
            }
        }
        
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            description += "\nDate: \(formatter.string(from: date))"
        }
        
        if let methodology = methodology {
            description += "\nMethodology: \(methodology)"
        }
        
        if let comparisonValue = comparisonValue {
            description += "\nComparison Value: \(comparisonValue) \(unit)"
        }
        
        if let topics = topics, !topics.isEmpty {
            description += "\nTopics: \(topics.joined(separator: ", "))"
        }
        
        return description
    }
}
