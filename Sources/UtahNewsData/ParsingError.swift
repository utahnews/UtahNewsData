import Foundation

/// Errors that can occur during parsing
public enum ParsingError: Error, Equatable {
    case invalidType
    case invalidHTML
    case llmError(String)
    
    public static func == (lhs: ParsingError, rhs: ParsingError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidType, .invalidType):
            return true
        case (.invalidHTML, .invalidHTML):
            return true
        case (.llmError(let lhsMsg), .llmError(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
} 