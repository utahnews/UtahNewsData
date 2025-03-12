/// The source of the parsed content
public enum ParsingSource {
    case htmlParsing
    case llmExtraction
}

/// The result of a parsing operation
public enum ParsingResult<T> {
    case success(T, source: ParsingSource)
    case failure(Error)
} 