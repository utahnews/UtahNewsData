//
//  CityNameNormalizerSlugTests.swift
//  UtahNewsDataTests
//
//  Verifies CityNameNormalizer.slug(_:) reproduces pipeline.app_cities.id byte-for-byte —
//  the SQL rule `lower(regexp_replace(name, '[^A-Za-z0-9]+', '-', 'g'))` (migration 292).
//  Invariant checked live against the DB: 0 mismatches across all 321 canonical names.
//

import Testing
@testable import UtahNewsData

struct CityNameNormalizerSlugTests {

    @Test("slug reproduces app_cities.id for representative canonical names")
    func slugParity() {
        #expect(CityNameNormalizer.slug("Salt Lake City") == "salt-lake-city")
        #expect(CityNameNormalizer.slug("St. George") == "st-george")          // '. ' -> single '-'
        #expect(CityNameNormalizer.slug("West Valley City") == "west-valley-city")
        #expect(CityNameNormalizer.slug("Cottonwood Heights") == "cottonwood-heights")
        #expect(CityNameNormalizer.slug("Marriott-Slaterville") == "marriott-slaterville")
        #expect(CityNameNormalizer.slug("South Salt Lake") == "south-salt-lake")
        #expect(CityNameNormalizer.slug("Provo") == "provo")
        #expect(CityNameNormalizer.slug("Park City") == "park-city")
    }

    @Test("slug collapses runs of non-alphanumerics to a single hyphen, no edge trim")
    func slugCollapseRule() {
        #expect(CityNameNormalizer.slug("A  B") == "a-b")     // multiple spaces -> one '-'
        #expect(CityNameNormalizer.slug("A--B") == "a-b")     // multiple punctuation -> one '-'
        #expect(CityNameNormalizer.slug("St.George") == "st-george")
        // No btrim (matches the DB rule) — edge punctuation keeps an edge hyphen.
        #expect(CityNameNormalizer.slug(".Foo.") == "-foo-")
    }
}
