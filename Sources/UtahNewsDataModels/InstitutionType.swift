//
//  InstitutionType.swift
//  UtahNewsDataModels
//
//  Represents a category of public institution (e.g., "Elementary School",
//  "Police Department") used for measuring city-level source coverage.
//

import Foundation

/// A category of public institution that produces community-relevant information.
///
/// Institution types are enumerable categories (schools, government offices, etc.)
/// used to measure whether the platform has source coverage for the essential
/// organizations in each city.
public struct InstitutionType: Identifiable, Codable, Hashable, Sendable {
    /// Unique identifier (e.g., "elementary_school", "police_department")
    public let id: String
    /// Human-readable name (e.g., "Elementary School")
    public let name: String
    /// Maps to `NewsSourceCategory` (e.g., "education", "publicSafety")
    public let category: String
    /// Types of data this institution is expected to produce
    public let expectedDataTypes: [String]
    /// 1 = foundational, 2 = important, 3 = nice-to-have
    public let priority: Int
    /// Hint for how to discover instances of this type
    public let discoveryHint: String?

    enum CodingKeys: String, CodingKey {
        case id, name, category, priority
        case expectedDataTypes = "expected_data_types"
        case discoveryHint = "discovery_hint"
    }

    public init(
        id: String,
        name: String,
        category: String,
        expectedDataTypes: [String] = [],
        priority: Int = 2,
        discoveryHint: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.expectedDataTypes = expectedDataTypes
        self.priority = priority
        self.discoveryHint = discoveryHint
    }
}
