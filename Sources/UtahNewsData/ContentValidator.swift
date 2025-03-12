//
//  ContentValidator.swift
//  UtahNewsData
//
//  Created by Mark Evans on 3/21/24
//
//  Summary: Provides validation for parsed content to ensure quality and accuracy.

import Foundation

/// A utility class for validating content based on its type
public enum ContentValidator {
    /// Content types that can be validated
    public enum ContentType {
        case title
        case mainContent
        case author
        case date
        case image
        case category
    }
    
    /// Result of content validation
    public struct ValidationResult {
        public let isValid: Bool
        public let score: Double
        public let issues: [ValidationIssue]
        
        public init(isValid: Bool, score: Double, issues: [ValidationIssue] = []) {
            self.isValid = isValid
            self.score = score
            self.issues = issues
        }
    }
    
    /// Issue found during validation
    public struct ValidationIssue {
        public enum IssueType {
            case length
            case format
            case content
            case structure
            case metadata
        }
        
        public enum Severity {
            case warning
            case error
        }
        
        public let type: IssueType
        public let severity: Severity
        public let message: String
    }
    
    /// Validates content based on its type
    public static func validate(_ content: String, type: ContentType) -> ValidationResult {
        switch type {
        case .title:
            return validateTitle(content)
        case .mainContent:
            return validateMainContent(content)
        case .author:
            return validateAuthor(content)
        case .date:
            return validateDate(content)
        case .image:
            return validateImage(content)
        case .category:
            return validateCategory(content)
        }
    }
    
    // MARK: - Private Validation Methods
    
    private static func validateTitle(_ title: String) -> ValidationResult {
        var issues: [ValidationIssue] = []
        var score = 1.0
        
        // Check length
        if title.isEmpty {
            issues.append(ValidationIssue(
                type: .length,
                severity: .error,
                message: "Title cannot be empty"
            ))
            score -= 1.0
        } else if title.count < 5 {
            issues.append(ValidationIssue(
                type: .length,
                severity: .warning,
                message: "Title is very short"
            ))
            score -= 0.3
        } else if title.count > 200 {
            issues.append(ValidationIssue(
                type: .length,
                severity: .warning,
                message: "Title is very long"
            ))
            score -= 0.2
        }
        
        // Check format
        if title.uppercased() == title && title.count > 10 {
            issues.append(ValidationIssue(
                type: .format,
                severity: .warning,
                message: "Title is all uppercase"
            ))
            score -= 0.2
        }
        
        // Check content
        if title.contains("http") || title.contains("www.") {
            issues.append(ValidationIssue(
                type: .content,
                severity: .warning,
                message: "Title contains URLs"
            ))
            score -= 0.3
        }
        
        return ValidationResult(
            isValid: score > 0,
            score: max(0, score),
            issues: issues
        )
    }
    
    private static func validateMainContent(_ content: String) -> ValidationResult {
        var issues: [ValidationIssue] = []
        var score = 1.0
        
        // Check length
        if content.isEmpty {
            issues.append(ValidationIssue(
                type: .length,
                severity: .error,
                message: "Content cannot be empty"
            ))
            score -= 1.0
        } else if content.count < 100 {
            issues.append(ValidationIssue(
                type: .length,
                severity: .warning,
                message: "Content is very short"
            ))
            score -= 0.3
        }
        
        // Check structure
        let paragraphs = content.components(separatedBy: "\n\n")
        if paragraphs.count < 2 {
            issues.append(ValidationIssue(
                type: .structure,
                severity: .warning,
                message: "Content lacks proper paragraph structure"
            ))
            score -= 0.2
        }
        
        return ValidationResult(
            isValid: score > 0,
            score: max(0, score),
            issues: issues
        )
    }
    
    private static func validateAuthor(_ author: String) -> ValidationResult {
        var issues: [ValidationIssue] = []
        var score = 1.0
        
        // Check length
        if author.isEmpty {
            issues.append(ValidationIssue(
                type: .length,
                severity: .error,
                message: "Author cannot be empty"
            ))
            score -= 1.0
        }
        
        // Check format
        if author.uppercased() == author {
            issues.append(ValidationIssue(
                type: .format,
                severity: .warning,
                message: "Author name is all uppercase"
            ))
            score -= 0.2
        }
        
        return ValidationResult(
            isValid: score > 0,
            score: max(0, score),
            issues: issues
        )
    }
    
    private static func validateDate(_ dateString: String) -> ValidationResult {
        var issues: [ValidationIssue] = []
        var score = 1.0
        
        // Check if empty
        if dateString.isEmpty {
            issues.append(ValidationIssue(
                type: .length,
                severity: .error,
                message: "Date cannot be empty"
            ))
            score -= 1.0
            return ValidationResult(isValid: false, score: 0, issues: issues)
        }
        
        // Try to parse the date
        if DateFormatter.iso8601Full.date(from: dateString) == nil &&
           DateFormatter.iso8601.date(from: dateString) == nil &&
           DateFormatter.standardDate.date(from: dateString) == nil {
            issues.append(ValidationIssue(
                type: .format,
                severity: .error,
                message: "Invalid date format"
            ))
            score -= 1.0
        }
        
        return ValidationResult(
            isValid: score > 0,
            score: max(0, score),
            issues: issues
        )
    }
    
    private static func validateImage(_ url: String) -> ValidationResult {
        var issues: [ValidationIssue] = []
        var score = 1.0
        
        // Check if empty
        if url.isEmpty {
            issues.append(ValidationIssue(
                type: .length,
                severity: .error,
                message: "Image URL cannot be empty"
            ))
            score -= 1.0
        }
        
        // Check format
        if !url.hasPrefix("http") && !url.hasPrefix("https") {
            issues.append(ValidationIssue(
                type: .format,
                severity: .warning,
                message: "Image URL should start with http(s)"
            ))
            score -= 0.3
        }
        
        return ValidationResult(
            isValid: score > 0,
            score: max(0, score),
            issues: issues
        )
    }
    
    private static func validateCategory(_ category: String) -> ValidationResult {
        var issues: [ValidationIssue] = []
        var score = 1.0
        
        // Check length
        if category.isEmpty {
            issues.append(ValidationIssue(
                type: .length,
                severity: .error,
                message: "Category cannot be empty"
            ))
            score -= 1.0
        }
        
        // Check format
        if category.uppercased() == category {
            issues.append(ValidationIssue(
                type: .format,
                severity: .warning,
                message: "Category is all uppercase"
            ))
            score -= 0.2
        }
        
        return ValidationResult(
            isValid: score > 0,
            score: max(0, score),
            issues: issues
        )
    }
} 