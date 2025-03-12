import Foundation
import SwiftSoup

extension LegalDocument: HTMLParsable {
    public static func parse(from document: Document) throws -> LegalDocument {
        // Validate that the document has a proper structure
        guard try !document.select("body").isEmpty(),
              try !document.select("head").isEmpty() else {
            throw ParsingError.invalidFormat("Invalid HTML document structure")
        }
        
        // Extract required fields
        let title = try extractTitle(from: document)
        let documentType = try extractDocumentType(from: document)
        
        // Extract optional fields
        let caseNumber = try extractCaseNumber(from: document)
        let filingDate = try extractFilingDate(from: document)
        let documentURL = try extractDocumentURL(from: document)
        
        // Create and return the LegalDocument
        return LegalDocument(
            title: title,
            dateIssued: filingDate ?? Date(),
            documentType: documentType ?? "unknown",
            documentNumber: caseNumber,
            documentURL: documentURL
        )
    }
    
    // MARK: - Private Helper Methods
    
    private static func extractTitle(from document: Document) throws -> String {
        let titleSelectors = [
            "h1.legal-title",
            ".document-title",
            "[itemprop='headline']",
            "meta[property='og:title']",
            ".case-title"
        ]
        
        for selector in titleSelectors {
            if selector.contains("meta") {
                if let title = try document.select(selector).first()?.attr("content"),
                   !title.isEmpty {
                    return title
                }
            } else {
                if let title = try document.select(selector).first()?.text(),
                   !title.isEmpty {
                    return title
                }
            }
        }
        
        throw ParsingError.missingRequiredField("title")
    }
    
    private static func extractDocumentType(from document: Document) throws -> String? {
        let typeSelectors = [
            ".document-type",
            "[itemprop='documentType']",
            ".legal-type"
        ]
        
        for selector in typeSelectors {
            if let typeText = try document.select(selector).first()?.text() {
                let normalizedText = typeText.lowercased()
                // Try to match based on keywords
                switch normalizedText {
                case let text where text.contains("bill"):
                    return "Bill"
                case let text where text.contains("ruling"):
                    return "Court Ruling"
                case let text where text.contains("order"):
                    return "Executive Order"
                case let text where text.contains("regulation"):
                    return "Regulation"
                case let text where text.contains("statute"):
                    return "Statute"
                default:
                    continue
                }
            }
        }
        
        return nil
    }
    
    private static func extractCaseNumber(from document: Document) throws -> String? {
        let caseNumberSelectors = [
            ".case-number",
            ".docket-number",
            "[itemprop='caseNumber']",
            ".legal-identifier",
            "meta[property='legal:caseNumber']"
        ]
        
        for selector in caseNumberSelectors {
            if selector.contains("meta") {
                if let caseNumber = try document.select(selector).first()?.attr("content"),
                   !caseNumber.isEmpty {
                    return caseNumber
                }
            } else {
                if let caseNumber = try document.select(selector).first()?.text(),
                   !caseNumber.isEmpty {
                    return caseNumber
                }
            }
        }
        
        return nil
    }
    
    private static func extractFilingDate(from document: Document) throws -> Date? {
        let dateSelectors = [
            "meta[property='article:published_time']",
            "[itemprop='datePublished']",
            ".filing-date",
            ".document-date",
            "time[datetime]"
        ]
        
        for selector in dateSelectors {
            if let dateStr = try document.select(selector).first()?.attr(selector.contains("meta") ? "content" : "datetime") {
                for formatter in [DateFormatter.iso8601Full, DateFormatter.iso8601, DateFormatter.standardDate] {
                    if let date = formatter.date(from: dateStr) {
                        return date
                    }
                }
            }
        }
        
        return nil
    }
    
    private static func extractDocumentURL(from document: Document) throws -> String? {
        let urlSelectors = [
            "meta[property='og:url']",
            "link[rel='canonical']",
            "[itemprop='url']"
        ]
        
        for selector in urlSelectors {
            if let url = try document.select(selector).first()?.attr(selector.contains("meta") ? "content" : "href"),
               !url.isEmpty {
                return url
            }
        }
        
        return nil
    }
} 