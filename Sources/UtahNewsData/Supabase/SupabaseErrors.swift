//
//  SupabaseErrors.swift
//  UtahNewsData
//
//  Shared error types for Supabase operations. Centralized here so all
//  consumers (NewsCapture, V2PipelineTester, URLCapture, UtahNews) throw
//  consistent, inspectable error values.
//
//  Added in v1.12.0. Part of the SupabaseService consolidation plan —
//  see docs/CONSOLIDATION_PLAN.md for the broader roadmap.
//

import Foundation

// MARK: - Generic Supabase Errors

/// Common error cases shared across all consumer apps' Supabase services.
public nonisolated enum SupabaseError: LocalizedError, Sendable, Equatable {

    /// A requested item (processed item, article, queue entry, etc.) was not
    /// found. The associated value is the item identifier used in the lookup.
    case itemNotFound(String)

    /// The Supabase client failed to connect (network, auth, TLS, etc.).
    /// The associated value is a developer-facing description.
    case connectionFailed(String)

    /// A query executed but the server returned an error response.
    case queryFailed(String)

    /// An insert or update operation failed server-side.
    case writeFailed(String)

    /// The response body could not be decoded into the expected shape.
    /// Include the expected type name and the raw response preview.
    case decodingFailed(type: String, preview: String)

    /// The SHA-1 hash of a URL could not be computed. Rare; usually indicates
    /// an encoding issue upstream.
    case hashingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .itemNotFound(let id):
            return "Item not found in Supabase: \(id)"
        case .connectionFailed(let detail):
            return "Supabase connection failed: \(detail)"
        case .queryFailed(let detail):
            return "Supabase query failed: \(detail)"
        case .writeFailed(let detail):
            return "Supabase write failed: \(detail)"
        case .decodingFailed(let type, let preview):
            return "Failed to decode \(type) from Supabase response: \(preview)"
        case .hashingFailed(let input):
            return "Failed to hash URL: \(input)"
        }
    }
}

// MARK: - Update-Specific Errors

/// Errors from write operations that expect a specific post-write state.
///
/// Use when you UPDATE a row and then SELECT it back to verify the expected
/// state was applied (e.g., article status transitions, editorial queue
/// assignments). These validation failures usually indicate a missing row,
/// a server-side trigger overriding the intended state, or an RLS policy
/// preventing the write.
public nonisolated enum SupabaseUpdateError: LocalizedError, Sendable, Equatable {

    /// An UPDATE returned 0 affected rows. Either the ID doesn't exist or
    /// an RLS policy rejected the write silently.
    case noRowsAffected(entity: String, id: String)

    /// An UPDATE succeeded but the post-write SELECT returned a different
    /// value than requested (e.g., a database trigger overrode the state).
    case stateMismatch(entity: String, id: String, expected: String, actual: String)

    public var errorDescription: String? {
        switch self {
        case .noRowsAffected(let entity, let id):
            return "\(entity) update affected 0 rows for id=\(id). Row may not exist, or RLS blocked the write."
        case .stateMismatch(let entity, let id, let expected, let actual):
            return "\(entity) id=\(id): expected \(expected), got \(actual) after write. Trigger or validation override suspected."
        }
    }
}
