import Foundation

/// Represents errors that can occur during HTML parsing
public enum ParsingError: Error, Equatable {
    /// Required field is missing from the HTML document
    case missingRequiredField(String)
    /// Invalid data format encountered
    case invalidFormat(String)
    /// Required element not found in the HTML document
    case elementNotFound(String)
    /// Error converting parsed data to expected type
    case conversionError(String)
    /// Generic parsing error with description
    case other(String)
    /// Invalid HTML document
    case invalidHTML
    
    /// Human-readable description of the error
    public var description: String {
        switch self {
        case .missingRequiredField(let field):
            return "Required field missing: \(field)"
        case .invalidFormat(let details):
            return "Invalid data format: \(details)"
        case .elementNotFound(let selector):
            return "Element not found: \(selector)"
        case .conversionError(let details):
            return "Data conversion error: \(details)"
        case .other(let message):
            return message
        case .invalidHTML:
            return "Invalid HTML document"
        }
    }
} 