import Foundation
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

    @Test("mig 1330 / 1338 shapes report their own listing reason")
    func listingIndexReasonCoversTheEditorLaneShapes() {
        // The four QUERY-BEARING shapes: url.path drops the query, so these prove
        // listingIndexReason matches the whole URL for them rather than the path.
        #expect(GarbageSignalFilter.isListingIndexURL("https://www.millcreekut.gov/Blog.asp?IID=1&ARC=1"))
        #expect(!GarbageSignalFilter.isListingIndexURL("https://www.millcreekut.gov/Blog.aspx?IID=1&BID=8421"))
        #expect(GarbageSignalFilter.isListingIndexURL("https://www.suu.edu/news/related.html?filter=Outdoors"))
        #expect(GarbageSignalFilter.isListingIndexURL("https://cityofhurricane.com/Archive.aspx?AMID=38"))
        #expect(!GarbageSignalFilter.isListingIndexURL("https://kanab.utah.gov/Archive.aspx?ADID=207"))
        #expect(GarbageSignalFilter.isListingIndexURL(
            "https://www.ferroncityutah.gov/module/events.htm?pageComponentId=5527477&day=10&month=9&year=2026"))
        #expect(!GarbageSignalFilter.isListingIndexURL(
            "https://www.ferroncityutah.gov/module/events.htm?pageComponentId=5527477&year=2026&month=Aug&day=15&eventId=8129528"))
        // The path-shaped ones.
        #expect(GarbageSignalFilter.isListingIndexURL("https://www.utah.gov/pmn/sitemap/publicbody/1006.html"))
        #expect(!GarbageSignalFilter.isListingIndexURL("https://www.utah.gov/pmn/sitemap/notice/1104155.html"))
        #expect(GarbageSignalFilter.isListingIndexURL(
            "https://www.espn.com/college-football/game/_/gameId/401636880/byu-baylor"))
        #expect(GarbageSignalFilter.isListingIndexURL("https://extension.usu.edu/agrability/in-the-news.php"))
        #expect(!GarbageSignalFilter.isListingIndexURL(
            "https://business.utah.gov/in-the-news/move-over-silicon-valley-utah-has-arrived/"))
        // The reason strings are the editorial audit trail; keep them stable.
        #expect(reason("Millcreek Blog", "https://www.millcreekut.gov/Blog.asp?IID=1&ARC=1", newsBody)
            == "CivicPlus blog listing view (blog/category/archive index, not a post)")
        #expect(reason("Public Body", "https://www.utah.gov/pmn/sitemap/publicbody/1006.html", newsBody)
            == "PMN public-body index (a body's notice list, not a notice)")
        #expect(reason("Calendar", "https://www.perrycityut.gov/module/events.htm", newsBody)
            == "CivicPlus calendar view page (event enumerator, not an event)")
    }

    @Test("The 1338 shapes keep the documented query-tail SUPERSET on the path forms")
    func inTheNewsQueryTailIsRefusedOnlyBySibling() {
        // Terminal-anchored on the whole URL in isNonNewsSourceURL (DB parity), but
        // listingIndexReason matches url.path, so a ?utm= tail is still a listing.
        let tail = "https://extension.usu.edu/in-the-news?utm_source=alert"
        #expect(!GarbageSignalFilter.isNonNewsSourceURL(tail))
        #expect(GarbageSignalFilter.isListingIndexURL(tail))
        #expect(reason("In the News", tail, newsBody)
            == "in-the-news section root (listing source, not a story)")
    }

    @Test("mig 1342 shapes report their own listing reason")
    func listingIndexReasonCoversTheFormFaqDriveShapes() {
        #expect(GarbageSignalFilter.isListingIndexURL(
            "https://www.sjc.utah.gov/FormCenter/Parks-Recreation-5/Gingerbread-Contest-Entry-2026-170"))
        #expect(GarbageSignalFilter.isListingIndexURL("https://highlandut.gov/FormCenter"))
        #expect(GarbageSignalFilter.isListingIndexURL("https://www.santaquin.gov/Faq.aspx?QID=107"))
        #expect(GarbageSignalFilter.isListingIndexURL("https://www.murray.utah.gov/faq.aspx"))
        #expect(!GarbageSignalFilter.isListingIndexURL("https://lindon.gov/CivicAlerts.aspx?AID=20"))
        #expect(!GarbageSignalFilter.isListingIndexURL(
            "https://www.example.com/news/2026/09/06/formcenter-opens-downtown"))
        #expect(reason("Gingerbread Contest Entry",
                       "https://www.sjc.utah.gov/FormCenter/Parks-Recreation-5/Gingerbread-Contest-Entry-2026-170",
                       newsBody) == "CivicPlus form-center page (a form, not the decision behind it)")
        #expect(reason("FAQs", "https://www.murray.utah.gov/faq.aspx", newsBody)
            == "CivicPlus FAQ explainer page (standing answers, not a dated notice)")
    }

    /// THE ASYMMETRY THIS PORT EXISTS TO PIN: the Drive clause is HOST-bearing, and
    /// url.path drops the host — matching it against `path` returns nil for every
    /// folder while the DB refuses them. Its siblings are PATH-shaped and must not
    /// swallow a civic site's own /drive/folders/ path.
    @Test("The Google Drive folder clause is matched on the whole URL, not url.path")
    func driveFolderClauseIsHostBearing() {
        let folder = "https://drive.google.com/drive/folders/10eOBG7Yc-TK14R3OzXEYNXKzBmwhBXCu"
        #expect(GarbageSignalFilter.isNonNewsSourceURL(folder))
        #expect(GarbageSignalFilter.isListingIndexURL(folder))     // proves `full`, not `path`
        #expect(reason("Folder - Google Drive", folder, newsBody)
            == "Google Drive folder listing (a file index, not a document)")

        // Every live spelling of the folder page is one class.
        #expect(GarbageSignalFilter.isListingIndexURL(
            "https://drive.google.com/drive/u/0/folders/0B1_5OqGNASZ5Rkxfc2Z3VUZMRXc"))
        #expect(GarbageSignalFilter.isListingIndexURL(
            "https://drive.google.com/drive/mobile/folders/1WnZfL1yTFTzdSGnqn8NQHiU1YbqJ0oym?usp=sharing"))

        // A civic site whose own path happens to read /drive/folders/ is untouched.
        let civicPath = "https://www.example.gov/drive/folders/2026-budget"
        #expect(!GarbageSignalFilter.isNonNewsSourceURL(civicPath))
        #expect(!GarbageSignalFilter.isListingIndexURL(civicPath))

        // A Drive FILE is a primary source on BOTH predicates (live published 2260971a).
        let file = "https://drive.google.com/file/d/1DREp20n3szUjdiMTdAyYeuw8vsvvbHSH/view?usp=drive_link"
        #expect(!GarbageSignalFilter.isNonNewsSourceURL(file))
        #expect(!GarbageSignalFilter.isListingIndexURL(file))
    }

    @Test("mig 1346 shapes report their own listing reason")
    func listingIndexReasonCoversTheProfileAndCalendarShapes() {
        #expect(GarbageSignalFilter.isListingIndexURL("https://bsky.app/profile/georgiametcalf.bsky.social"))
        #expect(GarbageSignalFilter.isListingIndexURL(
            "https://www.ssanpete.org/school-info/calendars/mhs-calendar/monthcalendar/2026/11.html"))
        #expect(GarbageSignalFilter.isListingIndexURL(
            "https://www.piutek12.org/calendar/eventsbyyear/2026/-.html"))
        #expect(GarbageSignalFilter.isListingIndexURL("https://smithfieldutah.gov/calendar/month/2026-09"))
        // Each of the four clauses reports ITS OWN reason — a shape that fell through
        // to a sibling's string would mean the clause order drifted from the DB's.
        #expect(reason("Georgia Metcalf", "https://bsky.app/profile/georgiametcalf.bsky.social", newsBody)
            == "Bluesky profile root (an account's post index, not a post)")
        #expect(reason("MHS Calendar",
                       "https://www.ssanpete.org/school-info/calendars/mhs-calendar/monthcalendar/2026/11.html",
                       newsBody) == "school-calendar view page (an enumerator of events, not a story)")
        #expect(reason("Events by year", "https://www.piutek12.org/calendar/eventsbyyear/2026/-.html", newsBody)
            == "calendar year view (an enumerator of events, not a story)")
        #expect(reason("September 2026", "https://smithfieldutah.gov/calendar/month/2026-09", newsBody)
            == "calendar day/week/month view (an enumerator of events, not a story)")
        // The carve-outs the reason strings must NOT claim.
        #expect(!GarbageSignalFilter.isListingIndexURL(
            "https://www.ssanpete.org/district-information/district-calendar/3116312/school-board-meeting.html"))
        #expect(!GarbageSignalFilter.isListingIndexURL("https://www.piutek12.org/calendar.html"))
    }

    /// THE ASYMMETRY THIS PORT EXISTS TO PIN, in its sharpest form. The bsky clause
    /// carries BOTH traps at once: it is HOST-bearing (url.path drops the host, the
    /// mig 1342 (3) trap) AND END-anchored (url.path drops the query, so a ?ref= tail
    /// would defeat the `$`). Only a whole-URL match keeps a profile ROOT apart from a
    /// /post/ permalink — and the live editor PUBLISHED such a post (d67a378a) as a
    /// primary source, so that URL must stay news on BOTH predicates.
    @Test("The bsky profile-root clause is matched on the whole URL and anchored at the END")
    func bskyProfileRootClauseIsHostBearingAndEndAnchored() {
        let root = "https://bsky.app/profile/georgiametcalf.bsky.social"
        #expect(GarbageSignalFilter.isNonNewsSourceURL(root))
        #expect(GarbageSignalFilter.isListingIndexURL(root))     // proves `full`, not `path`
        #expect(reason("Georgia Metcalf", root, newsBody)
            == "Bluesky profile root (an account's post index, not a post)")

        // Every live spelling of the root is one class: www, a trailing slash, a query
        // tail, and a did:plc: handle (colons are legal in a non-first path segment —
        // URL(string:) parses it, so isListingIndexURL is NOT blind to this spelling).
        #expect(GarbageSignalFilter.isListingIndexURL("https://www.bsky.app/profile/thechrony.bsky.social"))
        #expect(GarbageSignalFilter.isListingIndexURL("https://bsky.app/profile/huntsmancancer.bsky.social/"))
        #expect(GarbageSignalFilter.isListingIndexURL("https://bsky.app/profile/cthorley.bsky.social?ref=x"))
        let didRoot = "https://bsky.app/profile/did:plc:luf6isxwbbodo7bgkd5arieq"
        #expect(URL(string: didRoot) != nil)
        #expect(GarbageSignalFilter.isListingIndexURL(didRoot))
        #expect(GarbageSignalFilter.isNonNewsSourceURL(didRoot))

        // THE POST THE EDITOR PUBLISHED (d67a378a) — the exact production source_url,
        // doubly-encoded ref_url and all. FALSE on both predicates or this port has
        // deleted a primary source the editor accepted.
        let publishedPost = "https://bsky.app/profile/did:plc:luf6isxwbbodo7bgkd5arieq/post/"
            + "3m63shhebac22?ref_src=embed&ref_url=https%253A%252F%252Fwww.sltrib.com%252Fnews"
            + "%252Feducation%252F2025%252F12%252F04%252Findigenous-author-cancels-weber%252F"
        #expect(!GarbageSignalFilter.isNonNewsSourceURL(publishedPost))
        #expect(!GarbageSignalFilter.isListingIndexURL(publishedPost))

        // A bare post, a profile SUB-page and the host anchor.
        for open in ["https://bsky.app/profile/esqueer.net/post/3mrbpatwcys2s",
                     "https://bsky.app/profile/foo.bsky.social/feed/whats-hot",
                     "https://notbsky.app.evil.com/profile/foo"] {
            #expect(!GarbageSignalFilter.isNonNewsSourceURL(open))
            #expect(!GarbageSignalFilter.isListingIndexURL(open))
        }
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

struct IndexTitleReasonTests {

    private let pageURL = "https://example.gov/page"

    @Test("Month-year archive titles return the month-year reason")
    func recognizesMonthYearArchives() {
        let fixtures = [
            ("August 2026 – Tremonton City", "https://tremontoncity.gov/2026/08/"),
            ("April 2025 – Tremonton City", pageURL),
            ("June 2026 – Garden City Fire District", pageURL),
            ("May 2014 – Garden City Fire District", pageURL),
            ("April 2026 – Town of Hideout, Wasatch County, UT", pageURL),
            ("March 2026 | Governor Spencer J. Cox", pageURL),
            ("February, 2026 - Kane County School District", pageURL),
            ("April 2024 – Salton Sea Program", pageURL),
            ("June 2025 – Naples City, Uintah County, Utah", pageURL)
        ]
        for (title, url) in fixtures {
            #expect(GarbageSignalFilter.indexTitleReason(title, url: url) == "index-title: month-year archive")
        }
    }

    @Test("Day archive titles return the day reason")
    func recognizesDayArchives() {
        let fixtures = [
            ("June 11, 2026 – City of Orem", "https://orem.gov/2026/06/11/"),
            ("June 25, 2026 – City of Orem", pageURL),
            ("August 14, 2026 - Utah Film Commission", pageURL)
        ]
        for (title, url) in fixtures {
            #expect(GarbageSignalFilter.indexTitleReason(title, url: url) == "index-title: day archive")
        }
    }

    @Test("The first separator exposes bare-month archive titles")
    func recognizesBareMonths() {
        let fixtures = [
            ("September | 2026 | Washington County of Utah", "https://www.washco.utah.gov/2026/09"),
            ("December | 2025 | Washington County of Utah", pageURL)
        ]
        for (title, url) in fixtures {
            #expect(GarbageSignalFilter.indexTitleReason(title, url: url) == "index-title: bare month")
        }
    }

    @Test("Terminal by-year, by-month, and by-date phrases identify indexes")
    func recognizesByPeriodIndexes() {
        let fixtures = [
            ("Press Releases by year", "https://healthcare.utah.edu/press-releases/2010"),
            ("HMHI stories by year | University of Utah Health", "https://healthcare.utah.edu/hmhi/news/2021"),
            ("News stories by year", pageURL),
            ("HealthFeed by year", pageURL),
            ("Recognition by year", pageURL),
            ("Stories by month", pageURL),
            ("Stories by date", pageURL)
        ]
        for (title, url) in fixtures {
            #expect(GarbageSignalFilter.indexTitleReason(title, url: url) == "index-title: by-year index")
        }
    }

    @Test("Real headlines and the rejected index vocabulary remain allowed")
    func allowsRealHeadlinesAndIndexVocabulary() {
        let titles = [
            "News Flash Archive - Early Secondary Water Shutoff Begins September 15",
            "News - Weber County",
            "News - Washington City Utah",
            "Press Release: Vehicle Theft",
            "Press Release 7-27-2026",
            "Press Releases",
            "News",
            "Archives",
            "Calendar",
            "Home - Trailside Elementary",
            "News / Jan 23 meeting",
            "Orem City Council Enacts Compensation Increases for Specific Officers",
            "May Day celebration returns to Lehi",
            "March for Babies walk set for Saturday",
            "August Miller named principal",
            "June 2026 budget hearing set for Tremonton",
            "Sorted by relevance: council agendas",
            "Standby year",
            "Crime statistics by year show decline in Provo",
            "Births by month, 2025: a Utah County report",
            "",
            "   "
        ]
        for title in titles {
            #expect(GarbageSignalFilter.indexTitleReason(title, url: pageURL) == nil)
        }
    }

    @Test("Document path extensions exempt newsletters regardless of case or URL tails")
    func exemptsDocumentURLs() {
        #expect(GarbageSignalFilter.indexTitleReason(
            "March 2023",
            url: "https://ivinsutah.gov/wp-content/uploads/2023/03/March-2023-Newsletter-Reduced.pdf"
        ) == nil)
        #expect(GarbageSignalFilter.indexTitleReason(
            "March 2023", url: "https://ivinsutah.gov/2023/03/"
        ) == "index-title: month-year archive")
        #expect(GarbageSignalFilter.indexTitleReason(
            "March 2023",
            url: "https://ivinsutah.gov/wp-content/uploads/2023/03/March-2023-Newsletter.PDF?dl=1"
        ) == nil)

        for pathExtension in ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "csv"] {
            for title in ["March 2023", "March 11, 2023", "March", "Stories by year"] {
                #expect(GarbageSignalFilter.indexTitleReason(
                    title, url: "https://example.gov/newsletter.\(pathExtension.uppercased())?dl=1#page=2"
                ) == nil)
            }
        }
    }

    @Test("Normalization trims, uses the first spaced separator, and retains only core characters")
    func normalizesCoreTitles() {
        for separator in ["|", "-", "–", "—", ":", "»"] {
            #expect(GarbageSignalFilter.indexTitleReason(
                " \nFEBRUARY, 2026\t\(separator)\tPublisher | Later suffix \n", url: pageURL
            ) == "index-title: month-year archive")
        }
        #expect(GarbageSignalFilter.indexTitleReason(
            "March | April 2026 – Publisher", url: pageURL
        ) == "index-title: bare month")
        #expect(GarbageSignalFilter.indexTitleReason(
            "📅 March, 2023!", url: pageURL
        ) == "index-title: month-year archive")
        for title in ["March 2023|Publisher", "March 2023 -Publisher", "March & 2023", "March\t2023"] {
            #expect(GarbageSignalFilter.indexTitleReason(title, url: pageURL) == nil)
        }
    }

    @Test("All full month names match with the specified year and day boundaries")
    func respectsArchivePatternBoundaries() {
        for month in ["January", "February", "March", "April", "May", "June",
                      "July", "August", "September", "October", "November", "December"] {
            #expect(GarbageSignalFilter.indexTitleReason(month, url: pageURL) == "index-title: bare month")
            for year in [1900, 2099] {
                #expect(GarbageSignalFilter.indexTitleReason(
                    "\(month) \(year)", url: pageURL
                ) == "index-title: month-year archive")
                #expect(GarbageSignalFilter.indexTitleReason(
                    "\(month) 1, \(year)", url: pageURL
                ) == "index-title: day archive")
            }
        }
        for title in ["March 1899", "March 2100", "Mar 2026", "March 111 2026",
                      "March 1 2026 hearing", "Stories by  year", "Stories by years"] {
            #expect(GarbageSignalFilter.indexTitleReason(title, url: pageURL) == nil)
        }
    }

    @Test("Unparseable URLs and document names outside the path do not exempt archive titles")
    nonisolated func keepsArchiveChecksIndependentOfURLParsing() {
        let malformedURL = "https://[invalid/newsletter.pdf"
        #expect(URL(string: malformedURL) == nil)
        for url in [malformedURL, "", "https://example.gov/archive?file=newsletter.pdf",
                    "https://example.gov/archive#newsletter.pdf", "https://example.gov/archive.html"] {
            #expect(GarbageSignalFilter.indexTitleReason(
                "March 2023", url: url
            ) == "index-title: month-year archive")
        }
    }
}
