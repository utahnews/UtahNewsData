//
//  LegalDocument.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

/*
 # LegalDocument Model
 
 This file defines the LegalDocument model, which represents legal documents and
 official records in the UtahNewsData system. Legal documents can include court
 filings, legislation, regulations, and other official legal records relevant to
 news coverage.
 
 ## Key Features:
 
 1. Document identification (title)
 2. Publication tracking (dateIssued)
 3. Relationship tracking with other entities
 
 ## Usage:
 
 ```swift
 // Create a legal document
 let legislation = LegalDocument(
     title: "Senate Bill 101: Water Conservation Act",
     dateIssued: Date()
 )
 
 // Associate with related entities
 let legislatorRelationship = Relationship(
     id: senator.id,
     type: .person,
     displayName: "Sponsored by"
 )
 legislation.relationships.append(legislatorRelationship)
 
 let topicRelationship = Relationship(
     id: waterCategory.id,
     type: .category,
     displayName: "Related to"
 )
 legislation.relationships.append(topicRelationship)
 ```
 
 The LegalDocument model implements AssociatedData, allowing it to maintain
 relationships with other entities in the system, such as people, organizations,
 and categories.
 */

import SwiftUI

/// Represents a legal document or official record in the news system.
/// Legal documents can include court filings, legislation, regulations,
/// and other official legal records relevant to news coverage.
public struct LegalDocument: AssociatedData {
    /// Unique identifier for the legal document
    public var id: String
    
    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []
    
    /// Title or name of the legal document
    public var title: String
    
    /// When the document was issued or published
    public var dateIssued: Date
    
    /// The name property required by the AssociatedData protocol.
    /// Returns the title of the document.
    public var name: String {
        return title
    }
    
    /// Document type (e.g., "legislation", "court filing", "regulation")
    public var documentType: String?
    
    /// Official document number or identifier
    public var documentNumber: String?
    
    /// URL where the document can be accessed
    public var documentURL: String?
    
    /// Creates a new legal document with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the document (defaults to a new UUID string)
    ///   - title: Title or name of the legal document
    ///   - dateIssued: When the document was issued or published
    ///   - documentType: Type of document (e.g., "legislation", "court filing")
    ///   - documentNumber: Official document number or identifier
    ///   - documentURL: URL where the document can be accessed
    public init(
        id: String = UUID().uuidString,
        title: String,
        dateIssued: Date,
        documentType: String? = nil,
        documentNumber: String? = nil,
        documentURL: String? = nil
    ) {
        self.id = id
        self.title = title
        self.dateIssued = dateIssued
        self.documentType = documentType
        self.documentNumber = documentNumber
        self.documentURL = documentURL
    }
}
