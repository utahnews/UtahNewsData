//
//  CityNameNormalizerCatalogTests.swift
//  UtahNewsDataTests
//
//  THE DRIFT GUARD for `CityNameNormalizer.canonicalCities` (UtahNewsData 1.31.0, 2026-08-27).
//
//  WHY THIS FILE EXISTS
//  --------------------
//  `canonicalCities` is a hand-maintained allowlist standing in front of a live enumerator,
//  `pipeline.canonical_municipalities` (a view over the `canonical_city_names` table, filtered
//  `NOT ILIKE '% County'`; mig 1080). Until 1.31.0 the Swift list held 111 names and refused
//  188 of the DB's 296 municipalities — and every one of those 188 had a `city_coverage_state`
//  row, i.e. every one was a declared coverage target. The refusals were not cosmetic: five
//  call sites treat `normalize(_:) == nil` as a HARD refusal —
//
//    NewsCapture/.../NewsSourceService.swift:230              (source never registered)
//    NewsCapture/Services/AutomatedMultiSourceGenerationService.swift:784  (sports roundup never drafted)
//    NewsCapture/Services/EditorialCopilotService.swift:629   (`add_city_source` tool errors)
//    NewsCapture/View/NewsSourcesTab/SourceEditorView.swift:275 (picker never renders the option)
//    NewsCapture/Services/FeatureDraftingService.swift:287    (fixed separately by mig 1080)
//
//  — so a missing name produced no row at all, and was therefore invisible to every metric.
//
//  WHAT BREAKS IF YOU DELETE THESE TESTS
//  -------------------------------------
//  The DB table is hand-extended (migs 583, 694, 769, 825, 1080). The count assertion below is
//  the only thing that makes the NEXT extension loud. If it fails: re-run
//  `SELECT name FROM pipeline.canonical_municipalities ORDER BY name` and re-derive the list
//  under the exclusion rules documented on `canonicalCities` — do not just edit the number.
//
//  The structural fix (tracked, not done here) is to inject the catalogue at runtime the way
//  `FeatureCityGate.resolve(leadCity:normalizedCity:municipalities:)` already does; until then
//  this file is the accountability arm.
//

import Testing
@testable import UtahNewsData

struct CityNameNormalizerCatalogTests {

    // MARK: - The count pin

    /// Pinned against `SELECT count(*) FROM pipeline.canonical_municipalities` (296, live
    /// 2026-08-27) MINUS 3 non-name rows the view admits, PLUS 3 Swift-only towns the DB
    /// does not carry. 296 − 3 + 3 = 296. See `canonicalCities` for the full derivation.
    @Test("canonicalCities holds exactly 296 names")
    func canonicalCitiesCountIsPinned() {
        #expect(CityNameNormalizer.canonicalCityCatalog.count == 296)
    }

    @Test("canonicalCities has no duplicates")
    func canonicalCitiesHasNoDuplicates() {
        let all = CityNameNormalizer.canonicalCityCatalog
        #expect(Set(all).count == all.count)
    }

    @Test("canonicalCities has no case-folded duplicates either")
    func canonicalCitiesHasNoCaseFoldedDuplicates() {
        let all = CityNameNormalizer.canonicalCityCatalog
        #expect(Set(all.map { $0.lowercased() }).count == all.count)
    }

    // MARK: - The junk filter (the view's only filter is NOT ILIKE '% County')

    @Test("no catalogue entry is a slash-joined composite")
    func noSlashJoinedComposites() {
        let offenders = CityNameNormalizer.canonicalCityCatalog.filter { $0.contains("/") }
        #expect(offenders.isEmpty, "slash-joined composites are not city names: \(offenders)")
    }

    @Test("no catalogue entry is an '… area' descriptor")
    func noAreaDescriptors() {
        let offenders = CityNameNormalizer.canonicalCityCatalog.filter { $0.hasSuffix(" area") }
        #expect(offenders.isEmpty, "'… area' is a descriptor, not a city name: \(offenders)")
    }

    /// `Eden/Liberty/Huntsville`, `Antimony area` and `Beaver City` are in
    /// `canonical_municipalities` and are deliberately NOT here. `Eden`, `Huntsville`,
    /// `Antimony` and `Beaver` each stand on their own (30-day `articles.cities[]`:
    /// Beaver 49 vs Beaver City 4).
    @Test("the three excluded DB rows stay excluded, and their real names stay in")
    func excludedDBRowsStayExcluded() {
        let catalogue = Set(CityNameNormalizer.canonicalCityCatalog)
        for excluded in ["Eden/Liberty/Huntsville", "Antimony area", "Beaver City"] {
            #expect(!catalogue.contains(excluded), "\(excluded) must not be a canonical city")
            #expect(CityNameNormalizer.normalize(excluded) == nil)
        }
        for kept in ["Eden", "Huntsville", "Antimony", "Beaver"] {
            #expect(catalogue.contains(kept))
        }
    }

    // MARK: - The towns the 111-name list refused

    /// Named in the finding. All three carry live traffic and sit in tier C of
    /// `city_coverage_state`; all three returned nil before 1.31.0.
    @Test("the three towns named in the finding normalize to themselves")
    func townsNamedInTheFindingNormalize() {
        #expect(CityNameNormalizer.normalize("Alta") == "Alta")
        #expect(CityNameNormalizer.normalize("Springdale") == "Springdale")
        #expect(CityNameNormalizer.normalize("Dutch John") == "Dutch John")
    }

    /// The two highest-volume refusals by 30-day activity (Beaver 342 `processed_items` /
    /// 133 `articles.cities`; Kanosh 41 / 209).
    @Test("the highest-volume refused towns normalize to themselves")
    func highestVolumeRefusedTownsNormalize() {
        #expect(CityNameNormalizer.normalize("Beaver") == "Beaver")
        #expect(CityNameNormalizer.normalize("Kanosh") == "Kanosh")
    }

    @Test("previously-refused towns normalize case-insensitively too")
    func previouslyRefusedTownsAreCaseInsensitive() {
        #expect(CityNameNormalizer.normalize("alta") == "Alta")
        #expect(CityNameNormalizer.normalize("DUTCH JOHN") == "Dutch John")
        #expect(CityNameNormalizer.normalize("  kanosh  ") == "Kanosh")
    }

    // MARK: - The Swift-only entries must survive

    /// `Marion`, `Wolf Creek` and `Woodland` are unincorporated Summit/Weber-county places
    /// present in NEITHER `canonical_city_names` nor `canonical_municipalities`. A naive
    /// "replace the 111 with the DB's 296" would have DELETED them. They are owed a DB
    /// migration; until then this test is what keeps them alive.
    @Test("the three Swift-only towns still normalize")
    func swiftOnlyTownsStillNormalize() {
        #expect(CityNameNormalizer.normalize("Marion") == "Marion")
        #expect(CityNameNormalizer.normalize("Wolf Creek") == "Wolf Creek")
        #expect(CityNameNormalizer.normalize("Woodland") == "Woodland")
    }

    // MARK: - Pre-existing behaviour that must not regress

    @Test("the pre-1.31.0 aliases and prefix patterns still resolve")
    func legacyAliasesAndPrefixesStillResolve() {
        #expect(CityNameNormalizer.normalize("slc") == "Salt Lake City")
        #expect(CityNameNormalizer.normalize("utah city") == "Vineyard")
        #expect(CityNameNormalizer.normalize("wvc") == "West Valley City")
        #expect(CityNameNormalizer.normalize("city_source:Lehi") == "Lehi")
        #expect(CityNameNormalizer.normalize("domain:lehicity.org") == "Lehi")
    }

    @Test("a non-Utah value is still refused")
    func nonUtahValuesStillRefused() {
        #expect(CityNameNormalizer.normalize("Boise") == nil)
        #expect(CityNameNormalizer.normalize("") == nil)
        #expect(CityNameNormalizer.normalize(nil) == nil)
    }

    // MARK: - Aliases mirrored from the DB in 1.31.0

    /// Mirrored verbatim from `pipeline.tg_articles_alias_city_pregate` (migs 694/825/962)
    /// and `pipeline.tg_articles_canonicalize_city` (mig 694 §A3). Canonical spelling is the
    /// DB's own `name`. If you change one side, change the other in the same push.
    @Test("the DB's municipality aliases now resolve in Swift too")
    func dbMunicipalityAliasesResolve() {
        #expect(CityNameNormalizer.normalize("mt. pleasant") == "Mount Pleasant")
        #expect(CityNameNormalizer.normalize("Mt Pleasant") == "Mount Pleasant")
        #expect(CityNameNormalizer.normalize("South Salt Lake City") == "South Salt Lake")
        #expect(CityNameNormalizer.normalize("West Jordan City") == "West Jordan")
        #expect(CityNameNormalizer.normalize("Summit Park") == "Park City")
        #expect(CityNameNormalizer.normalize("Snyderville") == "Park City")
        #expect(CityNameNormalizer.normalize("Snyderville Basin") == "Park City")
    }

    /// Every alias target must itself be a canonical city, or `normalize(_:)` can emit a
    /// value the DB's Rule-16 city check would reject.
    @Test("every alias target is itself in the catalogue")
    func everyAliasTargetIsCanonical() {
        let catalogue = Set(CityNameNormalizer.canonicalCityCatalog)
        for alias in ["slc", "utah city", "wvc", "af", "pg", "sf", "ssl", "nsl", "wj", "sj",
                      "em", "ss", "bc", "cc", "sg", "pc", "mt. pleasant", "mt pleasant",
                      "south salt lake city", "west jordan city", "summit park",
                      "snyderville", "snyderville basin"] {
            let resolved = CityNameNormalizer.normalize(alias)
            #expect(resolved != nil, "alias '\(alias)' resolved to nil")
            if let resolved {
                #expect(catalogue.contains(resolved),
                        "alias '\(alias)' -> '\(resolved)' is not a canonical city")
            }
        }
    }

    /// The county / statewide-sentinel aliases the DB carries (`salt lake` -> Salt Lake
    /// County, `summit`/`cache`/`rich` -> * County, `utahns`/`wasatch front`/`america` ->
    /// `_utah_wide`, `utah` -> `utah-general`) are deliberately NOT mirrored here: their
    /// targets are not municipalities, and `normalize(_:)` feeds municipality fields at all
    /// 21 call sites. Adding them would change the return contract. Documented, not fixed.
    @Test("county and sentinel aliases are deliberately not mirrored")
    func countyAndSentinelAliasesAreNotMirrored() {
        #expect(CityNameNormalizer.normalize("salt lake") == nil)
        #expect(CityNameNormalizer.normalize("utahns") == nil)
        #expect(CityNameNormalizer.normalize("wasatch front") == nil)
    }
}
