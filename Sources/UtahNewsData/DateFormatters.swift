//
//  DateFormatters.swift
//  UtahNewsData
//
//  Created by Mark Evans on 3/21/24
//
//  Summary: Shared date formatters for consistent date parsing across the app.

import Foundation

/// Extension providing standard date formatters for use across the app
public extension DateFormatter {
    /// ISO 8601 formatter with full date and time (yyyy-MM-dd'T'HH:mm:ssZ)
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    /// ISO 8601 formatter with basic date and time (yyyy-MM-dd'T'HH:mm:ss)
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    /// Standard date formatter (yyyy-MM-dd)
    static let standardDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
} 