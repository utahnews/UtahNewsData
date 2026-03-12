//
//  CityInstitution.swift
//  UtahNewsDataModels
//
//  Represents a specific institution in a city (e.g., "Provo High School")
//  and tracks whether the platform has source coverage for it.
//

import Foundation

/// A specific institution instance within a city, linked to source coverage tracking.
///
/// Each record represents one real-world institution (a specific school, police
/// department, etc.) and tracks whether the platform has connected news sources.
public struct CityInstitution: Identifiable, Codable, Hashable, Sendable {
    /// Unique identifier (generated UUID)
    public let id: String
    /// City where this institution is located
    public let cityName: String
    /// Reference to the institution type
    public let institutionTypeId: String
    /// Name of this specific institution (e.g., "Sandy City Police")
    public let name: String
    /// Coverage status
    public let status: Status
    /// IDs of city_sources linked to this institution
    public let sourceIds: [String]
    /// Data types this institution is expected to produce
    public let expectedDataTypes: [String]
    /// Data types we're actually receiving
    public let verifiedDataTypes: [String]
    /// Canonical website URL
    public let websiteUrl: String?
    /// Free-form notes
    public let notes: String?
    /// When this institution was first discovered
    public let discoveredAt: Date?
    /// When coverage was last verified
    public let verifiedAt: Date?
    /// When we last checked this institution's status
    public let lastChecked: Date?

    public enum Status: String, Codable, Hashable, Sendable, CaseIterable {
        case discovered
        case connected
        case verified
        case stale
        case missing
    }

    enum CodingKeys: String, CodingKey {
        case id, name, status, notes
        case cityName = "city_name"
        case institutionTypeId = "institution_type_id"
        case sourceIds = "source_ids"
        case expectedDataTypes = "expected_data_types"
        case verifiedDataTypes = "verified_data_types"
        case websiteUrl = "website_url"
        case discoveredAt = "discovered_at"
        case verifiedAt = "verified_at"
        case lastChecked = "last_checked"
    }

    public init(
        id: String = UUID().uuidString,
        cityName: String,
        institutionTypeId: String,
        name: String,
        status: Status = .discovered,
        sourceIds: [String] = [],
        expectedDataTypes: [String] = [],
        verifiedDataTypes: [String] = [],
        websiteUrl: String? = nil,
        notes: String? = nil,
        discoveredAt: Date? = nil,
        verifiedAt: Date? = nil,
        lastChecked: Date? = nil
    ) {
        self.id = id
        self.cityName = cityName
        self.institutionTypeId = institutionTypeId
        self.name = name
        self.status = status
        self.sourceIds = sourceIds
        self.expectedDataTypes = expectedDataTypes
        self.verifiedDataTypes = verifiedDataTypes
        self.websiteUrl = websiteUrl
        self.notes = notes
        self.discoveredAt = discoveredAt
        self.verifiedAt = verifiedAt
        self.lastChecked = lastChecked
    }
}
