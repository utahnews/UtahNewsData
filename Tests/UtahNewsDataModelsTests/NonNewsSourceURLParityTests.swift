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

    /// mig 1342's three shapes, clause-for-clause with `pipeline.is_listing_page_url`
    /// as widened on 2026-09-06. The fixtures carry the truth table; this test pins
    /// the three decisions the fixture file cannot express — the two CARVE-OUTS that
    /// keep real primary sources publishable, and the cross-lane verdict this file
    /// must not move.
    @Test("mig 1342 form / FAQ / Drive-folder shapes keep their DB carve-outs")
    func mig1342ShapesKeepTheirCarveOuts() {
        // The three shapes are refused by the DB twin itself, not only by the
        // deliberately-superset sibling.
        #expect(GarbageSignalFilter.isNonNewsSourceURL(
            "https://www.sjc.utah.gov/FormCenter/Parks-Recreation-5/Gingerbread-Contest-Entry-2026-170"))
        #expect(GarbageSignalFilter.isNonNewsSourceURL("https://www.santaquin.gov/Faq.aspx?QID=107"))
        #expect(GarbageSignalFilter.isNonNewsSourceURL(
            "https://drive.google.com/drive/folders/10eOBG7Yc-TK14R3OzXEYNXKzBmwhBXCu?usp=sharing"))

        // CARVE-OUT 1 — a Drive FILE is a primary source. Live published 2260971a
        // (Boulder Town Truth-in-Taxation, 2026-09-05) is exactly this URL.
        #expect(!GarbageSignalFilter.isNonNewsSourceURL(
            "https://drive.google.com/file/d/1DREp20n3szUjdiMTdAyYeuw8vsvvbHSH/view?usp=drive_link"))
        #expect(!GarbageSignalFilter.isNonNewsSourceURL(
            "https://drive.google.com/open?id=1DMvuTKVr2U-x6hnl5osw0QKoHcGM_Akj"))
        // …and the folder clause REQUIRES an id, so the Drive root stays news.
        #expect(!GarbageSignalFilter.isNonNewsSourceURL("https://drive.google.com/drive/my-drive"))

        // CARVE-OUT 2 — the leading slash is the only discriminator against a slug.
        #expect(!GarbageSignalFilter.isNonNewsSourceURL(
            "https://www.example.com/news/2026/09/06/formcenter-opens-downtown"))
        #expect(!GarbageSignalFilter.isNonNewsSourceURL("https://www.example.gov/reformcenter/permits"))
        #expect(!GarbageSignalFilter.isNonNewsSourceURL("https://www.example.gov/news/our-faq.aspx"))
        // The generic non-CivicPlus FAQ class is LEFT OPEN on purpose (~211 URLs / 30 d
        // across arbitrary CMSes); this file is scoped to the CivicPlus module name.
        #expect(!GarbageSignalFilter.isNonNewsSourceURL("https://www.example.gov/faqs/"))

        // CROSS-LANE — docs.google.com/forms belongs to mig 1333 at INTAKE
        // (junk_intake_refuses), and mig 1342 must not move its verdict here.
        #expect(!GarbageSignalFilter.isNonNewsSourceURL(
            "https://docs.google.com/forms/d/e/1FAIpQLSc/viewform"))
        // Real CivicPlus news surfaces on the same hosts stay news.
        #expect(!GarbageSignalFilter.isNonNewsSourceURL("https://lindon.gov/CivicAlerts.aspx?AID=20"))
        #expect(!GarbageSignalFilter.isNonNewsSourceURL(
            "https://www.sjc.utah.gov/AgendaCenter/ViewFile/Agenda/_09022026-2101"))
    }

    /// mig 1346's four shapes, clause-for-clause with `pipeline.is_listing_page_url`
    /// as widened on 2026-09-06. The fixtures carry the truth table; this test pins
    /// what the fixture file cannot express — the carve-outs that keep real primary
    /// sources publishable, the classes MEASURED AND LEFT OPEN on purpose, and the
    /// cross-lane verdicts this file must not move.
    @Test("mig 1346 profile-root and calendar-view shapes keep their DB carve-outs")
    func mig1346ShapesKeepTheirCarveOuts() {
        // The four shapes are refused by the DB twin itself, not only by the
        // deliberately-superset sibling.
        #expect(GarbageSignalFilter.isNonNewsSourceURL("https://bsky.app/profile/georgiametcalf.bsky.social"))
        #expect(GarbageSignalFilter.isNonNewsSourceURL(
            "https://www.ssanpete.org/school-info/calendars/mhs-calendar/monthcalendar/2026/11.html"))
        #expect(GarbageSignalFilter.isNonNewsSourceURL(
            "https://www.piutek12.org/calendar/eventsbyyear/2026/-.html"))
        #expect(GarbageSignalFilter.isNonNewsSourceURL("https://smithfieldutah.gov/calendar/month/2026-09"))

        // CARVE-OUT 1 — a bsky POST is a primary source. The live editor published
        // d67a378a (an author's own statement about withdrawing from a Weber State
        // engagement) off exactly this URL, so the END anchor is load-bearing.
        #expect(!GarbageSignalFilter.isNonNewsSourceURL(
            "https://bsky.app/profile/did:plc:luf6isxwbbodo7bgkd5arieq/post/3m63shhebac22"))
        #expect(!GarbageSignalFilter.isNonNewsSourceURL(
            "https://bsky.app/profile/esqueer.net/post/3mrbpatwcys2s"))

        // CARVE-OUT 2 — a school single-EVENT page stays news; only the VIEW is a
        // listing. Same law as mig 1338's eventId= exemption, which must not move.
        #expect(!GarbageSignalFilter.isNonNewsSourceURL(
            "https://www.ssanpete.org/district-information/district-calendar/3116312/school-board-meeting.html"))
        #expect(!GarbageSignalFilter.isNonNewsSourceURL(
            "https://www.ferroncityutah.gov/module/events.htm?startDate=1/1/2026&eventId=8129528"))
        #expect(!GarbageSignalFilter.isNonNewsSourceURL("https://events.suu.edu/event/fall-convocation-2026"))

        // CARVE-OUT 3 — the trailing slash is the only discriminator against a slug
        // or a host that merely contains the token.
        #expect(!GarbageSignalFilter.isNonNewsSourceURL(
            "https://nationaldaycalendar.com/celebrations/national-hot-dog-day-third-wednesday-in-july"))
        #expect(!GarbageSignalFilter.isNonNewsSourceURL(
            "https://kutv.com/news/local/months-after-canvas-cyberattack-experts-warn-families-to-stay-alert-for-scams"))
        #expect(!GarbageSignalFilter.isNonNewsSourceURL("https://www.piutek12.org/calendar.html"))
        #expect(!GarbageSignalFilter.isNonNewsSourceURL("https://example.org/calendar/monthly-report-2026.pdf"))

        // MEASURED AND LEFT OPEN ON PURPOSE (mig 1346 sec 2.2 N). provo.edu's a/b
        // calendar view is ONE district's page slug on ONE eTLD+1 with 0 live
        // published rows — one CMS slug is not a shape, and it reduces no measured
        // live harm. Re-read that measurement before widening this.
        #expect(!GarbageSignalFilter.isNonNewsSourceURL(
            "https://timpview.provo.edu/school-calendar/a-b-calendar-month-view/"))

        // CROSS-LANE — the OTHER social-profile hosts stay UNDECIDED (mig 1341 (C)).
        // Institutional feeds live on them, and facebook.com additionally carries the
        // Tooele attribution problem; a generic /<handle>$ shape would decide all six
        // by the back door. bsky.app is host-anchored precisely to prevent that.
        #expect(!GarbageSignalFilter.isNonNewsSourceURL("https://x.com/NWSSaltLakeCity"))
        #expect(!GarbageSignalFilter.isNonNewsSourceURL("https://twitter.com/UtahDPS"))
        #expect(!GarbageSignalFilter.isNonNewsSourceURL("https://www.facebook.com/TooeleCityGov"))
        #expect(!GarbageSignalFilter.isNonNewsSourceURL("https://www.instagram.com/universityofutah"))

        // CROSS-LANE — bsky.app gets NO junk_park_hosts row, so nothing here may
        // refuse a profile root at INTAKE. mig 1342's Drive verdicts are unmoved too.
        #expect(!GarbageSignalFilter.isNonNewsSourceURL(
            "https://drive.google.com/file/d/1DREp20n3szUjdiMTdAyYeuw8vsvvbHSH/view?usp=drive_link"))
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
