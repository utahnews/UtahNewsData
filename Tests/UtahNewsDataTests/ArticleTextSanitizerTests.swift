//
//  ArticleTextSanitizerTests.swift
//  UtahNewsDataTests
//
//  Sprint AD.1 (2026-05-18) — entity decoding + run-on splitting.
//  Anchors the regression set so the screenshot defects (`&#8212;`,
//  `ASSOCIATIONCavaliers`, `6Orioles`) can't ship to readers again.
//

import XCTest
@testable import UtahNewsData

final class ArticleTextSanitizerTests: XCTestCase {

    // MARK: - HTML entity decoding

    func test_decodesNumericEmDashEntity() {
        let input = "(NEW YORK) &#8212; Here are the scores"
        let expected = "(NEW YORK) — Here are the scores"
        XCTAssertEqual(ArticleTextSanitizer.sanitize(input), expected)
    }

    func test_decodesHexEntities() {
        let input = "Salt Lake City &#x2014; the capital"
        let expected = "Salt Lake City — the capital"
        XCTAssertEqual(ArticleTextSanitizer.sanitize(input), expected)
    }

    func test_decodesCommonNamedEntities() {
        let input = "AT&amp;T &nbsp; Salt Lake&rsquo;s &ldquo;quote&rdquo;"
        let result = ArticleTextSanitizer.sanitize(input)
        XCTAssertTrue(result.contains("AT&T"))        // &amp; → &
        XCTAssertTrue(result.contains("\u{2019}"))    // &rsquo; → '
        XCTAssertTrue(result.contains("\u{201C}"))    // &ldquo; → "
        XCTAssertTrue(result.contains("\u{201D}"))    // &rdquo; → "
        // No raw entity prefixes remain (any "&" must be the decoded ampersand).
        XCTAssertFalse(result.contains("&amp;"))
        XCTAssertFalse(result.contains("&nbsp;"))
        XCTAssertFalse(result.contains("&rsquo;"))
        XCTAssertFalse(result.contains("&ldquo;"))
        XCTAssertFalse(result.contains("&rdquo;"))
    }

    func test_leavesNonEntityAmpersandsAlone() {
        let input = "Black & Decker had record sales"
        let result = ArticleTextSanitizer.sanitize(input)
        XCTAssertEqual(result, "Black & Decker had record sales")
    }

    func test_malformedNumericEntityUnchanged() {
        let input = "Score &#abc; was disputed"
        let result = ArticleTextSanitizer.sanitize(input)
        XCTAssertTrue(result.contains("&#abc;"))
    }

    // MARK: - Run-on splitting

    func test_splitsHeadingTitleCaseRunOn() {
        let input = "NATIONAL BASKETBALL ASSOCIATIONCavaliers 125, Pistons 94"
        let result = ArticleTextSanitizer.sanitize(input)
        XCTAssertTrue(result.contains("ASSOCIATION\nCavaliers"))
    }

    func test_splitsMultipleHeadingRunOns() {
        let input = "MAJOR LEAGUE BASEBALLMarlins 3, Rays 6 NHLBruins 4"
        let result = ArticleTextSanitizer.sanitize(input)
        XCTAssertTrue(result.contains("BASEBALL\nMarlins"))
        // NHL is only 3 caps so won't trigger {3,}+[A-Z][a-z] until "NHLB" but
        // followed by "ruins" lowercase. "NHL" + "B" + "ruins" matches.
        XCTAssertTrue(result.contains("NHL\nBruins"))
    }

    func test_splitsScoreboardDigitRunOn() {
        let input = "Marlins 3, Rays 6Orioles 7, Nationals 3"
        let result = ArticleTextSanitizer.sanitize(input)
        XCTAssertTrue(result.contains("6\nOrioles"))
    }

    func test_doesNotBreakValidCamelCase() {
        // iPhone has only 1 uppercase → must not split.
        let input = "Apple released the new iPhone today"
        let result = ArticleTextSanitizer.sanitize(input)
        XCTAssertTrue(result.contains("iPhone"))
        XCTAssertFalse(result.contains("iPh\n") || result.contains("i\nPhone"))
    }

    func test_doesNotBreakTwoLetterAcronyms() {
        // "UN" is only 2 caps — should NOT split "UNRules" (intentionally
        // conservative).
        let input = "Updated UNRules apply"
        let result = ArticleTextSanitizer.sanitize(input)
        XCTAssertTrue(result.contains("UNRules"))
    }

    // MARK: - Composition

    func test_idempotent() {
        let input = "(NEW YORK) &#8212; ASSOCIATIONCavaliers 125"
        let once = ArticleTextSanitizer.sanitize(input)
        let twice = ArticleTextSanitizer.sanitize(once)
        XCTAssertEqual(once, twice)
    }

    func test_screenshotDefects_endToEnd() {
        let input = """
        (NEW YORK) &#8212; Here are the scores from Sunday's sports events:
        NATIONAL BASKETBALL ASSOCIATIONCavaliers 125, Pistons 94 MAJOR LEAGUE \
        BASEBALLMarlins 3, Rays 6Orioles 7, Nationals 3
        """
        let result = ArticleTextSanitizer.sanitize(input)
        XCTAssertFalse(result.contains("&#8212;"), "em-dash entity should be decoded")
        XCTAssertFalse(result.contains("ASSOCIATIONCavaliers"), "heading run-on should split")
        XCTAssertFalse(result.contains("BASEBALLMarlins"), "heading run-on should split")
        XCTAssertFalse(result.contains("6Orioles"), "scoreboard run-on should split")
        XCTAssertTrue(result.contains("—"), "em dash should appear after decode")
    }

    func test_existingMarkdownStrippingStillWorks() {
        // Confirm Sprint AD.1 additions didn't regress prior behavior.
        let input = "## Header\n**bold** and `code` and [link](http://x)"
        let result = ArticleTextSanitizer.sanitize(input)
        XCTAssertTrue(result.contains("Header"))
        XCTAssertFalse(result.contains("##"))
        XCTAssertFalse(result.contains("**"))
        XCTAssertFalse(result.contains("`"))
        XCTAssertFalse(result.contains("](http"))
    }

    func test_emptyAndWhitespaceInputs() {
        XCTAssertEqual(ArticleTextSanitizer.sanitize(""), "")
        XCTAssertEqual(ArticleTextSanitizer.sanitize("   "), "")
    }
}
