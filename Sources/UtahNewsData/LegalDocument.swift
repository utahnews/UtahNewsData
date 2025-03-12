//
//  LegalDocument.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//
//  Summary: Defines the LegalDocument model which represents legal documents and
//           official records in the UtahNewsData system. Now conforms to JSONSchemaProvider
//           to provide a static JSON schema for LLM responses.

import SwiftUI
import Foundation
import SwiftSoup

/// Represents different types of legal documents
public enum LegalDocumentType: String, Codable, CaseIterable, Sendable {
    /// Legislative bill
    case bill = "Bill"
    /// Court ruling or decision
    case courtRuling = "Court Ruling"
    /// Executive order
    case executiveOrder = "Executive Order"
    /// Administrative regulation
    case regulation = "Regulation"
    /// Legal statute
    case statute = "Statute"
    /// Legal opinion or advisory
    case legalOpinion = "Legal Opinion"
    /// Policy document
    case policy = "Policy"
    /// Other legal document types
    case other = "Other"
    
    /// Returns a human-readable description of the document type
    public var description: String {
        return self.rawValue
    }
}

/// Represents a legal document or official record in the news system.
/// Legal documents can include court filings, legislation, regulations,
/// and other official legal records relevant to news coverage.
public struct LegalDocument: AssociatedData, JSONSchemaProvider { // Added JSONSchemaProvider conformance
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
    
    // MARK: - JSON Schema Provider
    /// Provides the JSON schema for LegalDocument.
    public static var jsonSchema: String {
        return """
        {
            "type": "object",
            "properties": {
                "id": {"type": "string"},
                "relationships": {
                    "type": "array",
                    "items": {"type": "object"}
                },
                "title": {"type": "string"},
                "dateIssued": {"type": "string", "format": "date-time"},
                "documentType": {"type": ["string", "null"]},
                "documentNumber": {"type": ["string", "null"]},
                "documentURL": {"type": ["string", "null"]}
            },
            "required": ["id", "title", "dateIssued"]
        }
        """
    }
}
