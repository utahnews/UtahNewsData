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

        // 0. Decode HTML entities (Sprint AD.1 2026-05-18).
        // RSS feeds and AI-rewritten articles sometimes carry encoded
        // entities through to readers — &#8212; instead of an em dash,
        // &amp; instead of &. Decode here so the published body is
        // human-readable. Covers named + numeric (decimal + hex).
        result = decodeHTMLEntities(result)

        // 0b. Insert newlines at run-on word boundaries (Sprint AD.1 2026-05-18).
        // Some V2 HTML strips lose paragraph breaks between a heading
        // and the following list, producing "ASSOCIATIONCavaliers" or
        // "6Orioles" mid-paragraph. Split conservatively so headings
        // and score lists read naturally. Idempotent.
        result = splitRunOns(result)

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

        // 5b. Sprint 2026-05-12 — Article Quality Guardian.
        // Strip bracketed template / placeholder tokens that occasionally
        // leak from the drafter into final article text:
        //   [Image #15]  [Image 15]  [Figure 3]  [Caption 2]  [Photo 4]
        //   [Embed: ...] [Video #N]  [Audio #N]  [Sidebar]
        // These slipped past markdown sanitization because they aren't
        // markdown — they're prompt-leakage from upstream rendering.
        // Idempotent: safe to call on text that has none.
        result = replacePattern(
            in: result,
            pattern: "\\[(?:Image|Figure|Caption|Photo|Video|Audio|Embed|Sidebar|Pullquote|Pull Quote|Insert)(?:\\s*[#:]?\\s*\\d*)?\\s*\\]",
            with: ""
        )
        // Also strip any "Image #N" / "Figure N" without surrounding brackets
        // that snuck through (rarer, but observed in some LLM outputs).
        result = replacePattern(
            in: result,
            pattern: "(?<![A-Za-z])(?:Image|Figure|Caption|Photo)\\s*#\\s*\\d+(?![A-Za-z])",
            with: ""
        )

        // 6. Collapse 3+ consecutive newlines to exactly 2
        result = replacePattern(in: result, pattern: "\\n{3,}", with: "\n\n")

        // 7. Collapse 2+ consecutive spaces to a single space (within text)
        result = replacePattern(in: result, pattern: " {2,}", with: " ")

        // 8. Trim trailing whitespace per line
        result = replacePattern(in: result, pattern: "(?m)[ \\t]+$", with: "")

        // 9. Trim leading/trailing whitespace from entire text
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        return result
    }

    /// Body-variant sanitize that PRESERVES `## ` section headers
    /// (Sprint 2026-07-03 reader-skimmability).
    ///
    /// Article bodies now carry scannable section headers as lines beginning
    /// with `## ` — the platform's one sanctioned markdown construct,
    /// produced at save time from the generation schema's structured
    /// `subheading` field. Everything else (`#`/`###` strays, bold, links,
    /// bullets, entities, run-ons) is still cleaned exactly as `sanitize`
    /// does. Use THIS for article bodies; keep `sanitize` for titles,
    /// summaries, and key points, which must never contain headers.
    nonisolated public static func sanitizeBodyPreservingHeaders(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        // Protect the H2 markers with a private-use-area token that no real
        // news text contains, run the full standard pipeline, then restore.
        let token = "\u{E000}UNSECTION\u{E000}"
        var result = replacePattern(in: text, pattern: "(?m)^##[ \\t]+", with: token)
        result = sanitize(result)
        result = result.replacingOccurrences(of: token, with: "## ")
        return result
    }

    // MARK: - Private

    /// Common named HTML entities seen in news text.
    nonisolated private static let namedEntities: [String: String] = [
        "&amp;": "&",
        "&lt;": "<",
        "&gt;": ">",
        "&quot;": "\"",
        "&apos;": "'",
        "&nbsp;": " ",
        "&mdash;": "\u{2014}",  // —
        "&ndash;": "\u{2013}",  // –
        "&hellip;": "\u{2026}", // …
        "&lsquo;": "\u{2018}",  // '
        "&rsquo;": "\u{2019}",  // '
        "&ldquo;": "\u{201C}",  // "
        "&rdquo;": "\u{201D}",  // "
        "&laquo;": "\u{00AB}",  // «
        "&raquo;": "\u{00BB}",  // »
        "&bull;": "\u{2022}",   // •
        "&middot;": "\u{00B7}", // ·
        "&trade;": "\u{2122}",  // ™
        "&reg;": "\u{00AE}",    // ®
        "&copy;": "\u{00A9}",   // ©
        "&deg;": "\u{00B0}",    // °
        "&sect;": "\u{00A7}",   // §
        "&para;": "\u{00B6}",   // ¶
        "&plusmn;": "\u{00B1}", // ±
        "&times;": "\u{00D7}",  // ×
        "&divide;": "\u{00F7}", // ÷
    ]

    /// Decodes HTML entities — named (`&amp;`) and numeric (`&#8212;`,
    /// `&#x2014;`) — into their Unicode equivalents. Idempotent.
    nonisolated private static func decodeHTMLEntities(_ text: String) -> String {
        var result = text

        // Named entities — fast string replace.
        for (entity, replacement) in namedEntities where result.contains(entity) {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }

        // Numeric entities — decimal &#NNNN; then hex &#xHHHH;
        result = decodeNumericEntities(result, pattern: "&#(\\d{1,7});", radix: 10)
        result = decodeNumericEntities(result, pattern: "&#[xX]([0-9A-Fa-f]{1,6});", radix: 16)

        return result
    }

    nonisolated private static func decodeNumericEntities(_ text: String, pattern: String, radix: Int) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        guard !matches.isEmpty else { return text }

        // Walk in reverse so earlier match ranges remain valid as we splice.
        var result = text as NSString
        for match in matches.reversed() {
            guard match.numberOfRanges >= 2 else { continue }
            let numberStr = nsText.substring(with: match.range(at: 1))
            guard let codepoint = UInt32(numberStr, radix: radix),
                  let scalar = Unicode.Scalar(codepoint) else { continue }
            result = result.replacingCharacters(in: match.range, with: String(Character(scalar))) as NSString
        }
        return result as String
    }

    /// Inserts a newline at run-on boundaries left over from RSS-stripping
    /// passes: "ASSOCIATIONCavaliers" → "ASSOCIATION\nCavaliers",
    /// "6Orioles" → "6\nOrioles". Conservative — requires 3+ uppercase
    /// letters or a digit on the left, and Title-case on the right.
    nonisolated private static func splitRunOns(_ text: String) -> String {
        var result = text
        // Heading→TitleCase run-on (3+ caps avoids breaking "iPhone").
        result = replacePattern(
            in: result,
            pattern: "([A-Z]{3,})([A-Z][a-z])",
            with: "$1\n$2"
        )
        // Number→TitleCase run-on (scoreboard collapse).
        result = replacePattern(
            in: result,
            pattern: "(\\d)([A-Z][a-z])",
            with: "$1\n$2"
        )
        return result
    }

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
