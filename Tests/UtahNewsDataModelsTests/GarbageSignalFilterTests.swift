import Testing
@testable import UtahNewsDataModels

/// Sprint BM — verifies the institution pipe-template detection in
/// GarbageSignalFilter.garbageReason mirrors the DB is_non_news_page Rule 10b
/// (mig 276): catches "Section | Institution" nav pages, PIPE-ONLY, with zero
/// false-positives on real headlines (em-dash / hyphen must pass).
struct GarbageSignalFilterTests {

    private func reason(_ title: String) -> String? {
        GarbageSignalFilter.garbageReason(
            title: title,
            snippet: String(repeating: "x", count: 400),  // non-thin body
            sourceURL: "https://example.gov/page"
        )
    }

    @Test("Institution pipe-template nav pages are rejected")
    func rejectsInstitutionPipeTemplates() {
        // short prefix branch
        #expect(reason("Makerspace | Ephraim Library") != nil)
        #expect(reason("Home | Lake Mountain School District") != nil)
        #expect(reason("Meetings | Rush Valley Town") != nil)
        // institution-word suffix branch (longer prefix)
        #expect(reason("Agendas and Minutes | Cottonwood Heights City") != nil)
    }

    @Test("Real headlines with em-dash or hyphen are NOT rejected (pipe-only)")
    func allowsEmDashAndHyphenHeadlines() {
        // The exact headline that exposed the em-dash false-positive risk.
        #expect(reason("New pump track brings recreation — and a dash of punk — to Wasatch County") == nil)
        #expect(reason("Lehi City Council approves new park bond - what residents should know") == nil)
    }

    @Test("Real headlines without a pipe template pass")
    func allowsRealHeadlines() {
        #expect(reason("Wasatch Trails Foundation opens new pump track in Heber") == nil)
        #expect(reason("Utah education leaders roll out new AI tools for schools") == nil)
        // A genuine headline that happens to contain a long pre-pipe segment and
        // a non-institution suffix should pass (prefix > 40 and no institution word).
        #expect(reason("Salt Lake City Council weighs a sweeping new affordable-housing ordinance | KSL") == nil)
    }
}

/// 2026-08-26 — court DOCKET RECORD pages (the filing ledger itself) were being
/// published as news: "Docket for 25-965" (supremecourt.gov), three sibling
/// docket files archived by hand, and PACER pages whose titles are docket-entry
/// headlines. The FM classifier types them `article`, so the rule keys on the
/// docket URL space, the bare docket-title template, and docket form fields in
/// the body (a re-hosted docket). Real Utah court COVERAGE must still pass —
/// "Docket" mid-sentence is not a docket page.
struct GarbageSignalFilterDocketTests {

    private let docketBody = """
    No. 25-965   Title: Daniel Grand, Petitioner v. City of University Heights, \
    Ohio, et al. Docketed: February 17, 2026 Lower Ct: United States Court of \
    Appeals for the Sixth Circuit Case Numbers: (24-3225)
    """
    private let newsBody = String(repeating: "Real reporting about a Utah court case. ", count: 12)

    private func reason(_ title: String, _ url: String, _ body: String) -> String? {
        GarbageSignalFilter.garbageReason(title: title, snippet: body, sourceURL: url)
    }

    @Test("The four live docket-record leaks are flagged")
    func flagsLiveDocketLeaks() {
        // 1. supremecourt.gov docket file — URL, title AND body all decisive.
        #expect(reason(
            "Docket for 25-965",
            "https://www.supremecourt.gov/docket/docketfiles/html/public/25-965.html",
            docketBody
        )?.hasPrefix("court docket record page") == true)
        // 2-4. The three hand-archived siblings — title template alone, on a
        // neutral URL, must be enough.
        for caseNo in ["25-1115", "25-573", "25-332", "26A203", "24-1260"] {
            #expect(reason("Docket for \(caseNo)", "https://example.org/page", newsBody)
                == "court docket record page (docket title)")
        }
    }

    @Test("PACER docket-entry headlines are flagged by URL")
    func flagsPacerDocketEntryHeadlines() {
        // A perfectly well-formed headline — only the URL gives it away.
        #expect(reason(
            "Rubicon Files Motion to Preserve Worker Records in Ogden Plant Closure",
            "https://www.pacermonitor.com/public/case/57231884/Rubicon_v_Acme_Holdings",
            newsBody
        ) == "court docket record page (docket URL)")
        #expect(reason(
            "Habeas Corpus Petition Filed by Salt Lake County Inmate",
            "https://www.pacermonitor.com/public/case/12009331/Doe_v_Salt_Lake_County",
            newsBody
        ) == "court docket record page (docket URL)")
    }

    @Test("Other docket URL spaces are flagged (case-insensitive host, subdomains)")
    func flagsOtherDocketURLSpaces() {
        #expect(reason("In re Great Salt Lake Water Rights", "https://www.SupremeCourt.gov/DocketPDF/25/25-965/brief.pdf", newsBody) != nil)
        #expect(reason("Utah v. Environmental Protection Agency", "https://www.courtlistener.com/docket/69123456/utah-v-epa/", newsBody) != nil)
        #expect(reason("Case summary and filings", "https://ecf.pacer.uscourts.gov/cgi-bin/DktRpt.pl?123456", newsBody) != nil)
    }

    @Test("A re-hosted docket is caught by its form fields")
    func flagsRehostedDocketByFormFields() {
        #expect(reason("Grand v. City of University Heights case record", "https://example.com/mirror/25-965", docketBody)
            == "court docket record page (3 docket form fields)")  // Docketed: / Lower Ct: / Case Numbers:
        // ONE marker is not enough — a real story may quote a docket line.
        #expect(reason(
            "Attorneys say the case was docketed: February 17, lawyers dispute the timeline",
            "https://www.sltrib.com/news/2026/02/18/case-timeline/",
            newsBody
        ) == nil)
    }

    @Test("Tag/category listing index URLs are flagged (migration 1128 twin)")
    func flagsListingIndexURLs() {
        #expect(reason("Lehi Free Press Archives Detail Local Arrest and City Plans",
                       "https://lehifreepress.com/tag/plans", newsBody)
            == "tag/category listing index page (listing source, not a story)")
        #expect(reason("Recent Developments and Updates in Lehi Area Education",
                       "https://lehifreepress.com/category/education/", newsBody) != nil)
        #expect(reason("Understanding the Kane County School District",
                       "https://www.sunews.net/blog/categories/community", newsBody) != nil)
        #expect(reason("Huntsman Cancer Institute Shares Diverse Patient Stories",
                       "https://healthcare.utah.edu/huntsmancancerinstitute/news/tags/sarcoma", newsBody) != nil)
    }

    @Test("Calendar VIEW pages and bare news-INDEX roots are flagged (migration 1325 twin)")
    func flagsMig1325ListingShapes() {
        // (a) school-calendar VIEW pages — Finalsite day/week/month enumerators.
        #expect(reason("MHS Events Calendar Lists Upcoming Athletic and District Activities",
                       "https://www.ssanpete.org/eventsbyday/2026/09/05.html", newsBody)
            == "school-calendar view page (event enumerator, not a story)")
        #expect(reason("District Highlights Fall Activities Across Its Schools",
                       "https://www.ssanpete.org/eventsbymonth/2026/09.html", newsBody) != nil)
        #expect(reason("Weekly Slate of School Events Announced",
                       "https://www.ssanpete.org/eventsbyweek/2026/09/01.html", newsBody) != nil)

        // (b) bare news-INDEX roots — terminal-anchored (mig 957 law).
        #expect(reason("Newsroom - West Jordan City",
                       "https://www.westjordan.utah.gov/news", newsBody)
            == "bare news-index root (listing source, not a story)")
        #expect(reason("City Shares Recent Announcements and Updates",
                       "https://www.example.gov/newsroom", newsBody) != nil)
        #expect(reason("Press Releases",
                       "https://www.example.gov/press-releases/", newsBody) != nil)
        #expect(reason("Latest News From the Department",
                       "https://www.example.gov/department/latest-news", newsBody) != nil)
    }

    @Test("Migration 1325 shapes do NOT swallow real stories or child pages")
    func allowsPermalinksNearMig1325Shapes() {
        // A dated permalink continues past the /news root.
        #expect(reason("Council approves water rate increase",
                       "https://www.westjordan.utah.gov/news/2026/09/05/water-rates", newsBody) == nil)
        // Child event pages stay news; only the calendar VIEW is a listing.
        #expect(reason("Board sets date for new elementary groundbreaking",
                       "https://www.ssanpete.org/events/detail/48213", newsBody) == nil)
        // The TRAILING SLASH is load-bearing: a recap slug is not a calendar view.
        #expect(reason("Eventsbyday recap draws record crowd to county fair",
                       "https://www.example.org/eventsbyday-recap-story", newsBody) == nil)
        // A slug merely ending in the word is not an index root.
        #expect(reason("Residents weigh in on what counts as local news",
                       "https://www.example.gov/opinion/what-counts-as-local-news", newsBody) == nil)
    }

    @Test("isListingIndexURL is a deliberate SUPERSET of the DB twin on query tails")
    func listingIndexURLRefusesQueryTailsTheDBMisses() {
        // /news?id=123 is the DOCUMENTED terminal-anchor miss on both sides of
        // pipeline.is_listing_page_url; the URL-parsing sibling still refuses it.
        let queryRoot = "https://www.example.gov/news?id=123"
        #expect(!GarbageSignalFilter.isNonNewsSourceURL(queryRoot))
        #expect(GarbageSignalFilter.isListingIndexURL(queryRoot))
        #expect(reason("Newsroom", queryRoot, newsBody)
            == "bare news-index root (listing source, not a story)")
    }

    @Test("Real permalinks and near-miss slugs are NOT flagged as listing pages")
    func allowsPermalinksNearListingShapes() {
        // Dated permalink on the same outlet.
        #expect(reason("Relentless defense and raw emotion spark thrilling win",
                       "https://lehifreepress.com/2026/08/31/relentless-defense-and-raw-emotion/", newsBody) == nil)
        // Story slug UNDER a category base — path continues past the segment.
        #expect(reason("School board approves budget",
                       "https://example.com/category/education/school-board-approves-budget/", newsBody) == nil)
        // Slugs merely containing the words.
        #expect(reason("Building tagged for demolition comes down",
                       "https://example.com/news/tagged-for-demolition-building-comes-down", newsBody) == nil)
        #expect(reason("Categories of aid announced for flood victims",
                       "https://example.com/categories-of-aid-announced-for-flood-victims", newsBody) == nil)
    }

    @Test("Real Utah court coverage is NOT flagged")
    func allowsRealCourtCoverage() {
        #expect(reason("Utah Supreme Court hears arguments in Great Salt Lake case", "https://www.sltrib.com/news/2026/08/26/gsl-arguments/", newsBody) == nil)
        #expect(reason("Judge dismisses lawsuit over Provo rezoning", "https://www.heraldextra.com/news/2026/08/26/provo-rezoning/", newsBody) == nil)
        #expect(reason("Court records show Ogden landlord owes $1.2M in back rent", "https://www.standard.net/news/2026/08/26/ogden-landlord/", newsBody) == nil)
        #expect(reason("Docket sheet leaked in city council dispute", "https://www.deseret.com/utah/2026/08/26/docket-sheet-leak/", newsBody) == nil)
        #expect(reason("Federal appeals court revives Bears Ears challenge filed by Utah counties", "https://www.ksl.com/article/51234567/bears-ears-appeal", newsBody) == nil)
    }
}
