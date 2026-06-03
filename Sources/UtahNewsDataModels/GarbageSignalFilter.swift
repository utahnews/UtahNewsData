//
//  GarbageSignalFilter.swift
//  UtahNewsDataModels
//
//  Sprint AB Phase 1a (2026-05-17).
//
//  Shared garbage-detection logic for signal-tier content (link-out cards,
//  RSS direct ingest, anywhere we need to filter homepage / section-page /
//  placeholder titles before publishing).
//
//  Previously duplicated across V2's LinkOutCardPublisherService and
//  RSSDirectIngestionService. Single source of truth now so V2 and the
//  new NC link-out card publisher (Sprint AB Phase 3) apply identical
//  rules without drift.
//

import Foundation

/// Detects garbage signal-tier content that shouldn't surface as a
/// reader-visible card or article. Returns `nil` if content is clean,
/// or a human-readable reason string explaining why it was rejected
/// (suitable for logging + audit trails).
///
/// All checks are conservative — false negatives (real headlines marked
/// garbage) hurt coverage; false positives (homepage hits marked clean)
/// pollute the reader feed. Tune for false-negative direction.
public enum GarbageSignalFilter: Sendable {

    /// Hardcoded display-name map for major Utah outlets. Used by
    /// `outletDisplayName(for:)` so callers don't each maintain their own
    /// copy. Domains that aren't in this map fall back to the stripped host.
    ///
    /// Future improvement: join against `rss_only_sources.display_name`
    /// when the domain is registered there. For now, this covers the
    /// canonical outlets that produce the bulk of signal volume.
    public static let outletDisplayNames: [String: String] = [
        "fox13now.com": "Fox 13",
        "abc4.com": "ABC 4",
        "ksl.com": "KSL",
        "ksltv.com": "KSL",
        "sltrib.com": "Salt Lake Tribune",
        "deseret.com": "Deseret News",
        "deseretnews.com": "Deseret News",
        "lehifreepress.com": "Lehi Free Press",
        "parkrecord.com": "Park Record",
        "utahnewsdispatch.com": "Utah News Dispatch",
        "kjzz.com": "KJZZ",
        "kutv.com": "KUTV",
        "kuer.org": "KUER",
        "etvnewsutah.com": "ETV News"
    ]

    /// Returns a human-readable outlet name for a URL. Falls back to the
    /// stripped host if the domain isn't in `outletDisplayNames`.
    public static func outletDisplayName(for urlString: String) -> String {
        guard let host = URL(string: urlString)?.host else { return urlString }
        let stripped = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        return outletDisplayNames[stripped] ?? stripped
    }

    /// Evaluates a signal-tier title + snippet pair. Returns `nil` if the
    /// content is clean and worth publishing, or a short reason string
    /// describing the failure (logged + persisted for editorial audits).
    ///
    /// - Parameters:
    ///   - title: The headline as extracted from the outlet.
    ///   - snippet: The body / summary text (may be empty).
    ///   - sourceURL: The article URL — used to detect "title equals
    ///     bare domain" homepage hits.
    public static func garbageReason(title rawTitle: String, snippet: String, sourceURL: String) -> String? {
        let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        // Upstream placeholder titles from signal_only ingest that escaped.
        let placeholders: Set<String> = [
            "Signal-only (news outlet)",
            "No title available",
            "Untitled",
            ""
        ]
        if placeholders.contains(title) {
            return "placeholder title"
        }

        // Bare outlet name → homepage hit.
        let outletName = outletDisplayName(for: sourceURL)
        if let host = URL(string: sourceURL)?.host {
            let stripped = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
            let lowered = title.lowercased()
            if lowered == stripped.lowercased() || lowered == outletName.lowercased() {
                return "title is bare outlet name → homepage"
            }
        }

        // Section / category page: "Opinion - <Outlet>", "Latest - <Outlet>",
        // "News - <Outlet>", "Sports - <Outlet>". Strip the outlet suffix and
        // check what's left.
        let suffixPatterns = [
            " - \(outletName)",
            " — \(outletName)",   // em-dash
            " | \(outletName)"     // pipe
        ]
        let sectionWords: Set<String> = [
            "opinion", "opinions", "latest", "news", "sports",
            "local government", "obituaries", "weather", "video", "podcast",
            "newsletters", "newsletter", "briefing", "subscribe",
            "sections", "categories", "topics", "archives", "tag",
            "about", "contact", "advertise", "home", "search",
            // Sprint BM — institutional/library/nav landing pages.
            "services", "library", "programs", "classes", "staff", "directory",
            "resources", "collections", "events", "calendar", "hours",
            "locations", "documents", "forms", "makerspace", "printing",
            "clubs", "departments", "agendas", "minutes", "meetings",
            "notices", "alerts", "faq", "faqs", "menu"
        ]
        for suffix in suffixPatterns where title.hasSuffix(suffix) {
            let core = String(title.dropLast(suffix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            if sectionWords.contains(core.lowercased()) {
                return "section page (\(core))"
            }
            // "Latest budget proposal..." is fine; only reject when the core
            // IS the section word, not when it merely starts with one.
        }

        // Sprint BM — institutional nav/landing pages use a "Section | Institution"
        // title template that V2 frequently mis-types as an article, e.g.
        // "Makerspace | Ephraim Library", "Home | Lake Mountain School District",
        // "Meetings | Rush Valley Town". This MIRRORS pipeline.is_non_news_page
        // Rule 10b (mig 276) — keep the two in sync. PIPE-ONLY by design: real
        // feature headlines never use " | " (verified 0 false-positives across
        // 152 AI + 106 primary-source news titles), whereas em-dash/hyphen DO
        // appear in real headlines, so they are deliberately excluded.
        if let pipeRange = title.range(of: " | ") {
            let prefix = String(title[title.startIndex..<pipeRange.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let suffix = String(title[pipeRange.upperBound...])
            let institutionWords =
                #"\b(librar(y|ies)|schools?|district|city|town|county|department|museum|cent(er|re)|academy|college|university|elementary|middle|high school|recreation|parks?|office|court|cemetery|government|fire|police|water|sewer)\b"#
            let prefixIsShort = !prefix.isEmpty && prefix.count <= 40
            let suffixIsInstitution = suffix.range(
                of: institutionWords,
                options: [.regularExpression, .caseInsensitive]
            ) != nil
            if prefixIsShort || suffixIsInstitution {
                return "institution nav page (pipe template)"
            }
        }

        // Title too short to be a real headline.
        if title.count < 12 {
            return "title too short (<12 chars)"
        }

        // Homepage tagline patterns. Common shapes:
        //   "Utah Breaking News, Top Stories & Sports"           (ksl.com)
        //   "KSL NewsRadio 102.7 FM: Utah News, Weather, Traffic" (kslnewsradio)
        //   "Latest news, weather, traffic..."                    (various)
        // The outlet's nav/SEO title, not an article headline.
        let homepageMarkers = [
            "top stories",
            "breaking news",
            "weather, traffic",
            "weather and traffic",
            "news, weather",
            "newsradio",     // "KSL NewsRadio 102.7 FM:" prefix
            "fm:"             // radio-station homepage colon
        ]
        let lowered = title.lowercased()
        let homepageHits = homepageMarkers.filter { lowered.contains($0) }.count
        if homepageHits >= 2 {
            return "homepage tagline (>=2 markers)"
        }
        if homepageHits >= 1 && snippet.count < 100 {
            return "homepage tagline + thin body"
        }

        // No usable summary AND title doesn't carry enough by itself.
        if snippet.isEmpty && title.count < 30 {
            return "empty snippet and thin title"
        }

        return nil
    }
}
