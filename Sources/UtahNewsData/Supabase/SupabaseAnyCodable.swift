//
//  SupabaseAnyCodable.swift
//  UtahNewsData
//
//  Type-erased Codable wrapper for JSONB columns in Supabase.
//  Used for flexible fields like submissionContext, editorialSignals,
//  confidenceScores, and structuredData.
//
//  Previously duplicated across V2PipelineTester, NewsCapture, and URLCapture.
//  Now consolidated here as the single source of truth.
//

import Foundation

/// Type-erased `Codable` container for Supabase JSONB columns.
///
/// Handles encoding/decoding of heterogeneous JSON values (strings, numbers,
/// booleans, nested objects, arrays, and null).
public struct SupabaseAnyCodable: Codable, Sendable, Hashable {
    public let value: any Sendable

    public init(_ value: any Sendable) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let dict = try? container.decode([String: SupabaseAnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else if let array = try? container.decode([SupabaseAnyCodable].self) {
            value = array.map { $0.value }
        } else {
            value = Optional<String>.none as any Sendable
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let dict as [String: any Sendable]:
            try container.encode(dict.mapValues { SupabaseAnyCodable($0) })
        case let array as [any Sendable]:
            try container.encode(array.map { SupabaseAnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }

    // MARK: - Hashable

    public static func == (lhs: SupabaseAnyCodable, rhs: SupabaseAnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case (let l as String, let r as String): return l == r
        case (let l as Int, let r as Int): return l == r
        case (let l as Double, let r as Double): return l == r
        case (let l as Bool, let r as Bool): return l == r
        default: return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch value {
        case let string as String: hasher.combine(string)
        case let int as Int: hasher.combine(int)
        case let double as Double: hasher.combine(double)
        case let bool as Bool: hasher.combine(bool)
        default: hasher.combine(0)
        }
    }
}
