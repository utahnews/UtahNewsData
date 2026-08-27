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

    /// Produce the canonical **slug id** for a canonical Utah city NAME, reproducing
    /// `pipeline.app_cities.id` byte-for-byte (migration 292):
    ///   `lower(regexp_replace(city_name, '[^A-Za-z0-9]+', '-', 'g'))`
    ///
    /// Each maximal run of non-`[A-Za-z0-9]` collapses to a single `-`; replace-then-lower,
    /// and (matching the DB) NO edge trim — every canonical Utah city name slugs clean, so
    /// no leading/trailing hyphen arises in practice (verified: 0 mismatches across 321 names).
    ///
    /// Reproduces the RULE, not catalog membership — pass a *canonical* display name from
    /// `app_cities` / `CityRegistry`, not arbitrary/messy input. For messy input, run
    /// ``normalize(_:)`` first, then `slug(_:)` on its result.
    ///
    /// - Example: `slug("St. George")` -> `"st-george"`, `slug("Salt Lake City")` -> `"salt-lake-city"`.
    nonisolated public static func slug(_ name: String) -> String {
        // Regex-free equivalent of lower(regexp_replace(name, '[^A-Za-z0-9]+', '-', 'g')):
        // collapse each maximal run of non-ASCII-alphanumeric to a single '-', no edge trim.
        var out = ""
        var pendingDash = false
        for scalar in name.unicodeScalars {
            let isAlnum = (scalar >= "A" && scalar <= "Z")
                || (scalar >= "a" && scalar <= "z")
                || (scalar >= "0" && scalar <= "9")
            if isAlnum {
                out.unicodeScalars.append(scalar)
                pendingDash = false
            } else if !pendingDash {
                out.append("-")
                pendingDash = true
            }
        }
        return out.lowercased()
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
        // Sprint BT (2026-06-11): "Utah City" is the 700-acre development on
        // the former Geneva Steel site INSIDE Vineyard — not an incorporated
        // municipality. As phase-1 coverage ramps up, FM extraction will emit
        // it as a location token; map it to its actual city.
        "utah city": "Vineyard",
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

        // 2026-08-27 (1.31.0): exact-VALUE aliases that already exist on the DB side
        // and had no Swift twin, so the two normalizers disagreed. Mirrored verbatim
        // from the live definitions — canonical spelling is the DB's own `name`:
        //   pipeline.tg_articles_alias_city_pregate  (migs 694/825/962)
        //   pipeline.tg_articles_canonicalize_city   (mig 694 §A3)
        // These are exact-value aliases on a city FIELD, never content-token matches.
        "mt. pleasant": "Mount Pleasant",
        "mt pleasant": "Mount Pleasant",
        "south salt lake city": "South Salt Lake",
        "west jordan city": "West Jordan",
        // Snyderville Basin / Summit Park are the unincorporated Summit County
        // communities the DB folds into Park City (mig 694 §B5).
        "summit park": "Park City",
        "snyderville": "Park City",
        "snyderville basin": "Park City",
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

    /// Canonical Utah city names (proper title case).
    ///
    /// **Provenance (2026-08-27, UtahNewsData 1.31.0).** Regenerated from the live
    /// `pipeline.canonical_municipalities` view (296 rows; mig 1080 =
    /// `canonical_city_names` minus `% County`), unioned with the previous
    /// hand-maintained 111-name list. Before this the list refused 188 of the DB's
    /// 296 municipalities — every one of them a declared `city_coverage_state`
    /// coverage target — which hard-refused source registration
    /// (`NewsSourceService`), the `add_city_source` copilot tool, the sports
    /// roundup lane, and the `SourceEditorView` city picker.
    ///
    /// Three DB rows are deliberately EXCLUDED because the view's only filter is
    /// `NOT ILIKE '% County'`, so it admits non-names:
    /// - `Eden/Liberty/Huntsville` — a slash-joined trio, not a city name. `Eden`
    ///   and `Huntsville` are separately canonical and both appear below.
    /// - `Antimony area` — an "… area" descriptor; `Antimony` itself is below.
    /// - `Beaver City` — a duplicate of `Beaver`, which is also in the view
    ///   (30-day `articles.cities[]`: Beaver 49 vs Beaver City 4).
    ///
    /// Three entries are Swift-only (`Marion`, `Wolf Creek`, `Woodland`) —
    /// unincorporated Summit/Weber-county places that are in NEITHER
    /// `canonical_city_names` nor `canonical_municipalities`. They are KEPT here and
    /// owed a DB migration; do not drop them to "match the DB".
    ///
    /// ⚠️ This is a hand-maintained allowlist standing in front of a live
    /// enumerator, and it WILL go stale again the next time the DB table is
    /// extended by hand (it has been, in migs 583/694/769/825/1080). The structural
    /// fix is to inject the catalogue at runtime the way
    /// `FeatureCityGate.resolve(leadCity:normalizedCity:municipalities:)` already
    /// does. `CityNameNormalizerTests.canonicalCitiesCountIsPinned` pins the count
    /// so the drift is loud rather than silent.
    nonisolated private static let canonicalCities: [String] = [
        "Alpine",
        "Alta",
        "Altamont",
        "Alton",
        "Amalga",
        "American Fork",
        "Annabella",
        "Antimony",
        "Apple Valley",
        "Aurora",
        "Ballard",
        "Bear River City",
        "Beaver",
        "Beryl",
        "Bicknell",
        "Big Water",
        "Blanding",
        "Bluff",
        "Bluffdale",
        "Bothwell",
        "Boulder",
        "Bountiful",
        "Brian Head",
        "Brigham City",
        "Brighton",
        "Bryce Canyon City",
        "Cannonville",
        "Castle Dale",
        "Castle Valley",
        "Cedar City",
        "Cedar Fort",
        "Cedar Highlands",
        "Cedar Hills",
        "Centerfield",
        "Centerville",
        "Central Valley",
        "Charleston",
        "Circleville",
        "Clarkston",
        "Clawson",
        "Clearfield",
        "Cleveland",
        "Clinton",
        "Coalville",
        "Copperton",
        "Corinne",
        "Cornish",
        "Cottonwood Heights",
        "Croydon",
        "Daniel",
        "Delta",
        "Deseret",
        "Deweyville",
        "Draper",
        "Duchesne",
        "Dugway",
        "Dutch John",
        "Eagle Mountain",
        "East Carbon",
        "Eastland",
        "Echo",
        "Eden",
        "Elk Ridge",
        "Elmo",
        "Elsinore",
        "Elwood",
        "Emery",
        "Emigration Canyon",
        "Enoch",
        "Enterprise",
        "Ephraim",
        "Erda",
        "Escalante",
        "Eskdale",
        "Eureka",
        "Fairfield",
        "Fairview",
        "Farmington",
        "Farr West",
        "Fayette",
        "Ferron",
        "Fielding",
        "Fillmore",
        "Fort Duchesne",
        "Fountain Green",
        "Francis",
        "Fruit Heights",
        "Garden City",
        "Garland",
        "Garrison",
        "Genola",
        "Glendale",
        "Glenwood",
        "Goshen",
        "Grantsville",
        "Green River",
        "Grouse Creek",
        "Gunnison",
        "Hanksville",
        "Hanna",
        "Harrisville",
        "Hatch",
        "Heber City",
        "Helper",
        "Henefer",
        "Henrieville",
        "Herriman",
        "Hideout",
        "Highland",
        "Hildale",
        "Hinckley",
        "Holden",
        "Holladay",
        "Honeyville",
        "Hooper",
        "Howell",
        "Huntington",
        "Huntsville",
        "Hurricane",
        "Hyde Park",
        "Hyrum",
        "Ibapah",
        "Independence",
        "Ivins",
        "Jensen",
        "Joseph",
        "Junction",
        "Kamas",
        "Kanab",
        "Kanarraville",
        "Kanosh",
        "Kaysville",
        "Kearns",
        "Kingston",
        "Koosharem",
        "La Sal",
        "La Verkin",
        "Lake Point",
        "Lake Powell",
        "Laketown",
        "Lapoint",
        "Layton",
        "Leamington",
        "Leeds",
        "Lehi",
        "Levan",
        "Lewiston",
        "Lindon",
        "Loa",
        "Logan",
        "Lyman",
        "Lynndyl",
        "Maeser",
        "Magna",
        "Manila",
        "Manti",
        "Mantua",
        "Mapleton",
        "Marion",  // Swift-only: absent from pipeline.canonical_city_names — owed a DB migration
        "Marriott-Slaterville",
        "Marysvale",
        "Mayfield",
        "Meadow",
        "Mendon",
        "Midvale",
        "Midway",
        "Milford",
        "Millcreek",
        "Millville",
        "Minersville",
        "Moab",
        "Mona",
        "Monroe",
        "Montezuma Creek",
        "Monticello",
        "Monument Valley",
        "Morgan",
        "Moroni",
        "Mount Pleasant",
        "Mountain Green",
        "Murray",
        "Myton",
        "Naples",
        "Navajo Mountain",
        "Neola",
        "Nephi",
        "New Harmony",
        "Newton",
        "Nibley",
        "North Logan",
        "North Ogden",
        "North Salt Lake",
        "Oak City",
        "Oakley",
        "Ogden",
        "Orangeville",
        "Orderville",
        "Orem",
        "Panguitch",
        "Paradise",
        "Paragonah",
        "Park City",
        "Park Valley",
        "Parowan",
        "Payson",
        "Penrose",
        "Perry",
        "Peterson",
        "Pinnacle",
        "Plain City",
        "Pleasant Grove",
        "Pleasant View",
        "Plymouth",
        "Portage",
        "Porterville",
        "Price",
        "Providence",
        "Provo",
        "Randolph",
        "Redmond",
        "Richfield",
        "Richmond",
        "River Heights",
        "Riverdale",
        "Riverton",
        "Rockville",
        "Rocky Ridge",
        "Roosevelt",
        "Roy",
        "Rush Valley",
        "Salem",
        "Salina",
        "Salt Lake City",
        "Sandy",
        "Santa Clara",
        "Santaquin",
        "Saratoga Springs",
        "Scipio",
        "Scofield",
        "Sigurd",
        "Smithfield",
        "Snowville",
        "South Jordan",
        "South Ogden",
        "South Salt Lake",
        "South Weber",
        "Spanish Fork",
        "Spring City",
        "Springdale",
        "Springville",
        "St. George",
        "Stansbury Park",
        "Sterling",
        "Stockton",
        "Sunnyside",
        "Sunset",
        "Syracuse",
        "Tabiona",
        "Taylor",
        "Taylorsville",
        "Teasdale",
        "Thompson Springs",
        "Ticaboo",
        "Tooele",
        "Toquerville",
        "Torrey",
        "Tremonton",
        "Trenton",
        "Tropic",
        "Trout Creek",
        "Uintah",
        "Vernal",
        "Vernon",
        "Vineyard",
        "Virgin",
        "Wales",
        "Wallsburg",
        "Washington",
        "Washington Terrace",
        "Wellington",
        "Wellsville",
        "Wendover",
        "West Bountiful",
        "West Haven",
        "West Jordan",
        "West Point",
        "West Valley City",
        "West Weber",
        "White City",
        "Whiterocks",
        "Willard",
        "Wolf Creek",  // Swift-only: absent from pipeline.canonical_city_names — owed a DB migration
        "Woodland",  // Swift-only: absent from pipeline.canonical_city_names — owed a DB migration
        "Woodland Hills",
        "Woodruff",
        "Woods Cross",
    ]

    /// Internal test hook: the canonical municipality catalogue this type validates against.
    ///
    /// `@testable import` cannot see `private`, and `CityNameNormalizerCatalogTests` has to
    /// pin `canonicalCities.count` against `pipeline.canonical_municipalities` so that the
    /// next hand-extension of that DB table trips a red test instead of silently re-opening
    /// the 188-town refusal gap this list carried until 1.31.0. Internal on purpose — this
    /// is not public API, and callers must go through `normalize(_:)`.
    nonisolated static var canonicalCityCatalog: [String] { canonicalCities }
}
