import Foundation
import Testing
@testable import UtahNewsDataModels

struct NonNewsSourceURLParityTests {

    private struct Fixture: Decodable {
        let url: String
        let expected: Bool
        let clause: String
    }

    @Test("Shared non-news URL fixtures match the Swift predicate")
    func matchesParityFixtures() throws {
        let fixtureFile = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/non_news_source_url_fixtures.json")
        let fixtures = try JSONDecoder().decode(
            [Fixture].self,
            from: Data(contentsOf: fixtureFile)
        )

        let negativeCount = fixtures.count(where: { !$0.expected })
        #expect(negativeCount >= 12)

        let positiveGroups = Dictionary(grouping: fixtures.filter(\.expected), by: \.clause)
        for group in positiveGroups.values {
            #expect(group.count >= 2)
        }

        for fixture in fixtures {
            let actual = GarbageSignalFilter.isNonNewsSourceURL(fixture.url)
            #expect(actual == fixture.expected)
        }
    }

    @Test("DB parity and sibling URL predicates remain independently composable")
    func keepsSiblingPredicatesSeparate() {
        let docketURL = "https://www.pacermonitor.com/public/case/57231884/example"
        #expect(!GarbageSignalFilter.isNonNewsSourceURL(docketURL))
        #expect(GarbageSignalFilter.isDocketRecordURL(docketURL))

        let speakerURL = "https://speeches.byu.edu/speakers/john-hughes"
        #expect(GarbageSignalFilter.isNonNewsSourceURL(speakerURL))
        #expect(GarbageSignalFilter.isReferenceBioURL(speakerURL))

        let queryListingURL = "https://provo.gov/tags/public-notice?utm_source=alert"
        #expect(!GarbageSignalFilter.isNonNewsSourceURL(queryListingURL))
        #expect(GarbageSignalFilter.isListingIndexURL(queryListingURL))
    }

    @Test("All non-news URL regex clauses compile")
    func allRegexClausesCompile() {
        #expect(GarbageSignalFilter.nonNewsRegexCompileFailures.isEmpty)
    }

    @Test("Surrounding whitespace and line endings do not change matching")
    func trimsWhitespaceAndLineEndingsBeforeMatching() {
        let url = "https://example.com/page/2"
        let expected = GarbageSignalFilter.isNonNewsSourceURL(url)

        #expect(GarbageSignalFilter.isNonNewsSourceURL("\(url)\n") == expected)
        #expect(GarbageSignalFilter.isNonNewsSourceURL("\(url)\r") == expected)
        #expect(GarbageSignalFilter.isNonNewsSourceURL(" \t\(url)\r\n ") == expected)
    }
}
