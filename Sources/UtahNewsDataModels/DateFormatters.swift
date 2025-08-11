//
//  DateFormatters.swift
//  UtahNewsDataModels
//
//  Created by Mark Evans on 01/29/25
//
//  Summary: Shared date formatters for consistent date parsing across the models.

import Foundation

/// Shared DateFormatter instances for use across the codebase
public extension DateFormatter {
    /// DateFormatter for ISO8601 format with timezone (yyyy-MM-dd'T'HH:mm:ssZ)
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    /// DateFormatter for ISO8601 format without timezone (yyyy-MM-dd'T'HH:mm:ss)
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    /// DateFormatter for standard date format (yyyy-MM-dd)
    static let standardDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    /// DateFormatter for short date format (MMM d, yyyy)
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    /// DateFormatter for long date format (MMMM d, yyyy)
    static let longDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
}