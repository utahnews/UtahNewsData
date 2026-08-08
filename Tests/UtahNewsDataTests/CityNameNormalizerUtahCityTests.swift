//
//  CityNameNormalizerUtahCityTests.swift
//  UtahNewsDataTests
//
//  Locks in Mark's 2026-07-30 ruling on the "Utah City" alias and the bare "Utah" label.
//
//  THE RULING, in three parts:
//    1. "Utah City" is the 700-acre development on the former Geneva Steel site INSIDE
//       Vineyard. It is NOT an incorporated municipality, so it aliases to Vineyard.
//    2. Promotion to a first-class city happens ONLY on official incorporation paper —
//       never because coverage volume grew. See docs/CITY_TAXONOMY.md.
//    3. IT IS NEVER TOKEN-MATCHED. The phrase "Utah City Councils ..." appears in real
//       statewide headlines, so any content scanner that matches the string inside prose
//       will attribute statewide legislative coverage to a Vineyard subdivision.
//
//  Part 3 is the reason this file exists. `normalize(_:)` is an EXACT-VALUE lookup on a
//  city FIELD — it takes `article.city`, `processed_items.city_name`, a `city_source:`
//  prefix — never a headline and never a body. These tests assert that boundary holds, so
//  that a future "improvement" that starts scanning content through this API fails loudly
//  instead of silently mis-citing statewide stories.
//
//  Mirrors the DB: pipeline.tg_articles_alias_city_pregate() and
//  pipeline.tg_articles_canonicalize_city() both carry the same
//  `WHEN 'utah city' THEN 'Vineyard'` exact-value CASE (migs 303/640/691). If you change
//  the alias here, change it there in the same push, or Swift and Postgres disagree about
//  who owns the name.
//

import Testing
@testable import UtahNewsData

struct CityNameNormalizerUtahCityTests {

    // MARK: - The alias itself

    @Test("'Utah City' aliases to Vineyard, case- and whitespace-insensitively")
    func utahCityAliasesToVineyard() {
        #expect(CityNameNormalizer.normalize("Utah City") == "Vineyard")
        #expect(CityNameNormalizer.normalize("utah city") == "Vineyard")
        #expect(CityNameNormalizer.normalize("UTAH CITY") == "Vineyard")
        #expect(CityNameNormalizer.normalize("  Utah City  ") == "Vineyard")
        // The prefixed registry forms resolve through the same lookup.
        #expect(CityNameNormalizer.normalize("city_source:Utah City") == "Vineyard")
    }

    @Test("Vineyard itself still normalizes to Vineyard (the alias did not shadow it)")
    func vineyardStillResolves() {
        #expect(CityNameNormalizer.normalize("Vineyard") == "Vineyard")
        #expect(CityNameNormalizer.normalize("vineyard") == "Vineyard")
    }

    // MARK: - THE TOKEN-MATCHING BAN (Mark's ruling, part 3)

    @Test("A statewide headline containing the phrase 'Utah City' does NOT attribute to Vineyard")
    func headlinePhraseIsNotTokenMatched() {
        // The canonical counter-example from the ruling. "Utah City Councils" is a real
        // statewide construction; attributing it to Vineyard would put legislative
        // coverage of all 253 municipalities into one subdivision's feed.
        #expect(CityNameNormalizer.normalize("Utah City Councils Manage Budget Shortfalls Amid Rising Costs") == nil)

        // Same shape, other real constructions seen in Utah political copy.
        #expect(CityNameNormalizer.normalize("Utah City Council Members Push Back on New Water Rules") == nil)
        #expect(CityNameNormalizer.normalize("Utah City and County Leaders Meet on Homelessness") == nil)
        #expect(CityNameNormalizer.normalize("Report: Utah City Budgets Strained by Inflation") == nil)

        // …and the alias must not leak out of a longer value in ANY position.
        #expect(CityNameNormalizer.normalize("Vineyard's Utah City development breaks ground") == nil)
        #expect(CityNameNormalizer.normalize("A look at Utah City") == nil)
    }

    @Test("The bare word 'Utah' is not a city and never normalizes to one")
    func bareUtahIsNotACity() {
        // 'Utah' is a SCOPE, not a place. It is absent from canonicalCities and from
        // abbreviations, and the platform's declared sentinel for statewide is
        // '_utah_wide' (DB side). Returning nil here is what keeps every NewsCapture
        // drafter from writing the bare string into pipeline.articles.city.
        #expect(CityNameNormalizer.normalize("Utah") == nil)
        #expect(CityNameNormalizer.normalize("utah") == nil)
        #expect(CityNameNormalizer.normalize("UTAH") == nil)
        #expect(CityNameNormalizer.normalize("State of Utah") == nil)

        // County labels are not cities either (the report's group-B "Utah County" case).
        #expect(CityNameNormalizer.normalize("Utah County") == nil)

        // Statewide headlines that merely CONTAIN "Utah" must not resolve to anything.
        #expect(CityNameNormalizer.normalize("Governor Cox Declares Drought Emergency in 17 Utah Counties") == nil)
        #expect(CityNameNormalizer.normalize("Utah Senate Confirms Two New Justices") == nil)
    }

    @Test("Sentinels are not city names and must not round-trip through the normalizer")
    func sentinelsAreNotCities() {
        #expect(CityNameNormalizer.normalize("_utah_wide") == nil)
        #expect(CityNameNormalizer.normalize("_unassigned") == nil)
        #expect(CityNameNormalizer.normalize("utah-general") == nil)
    }

    // MARK: - Contract: normalize is EXACT-VALUE, not substring

    @Test("normalize is an exact-value lookup — a real city name inside prose does not match")
    func normalizeIsExactValueNotSubstring() {
        // This is the general form of the token-matching ban. If any of these ever start
        // returning a city, someone has turned normalize() into a content scanner and the
        // "Utah City" protection above is only one of many things that just broke.
        #expect(CityNameNormalizer.normalize("Provo") == "Provo")
        #expect(CityNameNormalizer.normalize("A fire broke out in Provo on Tuesday") == nil)
        #expect(CityNameNormalizer.normalize("Salt Lake City") == "Salt Lake City")
        #expect(CityNameNormalizer.normalize("Traffic delays reported near Salt Lake City") == nil)
    }
}
