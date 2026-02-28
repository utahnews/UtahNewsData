//
//  CityNameNormalizer.swift
//  UtahNewsData
//
//  Normalizes messy city name values to clean, consistent format.
//  Handles prefixed formats (city_source:Lehi, domain:lehicity.org),
//  case variations, and abbreviations.
//
//  Shared utility used by NewsCapture, UtahNews, and V2PipelineTester.
//

import Foundation

/// Normalizes city name values to clean, title-cased format validated
/// against a canonical Utah city list.
///
/// Handles patterns found in existing data:
/// - `city_source:Lehi` -> `Lehi`
/// - `domain:www.taylorsvilleut.gov` -> `Taylorsville`
/// - `domain:slchamber.com` -> `Salt Lake City`
/// - `lehi` -> `Lehi`
/// - `american fork` -> `American Fork`
/// - `slc` -> `Salt Lake City`
public enum CityNameNormalizer: Sendable {

    // MARK: - Public API

    /// Normalize a raw city value to a clean, canonical city name.
    ///
    /// - Parameter rawValue: The messy city value (e.g., "city_source:Lehi", "domain:lehicity.org", "lehi")
    /// - Returns: The canonical city name if recognized, nil if not a valid Utah city
    nonisolated public static func normalize(_ rawValue: String?) -> String? {
        guard let rawValue, !rawValue.isEmpty else { return nil }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Pattern 1: "city_source:CityName" prefix
        if let city = extractFromCitySourcePrefix(trimmed) {
            return city
        }

        // Pattern 2: "domain:example.com" prefix
        if let city = extractFromDomainPrefix(trimmed) {
            return city
        }

        // Pattern 3: Direct city name or abbreviation lookup
        if let city = lookupCity(trimmed) {
            return city
        }

        return nil
    }

    /// Extract a city from a URL's domain
    nonisolated public static func cityFromURL(_ urlString: String) -> String? {
        guard let url = URL(string: urlString), let host = url.host?.lowercased() else {
            return nil
        }
        return resolveDomainToCity(host)
    }

    // MARK: - Private Helpers

    nonisolated private static func extractFromCitySourcePrefix(_ value: String) -> String? {
        let lower = value.lowercased()
        let prefixes = ["city_source:", "source:"]
        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                let cityPart = String(value.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return lookupCity(cityPart)
            }
        }
        return nil
    }

    nonisolated private static func extractFromDomainPrefix(_ value: String) -> String? {
        guard value.lowercased().hasPrefix("domain:") else { return nil }
        let domain = String(value.dropFirst("domain:".count))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return resolveDomainToCity(domain)
    }

    nonisolated private static func lookupCity(_ name: String) -> String? {
        let lower = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return cityLookup[lower]
    }

    nonisolated private static func resolveDomainToCity(_ domain: String) -> String? {
        let cleanDomain = domain.hasPrefix("www.") ? String(domain.dropFirst(4)) : domain

        // Check explicit domain map first
        if let city = domainToCityMap[cleanDomain] {
            return city
        }

        // University subdomains
        if cleanDomain.hasSuffix(".utah.edu") || cleanDomain == "utah.edu" {
            return "Salt Lake City"
        }
        if cleanDomain.hasSuffix(".byu.edu") || cleanDomain == "byu.edu" {
            return "Provo"
        }
        if cleanDomain.hasSuffix(".utahtech.edu") || cleanDomain == "utahtech.edu" {
            return "St. George"
        }
        if cleanDomain.hasSuffix(".weber.edu") || cleanDomain == "weber.edu" {
            return "Ogden"
        }
        if cleanDomain.hasSuffix(".usu.edu") || cleanDomain == "usu.edu" {
            return "Logan"
        }
        if cleanDomain.hasSuffix(".uvu.edu") || cleanDomain == "uvu.edu" {
            return "Orem"
        }
        if cleanDomain.hasSuffix(".snow.edu") || cleanDomain == "snow.edu" {
            return "Ephraim"
        }
        if cleanDomain.hasSuffix(".suu.edu") || cleanDomain == "suu.edu" {
            return "Cedar City"
        }

        // State government domains → Salt Lake City (capital)
        if cleanDomain.hasSuffix(".utah.gov") || cleanDomain == "utah.gov" {
            // Check for specific city subdomains first
            let parts = cleanDomain.split(separator: ".")
            if parts.count >= 3 {
                let subdomain = String(parts[0])
                if let city = lookupCity(subdomain) {
                    return city
                }
            }
            return "Salt Lake City"
        }

        // SLC schools
        if cleanDomain.hasSuffix(".slcschools.org") || cleanDomain == "slcschools.org" {
            return "Salt Lake City"
        }

        // Pattern: {city}city.org / {city}city.com / {city}ut.gov
        let govPatterns = ["city.org", "city.com", "ut.gov", "city.gov", "ut.org"]
        for suffix in govPatterns {
            if cleanDomain.hasSuffix(".\(suffix)") || cleanDomain == suffix {
                let withoutSuffix = cleanDomain.hasSuffix(".\(suffix)")
                    ? String(cleanDomain.dropLast(suffix.count + 1))
                    : String(cleanDomain.dropLast(suffix.count))
                let cityPart = withoutSuffix.replacingOccurrences(of: ".", with: "")
                if let city = lookupCity(cityPart) {
                    return city
                }
            }
        }

        // Pattern: cityof{name}.org
        if cleanDomain.hasPrefix("cityof") {
            let parts = cleanDomain.split(separator: ".")
            if let first = parts.first {
                let cityPart = String(first.dropFirst("cityof".count))
                if let city = lookupCity(cityPart) {
                    return city
                }
            }
        }

        return nil
    }

    // MARK: - Canonical Data

    /// Lowercase -> canonical city name mapping
    nonisolated private static let cityLookup: [String: String] = {
        var lookup: [String: String] = [:]
        for city in canonicalCities {
            lookup[city.lowercased()] = city
        }
        // Add abbreviations
        for (abbrev, city) in abbreviations {
            lookup[abbrev] = city
        }
        return lookup
    }()

    /// Common abbreviations for Utah cities
    nonisolated private static let abbreviations: [String: String] = [
        "slc": "Salt Lake City",
        "wvc": "West Valley City",
        "af": "American Fork",
        "pg": "Pleasant Grove",
        "sf": "Spanish Fork",
        "ssl": "South Salt Lake",
        "nsl": "North Salt Lake",
        "wj": "West Jordan",
        "sj": "South Jordan",
        "em": "Eagle Mountain",
        "ss": "Saratoga Springs",
        "bc": "Brigham City",
        "cc": "Cedar City",
        "sg": "St. George",
        "pc": "Park City",
    ]

    /// Explicit domain -> city mappings for known Utah domains
    nonisolated private static let domainToCityMap: [String: String] = [
        // Salt Lake City
        "slc.gov": "Salt Lake City",
        "slcgov.com": "Salt Lake City",
        "slchamber.com": "Salt Lake City",
        "slcpd.com": "Salt Lake City",
        "slcairport.com": "Salt Lake City",
        "visitsaltlake.com": "Salt Lake City",

        // Provo
        "provo.org": "Provo",
        "provo.gov": "Provo",

        // Ogden
        "ogdencity.com": "Ogden",
        "christmasvillage.ogdencity.com": "Ogden",
        "idlefree.ogdencity.com": "Ogden",

        // Logan
        "loganutah.org": "Logan",

        // St. George
        "stgeorgeutah.com": "St. George",
        "sgcity.org": "St. George",

        // Layton
        "layton.org": "Layton",
        "laytoncity.org": "Layton",

        // Taylorsville
        "taylorsvilleut.gov": "Taylorsville",

        // West Valley City
        "wvc-ut.gov": "West Valley City",
        "westvalleycity.org": "West Valley City",

        // Lehi
        "lehi-ut.gov": "Lehi",
        "lehicity.org": "Lehi",

        // American Fork
        "americanfork.gov": "American Fork",

        // Orem
        "orem.org": "Orem",

        // Spanish Fork
        "spanishfork.org": "Spanish Fork",

        // Springville
        "springville.org": "Springville",

        // Bountiful
        "bountifulutah.gov": "Bountiful",

        // Centerville
        "centerville.org": "Centerville",

        // Clearfield
        "clearfieldcity.org": "Clearfield",

        // Clinton
        "clintonmilitary.com": "Clinton",

        // Draper
        "draper.ut.us": "Draper",
        "drapercity.org": "Draper",

        // Farmington
        "farmingtonutah.org": "Farmington",

        // Fruit Heights
        "fruit-heights.com": "Fruit Heights",

        // Herriman
        "herriman.org": "Herriman",

        // Holladay
        "holladaycityut.org": "Holladay",

        // Kaysville
        "kaysville.com": "Kaysville",

        // Kearns
        "kearnsut.org": "Kearns",

        // Midvale
        "midvale.com": "Midvale",
        "midvalecity.org": "Midvale",

        // Millcreek
        "millcreek.us": "Millcreek",

        // North Ogden
        "northogdencity.com": "North Ogden",

        // North Salt Lake
        "northsaltlake.com": "North Salt Lake",

        // Pleasant Grove
        "pleasantgrove.org": "Pleasant Grove",

        // Payson
        "paysonutah.org": "Payson",

        // Riverton
        "riverton.utah.gov": "Riverton",

        // Roy
        "roycity.org": "Roy",

        // Eagle Mountain
        "eaglemountaincity.com": "Eagle Mountain",

        // Sandy
        "sandy.utah.gov": "Sandy",

        // Saratoga Springs
        "saratogaspringscity.com": "Saratoga Springs",

        // South Jordan
        "southjordanutah.org": "South Jordan",

        // South Ogden
        "southogdencity.com": "South Ogden",

        // Syracuse
        "syracuseut.com": "Syracuse",

        // Tooele
        "tooelecity.org": "Tooele",

        // West Jordan
        "westjordan.utah.gov": "West Jordan",

        // Woods Cross
        "woodscross.com": "Woods Cross",

        // Murray
        "murray.utah.gov": "Murray",

        // County-level
        "webercountyutah.gov": "Ogden",
        "utahcounty.gov": "Provo",
        "visitutah.com": "Salt Lake City",

        // Weber County subdomains
        "vote.utahcounty.gov": "Provo",
    ]

    /// Canonical Utah city names (proper title case)
    nonisolated private static let canonicalCities: [String] = [
        "Alpine",
        "American Fork",
        "Blanding",
        "Bluffdale",
        "Bountiful",
        "Brigham City",
        "Castle Dale",
        "Cedar City",
        "Cedar Hills",
        "Centerfield",
        "Centerville",
        "Clearfield",
        "Clinton",
        "Coalville",
        "Cottonwood Heights",
        "Delta",
        "Draper",
        "Duchesne",
        "Eagle Mountain",
        "Enoch",
        "Enterprise",
        "Ephraim",
        "Farmington",
        "Fillmore",
        "Fruit Heights",
        "Grantsville",
        "Green River",
        "Heber City",
        "Helper",
        "Herriman",
        "Highland",
        "Holladay",
        "Hurricane",
        "Hyrum",
        "Ivins",
        "Jensen",
        "Kanab",
        "Kaysville",
        "Kearns",
        "La Verkin",
        "Layton",
        "Lehi",
        "Lindon",
        "Logan",
        "Magna",
        "Manti",
        "Mapleton",
        "Marion",
        "Marriott-Slaterville",
        "Midvale",
        "Midway",
        "Millcreek",
        "Moab",
        "Morgan",
        "Murray",
        "Nephi",
        "North Logan",
        "North Ogden",
        "North Salt Lake",
        "Oakley",
        "Ogden",
        "Orem",
        "Park City",
        "Payson",
        "Perry",
        "Plain City",
        "Pleasant Grove",
        "Pleasant View",
        "Price",
        "Providence",
        "Provo",
        "Richfield",
        "Riverton",
        "Roosevelt",
        "Roy",
        "Salem",
        "Salt Lake City",
        "Sandy",
        "Santa Clara",
        "Santaquin",
        "Saratoga Springs",
        "Smithfield",
        "South Jordan",
        "South Ogden",
        "South Salt Lake",
        "Spanish Fork",
        "Spring City",
        "Springville",
        "St. George",
        "Stansbury Park",
        "Sunset",
        "Syracuse",
        "Taylorsville",
        "Tooele",
        "Tremonton",
        "Tropic",
        "Vernal",
        "Vineyard",
        "Wales",
        "Washington",
        "Washington Terrace",
        "Wellsville",
        "Wellington",
        "West Haven",
        "West Jordan",
        "West Point",
        "West Valley City",
        "Wolf Creek",
        "Woodland",
        "Woodland Hills",
        "Woods Cross",
    ]
}
