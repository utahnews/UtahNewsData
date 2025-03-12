import Foundation
import SwiftSoup

extension Poll: HTMLParsable {
    public static func parse(from document: Document) throws -> Poll {
        let question = try extractQuestion(from: document)
        let options = try extractOptions(from: document)
        let dateConducted = try extractDateRange(from: document)
        let source = try extractSource(from: document)
        let margin = try extractMarginOfError(from: document)
        let sampleSize = try extractSampleSize(from: document)
        let demographics = try extractDemographics(from: document)
        
        return Poll(
            id: UUID().uuidString,
            question: question,
            options: options.map { PollOption(text: $0.text, votes: $0.votes) },
            dateConducted: dateConducted ?? Date(),
            source: source ?? "Unknown",
            marginOfError: margin,
            sampleSize: sampleSize,
            demographics: demographics?.description
        )
    }
    
    // MARK: - Private Helper Methods
    
    private static func extractQuestion(from document: Document) throws -> String {
        let questionSelectors = [
            "[itemprop='question']",
            ".poll-question",
            ".question-text",
            "meta[property='poll:question']"
        ]
        
        for selector in questionSelectors {
            if selector.contains("meta") {
                if let question = try document.select(selector).first()?.attr("content"),
                   !question.isEmpty {
                    return question
                }
            } else {
                if let question = try document.select(selector).first()?.text(),
                   !question.isEmpty {
                    return question
                }
            }
        }
        
        throw ParsingError.missingRequiredField("question")
    }
    
    private static func extractOptions(from document: Document) throws -> [InternalPollOption] {
        var options: [InternalPollOption] = []
        
        for selector in ["[itemprop='option']", ".poll-option", ".option"] {
            let elements = try document.select(selector)
            for element in elements {
                let textElement = try element.select("[itemprop='text']").first()
                let text: String
                if let textContent = try textElement?.text() {
                    text = textContent
                } else {
                    let optionTextElement = try element.select(".option-text").first()
                    if let optionTextContent = try optionTextElement?.text() {
                        text = optionTextContent
                    } else {
                        text = try element.text()
                    }
                }
                
                let votesElement = try element.select("[itemprop='votes']").first()
                let votesStr: String
                if let votesContent = try votesElement?.text() {
                    votesStr = votesContent
                } else {
                    let votesTextElement = try element.select(".votes").first()
                    if let votesTextContent = try votesTextElement?.text() {
                        votesStr = votesTextContent
                    } else {
                        votesStr = "0"
                    }
                }
                
                let votes = Int(votesStr.replacingOccurrences(of: ",", with: "")) ?? 0
                
                options.append(InternalPollOption(text: text, votes: votes))
            }
        }
        
        if options.isEmpty {
            throw ParsingError.missingRequiredField("options")
        }
        
        return options
    }
    
    private static func extractDateRange(from document: Document) throws -> Date? {
        let dateSelectors = [
            "[itemprop='datePublished']",
            ".poll-date",
            "meta[property='article:published_time']",
            ".survey-date"
        ]
        
        for selector in dateSelectors {
            if selector.contains("meta") {
                if let dateStr = try document.select(selector).first()?.attr("content"),
                   let date = DateFormatter.iso8601.date(from: dateStr) {
                    return date
                }
            } else {
                if let dateStr = try document.select(selector).first()?.text(),
                   let date = DateFormatter.standardDate.date(from: dateStr) {
                    return date
                }
            }
        }
        
        return nil
    }
    
    private static func extractSource(from document: Document) throws -> String? {
        let sourceSelectors = [
            "[itemprop='publisher']",
            ".poll-source",
            "meta[property='article:publisher']",
            ".survey-organization"
        ]
        
        for selector in sourceSelectors {
            if selector.contains("meta") {
                if let source = try document.select(selector).first()?.attr("content"),
                   !source.isEmpty {
                    return source
                }
            } else {
                if let source = try document.select(selector).first()?.text(),
                   !source.isEmpty {
                    return source
                }
            }
        }
        
        return nil
    }
    
    private static func extractMarginOfError(from document: Document) throws -> Double? {
        let marginSelectors = [
            "[itemprop='marginOfError']",
            ".margin-of-error",
            ".error-margin"
        ]
        
        for selector in marginSelectors {
            if let marginText = try document.select(selector).first()?.text() {
                let numberStr = marginText.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
                if let margin = Double(numberStr) {
                    return margin
                }
            }
        }
        
        return nil
    }
    
    private static func extractSampleSize(from document: Document) throws -> Int? {
        let sampleSizeSelectors = [
            "[itemprop='sampleSize']",
            ".sample-size",
            ".respondents"
        ]
        
        for selector in sampleSizeSelectors {
            if let sizeText = try document.select(selector).first()?.text() {
                let numberStr = sizeText.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                if let size = Int(numberStr) {
                    return size
                }
            }
        }
        
        return nil
    }
    
    private static func extractDemographics(from document: Document) throws -> [String: Double]? {
        let demographicSelectors = [
            "[itemprop='demographics'] li",
            ".demographics li",
            ".demographic-breakdown li"
        ]
        
        var demographics: [String: Double] = [:]
        
        for selector in demographicSelectors {
            let elements = try document.select(selector)
            for element in elements {
                let text = try element.text()
                let components = text.components(separatedBy: ":")
                if components.count == 2,
                   let percentage = Double(components[1].replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) {
                    demographics[components[0].trimmingCharacters(in: .whitespaces)] = percentage
                }
            }
            
            if !demographics.isEmpty {
                break
            }
        }
        
        return demographics.isEmpty ? nil : demographics
    }
}

// MARK: - Helper Types

private struct InternalPollOption {
    let text: String
    let votes: Int
} 