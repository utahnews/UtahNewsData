//
//  SupabaseDate.swift
//  UtahNewsData
//
//  Robust ISO 8601 parsing for Postgres `timestamptz` values served by
//  PostgREST. PostgREST preserves stored sub-second precision, so the same
//  column can return whole-second ("2026-06-29T20:19:40+00:00") for some rows
//  and microseconds ("2026-06-29T19:01:58.625637+00:00") for others. A bare
//  `ISO8601DateFormatter()` parses the former but returns nil for the latter,
//  while a formatter WITH `.withFractionalSeconds` does the opposite. Neither
//  covers both — so fractional timestamps silently collapsed to `Date()`.
//
//  Try the fractional formatter first, then fall back to the plain one.
//

import Foundation

/// Flexible ISO 8601 / RFC 3339 timestamp parsing for Supabase (Postgres
/// `timestamptz`) strings, tolerant of optional fractional seconds.
nonisolated enum SupabaseDate {
    // ISO8601DateFormatter is read-only after `formatOptions` is set and is
    // safe for concurrent `date(from:)` calls on modern Foundation; cache two
    // configured instances rather than allocating per call.
    nonisolated(unsafe) private static let fractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    nonisolated(unsafe) private static let plain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    /// Parse a Postgres `timestamptz` string, with or without fractional
    /// seconds. Returns `nil` only when the string is genuinely unparseable.
    nonisolated static func parse(_ string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        return fractional.date(from: string) ?? plain.date(from: string)
    }
}
