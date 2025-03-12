//
//  HTMLParsable.swift
//  UtahNewsData
//
//  Created by Mark Evans on 3/21/24
//
//  Summary: Defines the HTMLParsable protocol for parsing HTML content into domain models.

import Foundation
import SwiftSoup

/// Protocol for types that can be parsed from HTML content.
/// Conforming types must implement a static parse method that takes a SwiftSoup Document
/// and returns an instance of the type.
public protocol HTMLParsable {
    /// Parse an instance of this type from HTML content.
    ///
    /// - Parameter document: The SwiftSoup Document to parse from
    /// - Returns: An instance of this type
    /// - Throws: ParsingError if the required data cannot be found or is invalid
    static func parse(from document: Document) throws -> Self
    
    /// Parse an HTML string and return an instance of Self.
    /// - Parameter html: The raw HTML content as a String.
    /// - Returns: An instance of the model parsed from the HTML.
    static func parse(from html: String) throws -> Self
    
    /// Extract text content from an HTML element using the given CSS selector.
    /// - Parameters:
    ///   - element: The element to search within.
    ///   - selector: The CSS selector to use.
    /// - Returns: The text content of the matched element, if found.
    static func extractText(from element: Element, selector: String) throws -> String?
    
    /// Extract an attribute value from an HTML element using the given CSS selector.
    /// - Parameters:
    ///   - element: The element to search within.
    ///   - selector: The CSS selector to use.
    ///   - attribute: The name of the attribute to extract.
    /// - Returns: The attribute value, if found.
    static func extractAttribute(from element: Element, selector: String, attribute: String) throws -> String?
}

extension String {
    /// Returns nil if the string is empty, otherwise returns self
    var nilIfEmpty: String? {
        return isEmpty ? nil : self
    }
}

/// Default implementations for HTMLParsable
public extension HTMLParsable {
    static func extractText(from element: Element, selector: String) throws -> String? {
        try element.select(selector).first()?.text()
    }
    
    static func extractAttribute(from element: Element, selector: String, attribute: String) throws -> String? {
        try element.select(selector).first()?.attr(attribute)
    }
    
    static func parse(from html: String) throws -> Self {
        do {
            let document = try SwiftSoup.parse(html)
            guard try !document.select("body").isEmpty(),
                  try !document.select("head").isEmpty() else {
                throw ParsingError.invalidHTML
            }
            return try parse(from: document)
        } catch let error as ParsingError {
            throw error
        } catch {
            throw ParsingError.invalidHTML
        }
    }
} 