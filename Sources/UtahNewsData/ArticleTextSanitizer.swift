//
//  ArticleTextSanitizer.swift
//  UtahNewsData
//
//  Strips markdown formatting, normalizes whitespace, and cleans
//  AI-generated article text for plain-text display in consumer apps.
//

import Foundation

public enum ArticleTextSanitizer: Sendable {

    /// Sanitizes article text by removing markdown formatting and normalizing whitespace.
    /// Safe to call on already-clean text (idempotent).
    nonisolated public static func sanitize(_ text: String) -> String {
        guard !text.isEmpty else { return text }

        var result = text

        // 1. Strip markdown headers (## Title -> Title)
        result = replacePattern(in: result, pattern: "(?m)^#{1,6}\\s+", with: "")

        // 2. Remove bold markers (**text** -> text)
        result = replacePattern(in: result, pattern: "\\*\\*(.+?)\\*\\*", with: "$1")

        // 3. Convert markdown links [text](url) -> text
        result = replacePattern(in: result, pattern: "\\[([^\\]]+)\\]\\([^)]+\\)", with: "$1")

        // 4. Remove bullet markers at line start (- item or * item)
        result = replacePattern(in: result, pattern: "(?m)^[*\\-]\\s+", with: "")

        // 5. Strip backtick code formatting (`code` -> code)
        result = replacePattern(in: result, pattern: "`([^`]+)`", with: "$1")

        // 6. Collapse 3+ consecutive newlines to exactly 2
        result = replacePattern(in: result, pattern: "\\n{3,}", with: "\n\n")

        // 7. Trim trailing whitespace per line
        result = replacePattern(in: result, pattern: "(?m)[ \\t]+$", with: "")

        // 8. Trim leading/trailing whitespace from entire text
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        return result
    }

    // MARK: - Private

    nonisolated private static func replacePattern(
        in text: String,
        pattern: String,
        with replacement: String
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: replacement)
    }
}
