//
//  CityCoverageSummary.swift
//  UtahNewsDataModels
//
//  Aggregated institutional coverage statistics for a city.
//  Maps to the city_coverage_summary view in Supabase.
//

import Foundation

/// Aggregated institutional coverage statistics for a single city.
///
/// This maps to the `city_coverage_summary` Supabase view which joins
/// `city_institutions` with `institution_types` to produce per-city metrics.
public struct CityCoverageSummary: Codable, Hashable, Sendable {
    /// City name
    public let cityName: String
    /// Total tracked institutions in this city
    public let totalInstitutions: Int
    /// Institutions with status "connected" or "verified"
    public let connectedCount: Int
    /// Institutions with status "verified" (actively producing data)
    public let verifiedCount: Int
    /// Institutions with status "missing" (known gap)
    public let missingCount: Int
    /// Percentage of institutions that are connected or verified
    public let coveragePct: Double?
    /// Names of institution types that have no entries
    public let missingTypes: [String]?

    enum CodingKeys: String, CodingKey {
        case cityName = "city_name"
        case totalInstitutions = "total_institutions"
        case connectedCount = "connected_count"
        case verifiedCount = "verified_count"
        case missingCount = "missing_count"
        case coveragePct = "coverage_pct"
        case missingTypes = "missing_types"
    }

    public init(
        cityName: String,
        totalInstitutions: Int,
        connectedCount: Int,
        verifiedCount: Int,
        missingCount: Int,
        coveragePct: Double? = nil,
        missingTypes: [String]? = nil
    ) {
        self.cityName = cityName
        self.totalInstitutions = totalInstitutions
        self.connectedCount = connectedCount
        self.verifiedCount = verifiedCount
        self.missingCount = missingCount
        self.coveragePct = coveragePct
        self.missingTypes = missingTypes
    }
}
