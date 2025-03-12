//
//  StatisticalData+HTMLParsable.swift
//  UtahNewsData
//
//  Created by Mark Evans on 3/21/24
//
//  Summary: Extension making StatisticalData conform to HTMLParsable for HTML content extraction.

import Foundation
import SwiftSoup

extension StatisticalData: HTMLParsable {
    public static func parse(from document: Document) throws -> StatisticalData {
        // Validate that the document has a proper structure
        guard try !document.select("body").isEmpty(),
              try !document.select("head").isEmpty() else {
            throw ParsingError.invalidHTML
        }
        
        // Get the title from various possible locations
        let title = try document.select("h1.stat-title").first()?.text() ??
                   document.select("[itemprop='name']").first()?.text() ??
                   document.title()
        
        // Validate that we have a title
        guard !title.isEmpty else {
            throw ParsingError.missingRequiredField("title")
        }
        
        // Get the statistical value
        let value = try document.select("[itemprop='value']").first()?.text() ??
                   document.select(".stat-value").first()?.text() ??
                   "0"
        
        // Get the unit of measurement
        let unit = try document.select("[itemprop='unitText']").first()?.text() ??
                  document.select(".stat-unit").first()?.text() ??
                  ""
        
        // Get the source information
        let sourceName = try document.select("[itemprop='sourceOrganization']").first()?.text() ??
                        document.select(".stat-source").first()?.text()
        
        // Get the methodology
        let methodology = try document.select("[itemprop='methodology']").first()?.text() ??
                         document.select(".stat-methodology").first()?.text()
        
        // Get the margin of error
        let marginOfError = try document.select("[itemprop='marginOfError']").first()?.text() ??
                           document.select(".stat-margin").first()?.text()
        
        // Create the source person if we have a name
        let source = sourceName.map { Person(name: $0, details: "Source", biography: nil) }
        
        return StatisticalData(
            title: title,
            value: value,
            unit: unit,
            source: source,
            date: Date(),
            methodology: methodology,
            marginOfError: marginOfError
        )
    }
    
    public static func parse(from html: String) throws -> StatisticalData {
        do {
            let document = try SwiftSoup.parse(html)
            return try parse(from: document)
        } catch {
            throw ParsingError.invalidHTML
        }
    }
} 