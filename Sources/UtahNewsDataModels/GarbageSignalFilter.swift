//
//  GarbageSignalFilter.swift
//  UtahNewsDataModels
//
//  Sprint AB Phase 1a (2026-05-17).
//
//  Shared garbage-detection logic for signal-tier content (link-out cards,
//  RSS direct ingest, anywhere we need to filter homepage / section-page /
//  placeholder titles before publishing).
//
//  Previously duplicated across V2's LinkOutCardPublisherService and
//  RSSDirectIngestionService. Single source of truth now so V2 and the
//  new NC link-out card publisher (Sprint AB Phase 3) apply identical
//  rules without drift.
//

import Foundation

/// Detects garbage signal-tier content that shouldn't surface as a
/// reader-visible card or article. Returns `nil` if content is clean,
/// or a human-readable reason string explaining why it was rejected
/// (suitable for logging + audit trails).
///
/// All checks are conservative — false negatives (real headlines marked
/// garbage) hurt coverage; false positives (homepage hits marked clean)
/// pollute the reader feed. Tune for false-negative direction.
public enum GarbageSignalFilter: Sendable {

    /// Hardcoded display-name map for major Utah outlets. Used by
    /// `outletDisplayName(for:)` so callers don't each maintain their own
    /// copy. Domains that aren't in this map fall back to the stripped host.
    ///
    /// Future improvement: join against `rss_only_sources.display_name`
    /// when the domain is registered there. For now, this covers the
    /// canonical outlets that produce the bulk of signal volume.
    public static let outletDisplayNames: [String: String] = [
        "fox13now.com": "Fox 13",
        "abc4.com": "ABC 4",
        "ksl.com": "KSL",
        "ksltv.com": "KSL",
        "sltrib.com": "Salt Lake Tribune",
        "deseret.com": "Deseret News",
        "deseretnews.com": "Deseret News",
        "lehifreepress.com": "Lehi Free Press",
        "parkrecord.com": "Park Record",
        "utahnewsdispatch.com": "Utah News Dispatch",
        "kjzz.com": "KJZZ",
        "kutv.com": "KUTV",
        "kuer.org": "KUER",
        "etvnewsutah.com": "ETV News"
    ]

    /// Returns a human-readable outlet name for a URL. Falls back to the
    /// stripped host if the domain isn't in `outletDisplayNames`.
    public static func outletDisplayName(for urlString: String) -> String {
        guard let host = URL(string: urlString)?.host else { return urlString }
        let stripped = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        return outletDisplayNames[stripped] ?? stripped
    }

    /// Court DOCKET RECORD pages — the case-management record itself (party
    /// tables, filing rows, "Docketed:" / "Lower Ct:" fields), never news
    /// coverage of a case. The FM classifier types them `article`, so pages
    /// like "Docket for 25-965" (supremecourt.gov) and PACER docket-entry
    /// headlines ("Rubicon Files Motion to Preserve Worker…") reached readers.
    ///
    /// Host match is case-insensitive and covers subdomains; `pathPrefix` is a
    /// case-insensitive prefix on the path, and an EMPTY prefix means the whole
    /// host is docket-record space. Keep in sync with `pipeline.is_non_news_page`
    /// (DB backstop) and `find_unarticled_primary_items` (candidate filter).
    public static let docketRecordPathMarkers: [(host: String, pathPrefix: String)] = [
        ("supremecourt.gov", "/docket/docketfiles/"),
        ("supremecourt.gov", "/docketpdf/"),
        ("pacermonitor.com", "/public/case/"),
        ("courtlistener.com", "/docket/"),
        ("pacer.uscourts.gov", "")
    ]

    /// Field labels that only occur on a rendered docket record. Two or more
    /// in the body catches a docket that was RE-HOSTED off the known docket
    /// domains (a mirror, a translation proxy, a scraped copy).
    public static let docketFormMarkers: [String] = [
        "docketed:",
        "lower ct:",
        "case numbers:",
        "decision date:",
        "rehearing denied:"
    ]

    /// SPEAKER BIO INDEX pages — a directory entry ABOUT A PERSON, never an
    /// event. The Swift twin of the `speeches.byu.edu/speakers/` clause added to
    /// `pipeline.is_non_news_source_url` by migration 1118 (3-place sync law:
    /// DB predicate + this filter + `find_unarticled_primary_items`, which
    /// inherits it through `_unarticled_primary_band`).
    ///
    /// WHY THIS CLASS EXISTS. Reader flag 730a4892, 2026-08-31: the feature
    /// drafter published "John Hughes serves as editor of the Deseret News" as a
    /// current local profile, drafted from
    /// `https://speeches.byu.edu/speakers/john-hughes`. The body itself cites a
    /// 1998 speech; the role claim is decades stale. A bio index page has no
    /// event and usually no date, so every DATE gate on the platform sees
    /// nothing to refuse — the URL is the only honest signal. Same class as the
    /// roster rule (migration 593) and `congress.gov/member/` (migration 925).
    ///
    /// Measured over the live corpus 2026-08-31: 37 such URLs, 20 articles born
    /// from them, 19 archived / rejected / permanently stuck as drafts.
    ///
    /// ⚠️ HOST-ANCHORED, deliberately. The general `/speakers/<slug>` shape is
    /// clean by content across the whole corpus (48 URLs / 9 hosts, 48/48 the
    /// class) but costs one legitimate appointment story on `speeches.ensign.edu`
    /// — widening it is an editorial policy call, filed for the owner, not taken
    /// here. Widen this list and migration 1118's clause TOGETHER or they stop
    /// being twins.
    public static let speakerBioHostPathMarkers: [(host: String, pathPrefix: String)] = [
        ("speeches.byu.edu", "/speakers/")
    ]

    /// True when the URL is a speaker-bio index page (see
    /// `speakerBioHostPathMarkers`).
    public static func isReferenceBioURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString), let rawHost = url.host else { return false }
        var host = rawHost.lowercased()
        if host.hasPrefix("www.") { host = String(host.dropFirst(4)) }
        let path = url.path.lowercased()
        for marker in speakerBioHostPathMarkers {
            let markerHost = marker.host.lowercased()
            guard host == markerHost || host.hasSuffix("." + markerHost) else { continue }
            let prefix = marker.pathPrefix.lowercased()
            if prefix.isEmpty || path.hasPrefix(prefix) { return true }
        }
        return false
    }

    /// True when the URL is a LISTING/INDEX page. The DB home for every listing
    /// shape is `pipeline.is_listing_page_url` (mig 1325); this is its app-side
    /// twin, and the two are widened TOGETHER or they stop being twins.
    ///
    /// Shapes, in the order `listingIndexReason` reports them:
    ///  - CMS TAG/CATEGORY INDEX — the path ENDS at the tag/category slug
    ///    (migration 1128's twin, 2026-08-31). Covers /tag/, /tags/, /category/,
    ///    /categories/. gemma composes "archive digest" mashups from these pages
    ///    (Lehi audit 2026-08-31: 103 of Lehi's August drafts alone).
    ///  - SCHOOL-CALENDAR VIEW pages (/eventsby{day,week,month}/, Finalsite) —
    ///    migration 1325 (a), 2026-09-05. An ENUMERATOR of events that always
    ///    renders "today", so every date gate sees a live page.
    ///  - BARE NEWS-INDEX ROOTS (terminal /news, /latest-news, /news-releases,
    ///    /newsroom, /press-releases) — migration 1325 (b), 2026-09-05.
    ///  - CivicPlus BLOG LISTING views (Blog.asp[x]?IID=/CID=/ARC=, single-post
    ///    BID= exempt) — migration 1330 (a), 2026-09-06.
    ///  - BOXSCORE / GAMECAST placeholder pages (-game-boxscore-<id>,
    ///    /game/_/gameId/, /gamecast/) — migration 1330 (b), 2026-09-06.
    ///  - PMN PUBLIC-BODY sitemap indexes (/pmn/sitemap/publicbody/) — migration
    ///    1338 (1), 2026-09-06. The notice itself stays news.
    ///  - CMS RELATED-ITEMS filter listings (/related.html?filter=) — 1338 (2).
    ///  - CivicPlus ARCHIVE MODULE indexes (Archive.asp[x]?AMID=, single-document
    ///    ADID= exempt) — 1338 (3).
    ///  - CivicPlus CALENDAR VIEWS (/module/events.htm, single-event eventId=
    ///    exempt) — 1338 (4).
    ///  - /in-the-news SECTION ROOTS (terminal) — 1338 (6). The hyphen-prefixed
    ///    form is a documented miss: story slugs end in the same phrase.
    ///  - CivicPlus /FormCenter/ FORM PAGES — the form LEAF, the CATEGORY page and
    ///    the bare /FormCenter root are one class — migration 1342 (1), 2026-09-06.
    ///    A form is not a source; the decision behind it belongs to the city's news
    ///    release, agenda or calendar page.
    ///  - CivicPlus Faq.asp[x] EXPLAINER pages (?QID=, ?TID=, bare index) — 1342 (2).
    ///    Standing answers, undated, never a dated notice.
    ///  - GOOGLE DRIVE FOLDER listings (drive.google.com/drive/[u/N/][mobile/]
    ///    folders/<id>) — 1342 (3). A folder page is a FILE INDEX and the enumerator
    ///    harvests its contents; the files themselves (/file/d/, /open?id=) are
    ///    primary sources and stay news.
    ///  - BSKY.APP PROFILE ROOTS (bsky.app/profile/<handle>, END-anchored) —
    ///    migration 1346 (1), 2026-09-06. A profile root is the reverse-chronological
    ///    INDEX of one account's posts, the social form of mig 957's /author/<name>
    ///    archive; a /post/<id> permalink continues past it and STAYS NEWS — the live
    ///    editor published exactly such a post (d67a378a) as a primary source.
    ///  - FINALSITE month/day/week CALENDAR VIEWS (/(day|week|month)calendar/) —
    ///    1346 (2a). The second view spelling on the same two hosts mig 1325 measured;
    ///    it published two calendar DIGESTS before this clause existed.
    ///  - FINALSITE YEAR view (/events?byyear/) — 1346 (2b). mig 1325's clause covers
    ///    (day|week|month) only.
    ///  - CMS-AGNOSTIC calendar day/week/month VIEWS (/calendar/(day|week|month)/) —
    ///    1346 (2c). 43 corpus URLs over 3 hosts, 0 false positives corpus-wide.
    ///
    /// FOUR shapes live entirely in the QUERY STRING and TWO in the HOST, all six
    /// of which `url.path` drops — they are matched against the whole URL inside
    /// `listingIndexReason`. The bsky profile root (1346 (1)) needs the whole URL
    /// for a SECOND reason: it is END-ANCHORED, and `path` drops the query, so a
    /// ?ref= tail would defeat the `$` and the two predicates would disagree.
    /// A shape confined to ONE eTLD+1 is not a shape: the sixth class of the
    /// 2026-09-06 editor sweep (St. George recreation program catalogs) went into
    /// `pipeline.junk_park_hosts` as PATH rows instead, and has no clause here. The
    /// Drive FOLDER shape (1342 (3)) is the documented exception, and the reasoning
    /// is recorded so it is not re-litigated: a folder page literally IS a file
    /// listing, it is a GLOBAL PLATFORM surface used by 14 distinct Utah cities in
    /// this corpus, and the `junk_park_hosts` alternative would need the COARSE host
    /// drive.google.com in `_refused_host_sweep_list()`, whose arm would then flag
    /// the live published Drive FILE record 2260971a. `docs.google.com/forms` stays
    /// migration 1333's, refused at INTAKE and not here.
    ///
    /// The bsky PROFILE ROOT (1346 (1)) is the second such exception, and it is
    /// mig 1341 DECISION (C) recorded verbatim rather than a new judgement. It is a
    /// GLOBAL PLATFORM surface, not one eTLD+1's page slug; and the catalog CANNOT
    /// express it — `junk_park_hosts`' PATH branch always appends a trailing `%`, so
    /// `bsky.app/profile/` would match the POST too. A `junk_park_hosts` row would
    /// therefore refuse, at intake, the very post the live editor published
    /// (d67a378a). The shape belongs here, closed at the publish/promote gates, and
    /// bsky.app stays OPEN at intake. It is host-anchored ON PURPOSE: x.com,
    /// twitter.com, instagram.com, threads.com/.net and facebook.com remain UNDECIDED
    /// (institutional feeds live there), and a generic /<handle>$ shape would decide
    /// all six by the back door.
    ///
    /// The mig 957 law holds throughout: a LISTING ends the path, so a
    /// /category/<base>/<story-slug> permalink and a dated /news/2026/09/05/slug
    /// permalink continue past the anchor and never match. Pagination tails
    /// (/tag/x/page/2) are the mig 957 author/pagination shapes, carried by
    /// `isNonNewsSourceURL` alone.
    ///
    /// DELIBERATE SUPERSET of the DB twin on query-string tails: this predicate
    /// matches `url.path`, so /tags/x?utm=… and /news?id=123 — the terminal-anchor
    /// MISS documented on both sides of `pipeline.is_listing_page_url` — are
    /// refused here. That widening is asserted in NonNewsSourceURLParityTests and
    /// is why `garbageReason` consults this predicate rather than
    /// `isNonNewsSourceURL`, which must stay clause-for-clause with the DB.
    public static func isListingIndexURL(_ urlString: String) -> Bool {
        listingIndexReason(urlString) != nil
    }

    /// The editorial audit reason behind `isListingIndexURL`, or `nil` when the
    /// URL is not a listing/index page. Clause order mirrors the predicate's
    /// historical OR order on purpose: a URL that already matched before mig 1325
    /// keeps its original reason string verbatim.
    ///
    /// The tag/category literals differ from `RegexClause.tagIndex` /
    /// `.categoryIndex` by design — those match a whole URL and must exclude
    /// `?#`; these match an already-parsed `url.path`, which carries neither. The
    /// mig 1325 shapes carry no such class, so they are reused from `RegexClause`
    /// directly and cannot drift from the `isNonNewsSourceURL` clauses.
    private static func listingIndexReason(_ urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        let path = url.path.lowercased()
        // ⚠️ `path` DROPS THE QUERY STRING *AND THE HOST*. SIX of the shapes below
        // are invisible to it: four live entirely in the query (Blog.aspx?IID=,
        // related.html?filter=, Archive.aspx?AMID=, module/events.htm?day=) and two
        // in the HOST (drive.google.com/drive/…/folders/<id> — mig 1342 (3) — and
        // bsky.app/profile/<handle> — mig 1346 (1)), so matching any of them against
        // `path` would make them silently invisible here while the DB refuses them.
        // Those clauses match the whole URL instead; the path-anchored shapes keep
        // matching `path`, which is what makes this predicate the documented SUPERSET
        // on query tails. The bsky clause carries a SECOND reason it cannot use
        // `path`: it is END-ANCHORED, and `path` drops the query, so a profile root
        // with a ?ref= tail would match on `path` while the DB's `$` refuses it —
        // the superset would run the WRONG way and swallow no-longer-root URLs.
        let full = urlString.lowercased()
        // The clauses added by migs 1330/1338 pass `.caseInsensitive` explicitly,
        // mirroring the DB's `~*`. Lowercasing the subject is NOT enough: a pattern
        // that carries an uppercase letter (`/game/_/gameId/`) silently matches
        // nothing against a lowercased subject under a case-SENSITIVE regex — the
        // exact miss this predicate exists to prevent.

        if path.range(of: #"/tags?/[^/]+/?$"#, options: .regularExpression) != nil
            || path.range(of: #"/categor(y|ies)/[^/]+/?$"#, options: .regularExpression) != nil {
            return "tag/category listing index page (listing source, not a story)"
        }
        if path.range(
            of: RegexClause.calendarView.rawValue,
            options: .regularExpression
        ) != nil {
            return "school-calendar view page (event enumerator, not a story)"
        }
        if path.range(
            of: RegexClause.newsIndexRoot.rawValue,
            options: .regularExpression
        ) != nil {
            return "bare news-index root (listing source, not a story)"
        }
        // mig 1330 (a) — query-bearing, so matched on the whole URL.
        if full.range(of: RegexClause.blogListingView.rawValue, options: [.regularExpression, .caseInsensitive]) != nil,
           full.range(of: RegexClause.blogSinglePost.rawValue, options: [.regularExpression, .caseInsensitive]) == nil {
            return "CivicPlus blog listing view (blog/category/archive index, not a post)"
        }
        // mig 1330 (b) — path-shaped.
        if path.range(of: RegexClause.gameBoxscore.rawValue, options: [.regularExpression, .caseInsensitive]) != nil
            || path.range(of: RegexClause.gameIdRecord.rawValue, options: [.regularExpression, .caseInsensitive]) != nil
            || path.range(of: RegexClause.gamecastRecord.rawValue, options: [.regularExpression, .caseInsensitive]) != nil {
            return "boxscore or gamecast placeholder page (scoreboard record, not a story)"
        }
        // mig 1338 (1) — path-shaped.
        if path.range(of: RegexClause.pmnPublicBodyIndex.rawValue, options: [.regularExpression, .caseInsensitive]) != nil {
            return "PMN public-body index (a body's notice list, not a notice)"
        }
        // mig 1338 (2) — query-bearing.
        if full.range(of: RegexClause.relatedFilterListing.rawValue, options: [.regularExpression, .caseInsensitive]) != nil {
            return "CMS related-items filter listing (tag view, not a story)"
        }
        // mig 1338 (3) — query-bearing, with the single-document carve-out.
        if full.range(of: RegexClause.archiveModuleIndex.rawValue, options: [.regularExpression, .caseInsensitive]) != nil,
           full.range(of: RegexClause.archiveDocumentId.rawValue, options: [.regularExpression, .caseInsensitive]) == nil {
            return "CivicPlus archive module index (document list, not a document)"
        }
        // mig 1338 (4) — query-bearing, with the single-event carve-out.
        if full.range(of: RegexClause.eventsModuleCalendar.rawValue, options: [.regularExpression, .caseInsensitive]) != nil,
           full.range(of: RegexClause.eventsModuleSingleEvent.rawValue, options: [.regularExpression, .caseInsensitive]) == nil {
            return "CivicPlus calendar view page (event enumerator, not an event)"
        }
        // mig 1338 (6) — path-anchored, so a ?utm= tail is refused here and not by
        // the DB twin: the documented superset, same as newsIndexRoot.
        if path.range(of: RegexClause.inTheNewsRoot.rawValue, options: [.regularExpression, .caseInsensitive]) != nil {
            return "in-the-news section root (listing source, not a story)"
        }
        // mig 1342 (1) — path-shaped. The clause carries its own (\?|#|$) terminator,
        // so path and whole-URL matching agree; no superset gap here.
        if path.range(of: RegexClause.civicPlusFormCenter.rawValue,
                      options: [.regularExpression, .caseInsensitive]) != nil {
            return "CivicPlus form-center page (a form, not the decision behind it)"
        }
        // mig 1342 (2) — path-shaped, same terminator reasoning.
        if path.range(of: RegexClause.civicPlusFaqPage.rawValue,
                      options: [.regularExpression, .caseInsensitive]) != nil {
            return "CivicPlus FAQ explainer page (standing answers, not a dated notice)"
        }
        // mig 1342 (3) — HOST-BEARING, so `full`, not `path`. ⚠️ url.path drops the
        // host: matching this clause against `path` would return nil for every Drive
        // folder while the DB refuses them — the same trap the four query-bearing
        // 1330/1338 shapes carry, in its host-shaped form. Pinned by a test.
        if full.range(of: RegexClause.googleDriveFolder.rawValue,
                      options: [.regularExpression, .caseInsensitive]) != nil {
            return "Google Drive folder listing (a file index, not a document)"
        }
        // mig 1346 (1) — HOST-BEARING **and** END-ANCHORED, so `full`, not `path`.
        // ⚠️ Two traps in one clause: `url.path` drops the host (the mig 1342 (3)
        // trap), and it also drops the query, which would silently DEFEAT the `$` —
        // a /profile/<handle>?ref=x tail is still a ROOT, but a /post/<id> is not,
        // and only the whole-URL match keeps that distinction. Pinned by a test.
        if full.range(of: RegexClause.bskyProfileRoot.rawValue,
                      options: [.regularExpression, .caseInsensitive]) != nil {
            return "Bluesky profile root (an account's post index, not a post)"
        }
        // mig 1346 (2a) — path-shaped. The token must be a whole path SEGMENT tail:
        // nationaldaycalendar.com carries it in the HOST, which `path` drops anyway.
        if path.range(of: RegexClause.finalsiteXCalendarView.rawValue,
                      options: [.regularExpression, .caseInsensitive]) != nil {
            return "school-calendar view page (an enumerator of events, not a story)"
        }
        // mig 1346 (2b) — path-shaped. mig 1325's clause is (day|week|month) only.
        if path.range(of: RegexClause.finalsiteEventsByYear.rawValue,
                      options: [.regularExpression, .caseInsensitive]) != nil {
            return "calendar year view (an enumerator of events, not a story)"
        }
        // mig 1346 (2c) — path-shaped. The trailing slash keeps /calendar/monthly-…
        // and a bare /calendar.html FALSE.
        if path.range(of: RegexClause.calendarDayWeekMonthView.rawValue,
                      options: [.regularExpression, .caseInsensitive]) != nil {
            return "calendar day/week/month view (an enumerator of events, not a story)"
        }
        return nil
    }

    /// Detects archive indexes from the source page's own title, exempting
    /// document URLs. Checks the normalized core title in order for a month-year,
    /// month-day-year, bare month, or a terminal "by year/month/date" phrase.
    ///
    /// Measured: 35/35 index leaks caught, 0/150 ordinary-article false positives.
    /// A 30-day replay refused 376 rows, saved 74 syntheses, and prevented 42
    /// editor/reviewer rejections at the cost of one editor-published row (42:1).
    /// NOT the index vocabulary — measured, 11 editor publishes / 30 d.
    /// CivicPlus uses "News Flash Archive - <headline>" for real stories.
    public nonisolated static func indexTitleReason(_ sourceTitle: String, url urlString: String) -> String? {
        if let pathExtension = URL(string: urlString)?.pathExtension.lowercased(),
           ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "csv"].contains(pathExtension) {
            return nil
        }

        let core = coreTitle(sourceTitle)
        guard !core.isEmpty else { return nil }

        if matches(core, .indexTitleMonthYear) {
            return "index-title: month-year archive"
        }
        if matches(core, .indexTitleDay) {
            return "index-title: day archive"
        }
        if matches(core, .indexTitleBareMonth) {
            return "index-title: bare month"
        }
        if matches(core, .indexTitleByPeriod) {
            return "index-title: by-year index"
        }
        return nil
    }

    private nonisolated static func coreTitle(_ sourceTitle: String) -> String {
        var core = sourceTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if let expression = compiledRegexTable.first(where: { $0.clauseLabel == .indexTitleSeparator })?.0,
           let match = expression.firstMatch(
               in: core,
               options: [],
               range: NSRange(core.startIndex..<core.endIndex, in: core)
           ),
           let separator = Range(match.range, in: core) {
            core = String(core[..<separator.lowerBound])
        }

        // Delete everything outside [a-z0-9& ], including non-space whitespace.
        let scalars = core.lowercased().unicodeScalars.filter {
            switch $0.value {
            case 97...122, 48...57, 38, 32: true
            default: false
            }
        }
        return String(String.UnicodeScalarView(scalars)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// True when the URL points into known court docket-record space.
    public static func isDocketRecordURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString), let rawHost = url.host else { return false }
        var host = rawHost.lowercased()
        if host.hasPrefix("www.") { host = String(host.dropFirst(4)) }
        let path = url.path.lowercased()
        for marker in docketRecordPathMarkers {
            let markerHost = marker.host.lowercased()
            guard host == markerHost || host.hasSuffix("." + markerHost) else { continue }
            let prefix = marker.pathPrefix.lowercased()
            if prefix.isEmpty || path.hasPrefix(prefix) { return true }
        }
        return false
    }

    /// Swift twin of `pipeline.is_non_news_source_url(text)`; callers that also
    /// want docket-record and listing-index refusal OR in the sibling predicates.
    /// The checks stay in SQL order so changes can be reviewed clause-by-clause
    /// against the DB function. Matching trims surrounding whitespace and line
    /// endings first, then operates on the otherwise-raw value without parsing
    /// or canonicalization.
    public nonisolated static func isNonNewsSourceURL(_ urlString: String) -> Bool {
        let value = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        // staff email/contact forms + office directories
        if matches(value, .emailContactForm)
            || matches(value, .districtOfficeDirectory) {
            return true
        }

        // legal boilerplate pages
        if matches(value, .legalBoilerplate) {
            return true
        }

        // staff / faculty / leadership roster pages
        if matches(value, .staffRoster) {
            return true
        }

        // NPS reference DIRECTORIES (mig 448) — evergreen getinvolved/learn/
        // education/planyourvisit/collection pages across ALL parks. The trailing
        // `AND NOT /news/` and the planyourvisit exceptions spare real park news,
        // events, and fire/flood/closure alerts (golden-validated 0/801 FP).
        if matches(value, .npsHost)
            && (
                matches(value, .npsReferenceDirectory)
                    || (matches(value, .npsLearn) && !matches(value, .npsLearnNews))
                    || (matches(value, .npsPlanYourVisit)
                        && !matches(value, .npsPlanYourVisitException))
                    || matches(value, .npsArticlesOrSubjects)
            )
            && !matches(value, .newsPath) {
            return true
        }

        // mig 547: machine-translated locale twins of civic pages
        if isLocaleVariantURL(value) {
            return true
        }

        // mig 562: archived/reference material is never current news
        if isArchivedReferenceURL(value) {
            return true
        }

        // mig 574: transactional web-app surfaces (portal-as-news). DATA, not
        // EVENTS: CGI binary queries, search RESULTS pages, GIS map viewers,
        // e-forms / request trackers. gemma fabricates a plausible lede from
        // any structured page it is handed (the invented-"Monday" class, arm
        // portal_tool_page_pub mig 566). Precision-verified over the full
        // corpus: every match is the portal class. Do NOT add bare /cgi-bin/
        // or /forms/ — they match docquery.fec.gov campaign-finance filings,
        // which are legitimate primary-source documents.
        // The asp predicate carries an explicit English-word negative guard
        // (adversarial review 574: '(form|tracker)\.asp' alone matches
        // reform.asp/inform.asp/platform.asp — 0 corpus hits today, but this
        // is a permanent hard-reject and POSIX ERE has no lookbehind).
        // mig 593: athletic/institutional ROSTER pages — player & coach bios,
        // season rosters, jail booking rosters (roster_details). Directory
        // shapes, never stories; gemma drafts evergreen bios and years-old
        // seasons as current news (overnight 2026-07-25: reader-flagged BYU
        // bio with fabricated name; corpus FP check 154/154 roster-class,
        // 0 real news; 44 slug-embedded 'roster' controls correctly unmatched).
        if matches(value, .roster)
            || matches(value, .rosterDetails)
            || matches(value, .executableQuery)
            || matches(value, .searchQuery)
            || matches(value, .esriMap)
            || (matches(value, .aspPortal)
                && !matches(value, .aspEnglishWordGuard)) {
            return true
        }

        // mig 594: EMPTY-TRAILING-ID-PARAM default report view — an unfiltered
        // report/listing GENERATOR at its default state (year selector set, the
        // subject id UNSET): aggregate table, no event, no date, so the model
        // invents both. mig 578 added this shape to the ARM only; this is the
        // matching ENFORCEMENT. 12/12 corpus matches are the class, 0 FP.
        // The `&` and the `$` anchor are LOAD-BEARING — see the header. Do NOT
        // relax to a bare `?...id=`: that matches real CivicPlus DocumentCenter
        // documents and FEC filings.
        if matches(value, .emptyTrailingID) {
            return true
        }

        // mig 924: waterrights portal class closure. BOTH rules hostname-
        // anchored to *.waterrights.utah.gov (companyId/station_id are
        // generic elsewhere). /forms/ is the Division's e-form APP namespace
        // (adjudicated); genuine notices live under /cgi-bin/, left open.
        if matches(value, .waterRightsQuery)
            || matches(value, .waterRightsNamespace) {
            return true
        }

        // mig 925: congress.gov member pages = bio/roster surfaces (mig 593
        // law); /bill/ archives are handled by is_archived_reference_url.
        if matches(value, .congressMember) {
            return true
        }

        // mig 928: CivicPlus section pages (civicplus section shape) —
        // /<digits>/<Slug> on a municipal .gov/.us host. Department/program
        // directories, never stories; gemma fabricates dates from them.
        // Year-like first segments (19xx/20xx) are EXCLUDED: /2026/slug is a
        // real news URL shape. CivicAlerts.aspx does not match (extension).
        if matches(value, .civicPlusSection)
            && !matches(value, .civicPlusYearPath) {
            return true
        }

        // NOTE (mig 1325): the DB consolidated EVERY listing/index shape — migs
        // 957, 1128, 1170, 1207, 1227 plus the two 1325 shapes — into
        // pipeline.is_listing_page_url, and is_non_news_source_url now carries a
        // single delegating clause. That function is where the NEXT listing shape
        // lands on the DB side. Swift keeps the clauses inlined below so this
        // function stays reviewable clause-by-clause in SQL order against the
        // parent; the app-side listing grouping is the sibling predicate
        // `isListingIndexURL` (which parses the URL and is a deliberate superset
        // on query tails), NOT this function. Add a new listing shape to BOTH.

        // mig 957: author-archive + pagination TERMINAL shapes. An
        // /author/<name> index or a /page/<N> archive tail is a LISTING, not
        // a story — gemma composes mashup digests and republishes deep
        // archives from them (steward 086e4906; 20/20 live matches junk,
        // 0 FP). Terminal-anchored on purpose: a /page/N/ mid-path or a
        // '/page-…' slug never matches.
        if matches(value, .authorArchive)
            || matches(value, .terminalPagination) {
            return true
        }

        // mig 1014: native ad-network / RTB click hosts. A publisher page carries a
        // RevContent / MediaForce "Sponsored Content" widget; the listing enumerator
        // (url-list-extraction-service) harvests those outbound links as article
        // candidates, and gemma drafts the advertorial as local news. 27 rows, 15 live,
        // including one promoted to multi_source on outlet_domains={mfadsrvr.com,
        // revcontent.com} — two AD NETWORKS counted as two independent outlets.
        // Reader flag 395456a6: "Not news. This is an ad." Host list:
        // pipeline.ad_network_etld1s(). Do NOT narrow this to revcontent.
        if isAdNetworkURL(value) {
            return true
        }

        // mig 1118: SPEAKER BIO INDEX pages (speeches.byu.edu/speakers/<name>).
        // Same class as mig 593 rosters and mig 925 congress.gov/member/: a
        // directory entry ABOUT A PERSON, never an event, usually undated — so
        // every date gate on the platform sees nothing to refuse while gemma
        // turns it into a present-tense claim about that person today. Reader
        // flag 730a4892: "John Hughes serves as editor of the Deseret News",
        // drafted 2026-08-31 from a bio whose own body cites a 1998 speech.
        // Corpus at authoring: 37 such URLs, 20 articles born, 19 of them
        // archived / rejected / permanently stuck as drafts. Host-anchored on
        // purpose: the general '/speakers/<slug>$' shape is clean over the
        // whole corpus (48/48) but costs one legitimate appointment story on
        // speeches.ensign.edu, so widening it is Mark's call, not this file's.
        // This exact raw-string clause includes isReferenceBioURL's SQL twin;
        // the existing URL-parsing predicate remains unchanged.
        if matches(value, .speakerBio) {
            return true
        }

        // mig 1128: CMS TAG/CATEGORY INDEX pages, terminal-anchored (mig 957
        // law: a LISTING ends the path; a /category/<base>/<story-slug>
        // permalink continues past it and never matches). gemma composes
        // "archive digest" mashups from these (Lehi audit 2026-08-31:
        // 15/15 sampled drafts = the class; 0 FP over the 704 deeper-path
        // controls). Covers /tag/, /tags/, /category/, /categories/.
        // Pagination tails (/tag/x/page/2) already match the mig 957 rule;
        // query-string tails (/tag/x/?utm=…) are a documented miss.
        // These exact raw-string clauses include isListingIndexURL's SQL twin;
        // calling that URL-parsing predicate would erase the documented query miss.
        if matches(value, .tagIndex)
            || matches(value, .categoryIndex) {
            return true
        }

        // NOTE (DB-only clause, deliberately NOT ported):
        // pipeline.is_non_news_source_url's mig1170 arm reads the live media-host
        // set (pipeline.is_media_host over city_institutions); a Swift snapshot
        // drifts both ways, so Swift UNDER-refuses this one class by design — the
        // publish gate remains the backstop.

        // mig1207-apptegy: Thrillshare/Apptegy school LISTING pages
        // (host-agnostic, path-anchored). Org root; news|live-feed
        // hubs with optional path tail; exact hubs events|staff|
        // faculty-and-staff|athletics|calendar|browse; /page/<slug>.
        // Real stories at /o/<org>/article/<digits> do NOT match;
        // /browse/<digits> and /events/detail/<id> stay news.
        if matches(value, .apptegyRoot)
            || matches(value, .apptegyNewsOrLiveFeed)
            || matches(value, .apptegyExactHub)
            || matches(value, .apptegyPage) {
            return true
        }

        // mig1227-wordpress: WordPress LISTING pages (host-agnostic,
        // path-anchored, query-string ignored). /author|/tag|/category
        // /<slug> optional /page/N; plus terminal /page/N with dated
        // multipage-story carve-out (1170). Real permalinks that continue
        // past /category/<base>/<story-slug> do NOT match. Intake stays
        // open — drafting band + Rule 10c only.
        if matches(value, .wordpressTaxonomy)
            || (matches(value, .wordpressPagination)
                && !matches(value, .datedPath)) {
            return true
        }

        // mig 1325 (a): school-calendar VIEW pages. Finalsite renders a
        // day/week/month VIEW of a calendar at /eventsbyday/<Y>/<M>/<D>.html,
        // /eventsbyweek/…, /eventsbymonth/… . It ENUMERATES events, is never a
        // story, and it always renders "today", so every date gate on the
        // platform sees a live page while gemma writes a present-tense digest
        // ("MHS Events Calendar Lists Upcoming Athletic and District
        // Activities"). Measured (spec, 2026-09-05): 27 items/7 d on
        // www.ssanpete.org, 8 live published calendar pages; re-verified
        // db-ro 2026-09-06: 33 processed_items/7 d over 2 hosts (31 of them
        // ssanpete), 9 published articles. The TRAILING SLASH is load-bearing:
        // it keeps an /eventsbyday-recap-story slug out of the class. Child
        // event pages (/events/detail/<id>) are untouched and stay news.
        if matches(value, .calendarView) {
            return true
        }

        // mig 1325 (b): bare news-INDEX roots, TERMINAL-anchored (mig 957 law —
        // a listing ENDS the path). /news, /latest-news, /news-releases,
        // /newsroom, /press-releases and their unhyphenated twins are a site's
        // newsroom INDEX; gemma drafts a mashup digest of whatever the index
        // happened to list ("Newsroom - West Jordan City", "Press Releases").
        // Measured (spec, 2026-09-05): 608 bare /news$ items/30 d, 62 live
        // published index digests; re-verified db-ro 2026-09-06: 609 bare
        // /news$ items/30 d, 706/30 d over 506 hosts for the whole clause,
        // 169 published rows. A dated permalink continues past the root
        // (/news/2026/09/05/slug) and never matches; a query-string tail
        // (/news?id=123) is the DOCUMENTED terminal-anchor miss, left open on
        // both sides. Same unanchored-$ direction: the clause can land inside a
        // query/fragment tail (…/real-story?utm_source=/news) — 0 corpus rows,
        // and the 1227-style '(\?[^#]*)?(#.*)?$' tail does NOT fix it, so it is
        // recorded rather than patched. FALSE POSITIVE accepted: category-last
        // CMS permalinks (…/<id>/<slug>/news), 2 URLs corpus-wide, both
        // archived and non-Utah.
        if matches(value, .newsIndexRoot) {
            return true
        }

        // mig 1330 (a): CivicPlus BLOG LISTING views. Blog.asp[x] takes IID=<blog
        // index>, CID=<category listing> and ARC=<archive page>; a single POST
        // carries BID=<n>. SIX copies of one Millcreek post were drafted from six
        // archive views (IID=1&ARC=1/2/3, IID=2&ARC=4, CID=2&ARC=1/2) — the
        // archived-alert rule [?&]ARC=[0-9]+ is scoped to CivicAlerts.aspx and
        // never sees Blog.asp[x]. The single-post exemption is evaluated with the
        // match, exactly as the DB writes it INSIDE one clause, so an edit cannot
        // keep the match and lose the carve-out. Measured (db-ro 2026-09-06):
        // 30 Blog.asp[x] URLs / 30 d, 23 listing views, ZERO carrying BID.
        // DOCUMENTED MISS: the ARC=L archive-INDEX form carries no numeric
        // parameter and stays FALSE on both sides.
        if matches(value, .blogListingView) && !matches(value, .blogSinglePost) {
            return true
        }

        // mig 1330 (b): BOXSCORE / GAMECAST placeholder pages, host-agnostic and
        // terminal-or-continuing (a ?tab=boxscore tail still matches). A boxscore
        // page is the scoreboard RECORD of a fixture, not a story: it renders for a
        // game that has NOT been played (a Sept 19 2026 fixture was drafted with
        // invented scores) and identically for a 2020 game. Results belong to an
        // outlet story. Measured (db-ro 2026-09-06): 55 distinct URLs, 74 articles,
        // 0 false positives; /gamecast/ matched nothing live and is carried
        // pre-emptively, unanchored like newsIndexRoot.
        if matches(value, .gameBoxscore)
            || matches(value, .gameIdRecord)
            || matches(value, .gamecastRecord) {
            return true
        }

        // mig 1338 (1): PMN PUBLIC-BODY SITEMAP PAGES. Utah's Public Meeting Notice
        // site publishes, per public body, an INDEX of that body's notices — a LIST
        // of notices, never a notice. gemma drafts "Heber City Council Lists
        // Upcoming and Past Meeting Notices" and, off the body's member roster,
        // BIOS. Measured (db-ro 2026-09-06): 921 distinct URLs / 30 d on one host,
        // 628 articles (128 open drafts, 31 live published). The NOTICE itself
        // (/pmn/sitemap/notice/<id>.html, 5,766 / 30 d) and its attachments
        // (/pmn/files/<id>.pdf) are real primary sources and stay news.
        if matches(value, .pmnPublicBodyIndex) {
            return true
        }

        // mig 1338 (2): CMS RELATED-ITEMS FILTER LISTINGS. related.html?filter=<tag>
        // is the site's related-content endpoint rendering a TAG VIEW; gemma
        // composes a mashup digest of whatever the filter returned. Measured
        // (db-ro 2026-09-06): 361 URLs all-time, ALL on one host (www.suu.edu) —
        // the clause is written host-agnostically because related.html?filter=
        // names a CMS endpoint, but there is no second host in the corpus.
        // filter= is lossless: 0 related.html URLs all-time lack it.
        if matches(value, .relatedFilterListing) {
            return true
        }

        // mig 1338 (3): CivicPlus Archive.asp[x] ARCHIVE MODULE INDEXES. AMID = the
        // archive MODULE (index of one archive list); ADID = one archived DOCUMENT
        // and is 3,466 distinct URLs / 30 d of real agenda/minutes landings that
        // must never be swallowed. Two guards: amid=[0-9]+ cannot match ?ADID=, and
        // the paired exemption is the belt. DEFENSIVE, NOT FIELD-VALIDATED: zero
        // URLs all-time carry a numeric AMID and a numeric ADID.
        if matches(value, .archiveModuleIndex) && !matches(value, .archiveDocumentId) {
            return true
        }

        // mig 1338 (4): CivicPlus module/events.htm CALENDAR-DAY VIEWS — the
        // CivicPlus twin of the Finalsite /events?by(day|week|month)/ rule. Measured
        // (db-ro 2026-09-06): 82 distinct URLs / 30 d over 4 hosts, split 46
        // calendar views (bare, or a day=/month=/year= selector; source_title is
        // literally "Calendar") and 36 SINGLE EVENTS carrying eventId=<n>. The
        // single-event form is the CivicPlus shape of /events/detail/<id>, kept as
        // news by mig 1325, so it is exempted with the match.
        if matches(value, .eventsModuleCalendar) && !matches(value, .eventsModuleSingleEvent) {
            return true
        }

        // mig 1338 (6): /in-the-news SECTION ROOTS, TERMINAL-anchored under the mig
        // 957 law (a listing ENDS the path). Measured (db-ro 2026-09-06): 18 corpus
        // URLs, 16 of them newly refused, every one a section root. DOCUMENTED MISS
        // LEFT OPEN ON PURPOSE: the hyphen-prefixed form (cce-in-the-news,
        // crimson-view-in-the-news/, esa-in-the-news/, …, 7 corpus URLs) is the same
        // class, but widening to [-/]in-the-news would make FALSE POSITIVES of real
        // stories whose SLUG ends in the phrase (age-verification-in-the-news,
        // housing-and-climate-crosswinds-in-the-news.html). The leading slash is the
        // only discriminator; do not widen it.
        if matches(value, .inTheNewsRoot) {
            return true
        }

        // mig 1342 (1): CivicPlus /FormCenter/ FORM PAGES. A form is not a source —
        // the event or decision behind it (a pumpkin-walk vendor call, a gingerbread
        // contest, a tribute collection, a GRAMA request portal) belongs to the city's
        // news release, agenda or calendar page. The form page is the INSTRUMENT, and
        // it is undated and standing, so every date gate sees a live page while gemma
        // writes a present-tense "City Releases 2026 Pumpkin Walk Food Truck
        // Applications" out of a web form — published TWICE, off the bare-host and www
        // spellings of one URL. Measured (db-ro 2026-09-06): 313 distinct URLs / 30 d
        // over 46 CivicPlus civic hosts and zero non-civic hosts, 373 all-time; 54
        // articles, 6 live published (5 post-928). ONE class, three spellings: the FORM
        // leaf, the CATEGORY page and the bare /FormCenter root (24 URLs all-time). The
        // leading slash is the only discriminator — …/news/formcenter-opens-downtown
        // and /reformcenter/ stay news — and the hyphen-prefixed …-formcenter form is a
        // DOCUMENTED MISS left open on purpose (0 corpus URLs, so it costs nothing
        // today). Same law as mig 1338's /in-the-news decision: do not widen to [-/].
        if matches(value, .civicPlusFormCenter) {
            return true
        }

        // mig 1342 (2): CivicPlus Faq.asp[x] EXPLAINER PAGES. A FAQ entry (?QID=<n>), a
        // FAQ topic view (?TID=<n>) and the bare FAQ index are the same thing: STANDING
        // ANSWERS, undated, rewritten as news. A Moab COVID-era FAQ answer was
        // published as a July 2026 story, a bare index became "SL County DA Prosecutes
        // Arson Charges in Murray", and four near-duplicate Bees-Stadium mashups came
        // off four FAQ entries of one host. All 18 live published rows were read at
        // authoring and NOT ONE is a dated notice that merely lives at Faq.aspx, so
        // nothing was narrowed. Measured (db-ro 2026-09-06): 359 distinct URLs / 30 d
        // over 53 hosts (QID 245 / TID 96 / bare index 18), 423 all-time; 77 articles,
        // 18 live published (9 post-928). Anchored on the CivicPlus MODULE file name;
        // the x? also admits the legacy .asp spelling. The terminator is lossless over
        // the corpus (0 URLs carry anything after .aspx but ? or the end) and keeps
        // /faq.aspxyz and …/blog/faq.aspx-explained FALSE. LEFT OPEN ON PURPOSE: the
        // same editorial class on non-CivicPlus CMSes — terminal /faq|/faqs (126 URLs
        // / 30 d) and /faq.html|.php (85) — is a ~211-URL blast radius across arbitrary
        // CMSes and needs its own census and sample read; do not fold it in here.
        if matches(value, .civicPlusFaqPage) {
            return true
        }

        // mig 1342 (3): GOOGLE DRIVE FOLDER LISTINGS. A folder page is a FILE INDEX —
        // "Folder - Google Drive" is the literal source_title of 34 of the 62 corpus
        // URLs — and the enumerator harvests EVERY FILE INSIDE IT: the Cache County COG
        // archive alone produced 13 stale rejects, 2016–2023 documents surfaced with
        // the crawl date, and every one of them was a /file/d/ or /open?id= FILE
        // harvested off the folder. Closing the folder page closes the faucet. Measured
        // (db-ro 2026-09-06): 62 distinct URLs / 30 d across 14 distinct cities and 9
        // sources, 129 all-time; 1 article (rejected), 0 live published. HOST-ANCHORED,
        // so a civic site's own /drive/folders/ path and notdrive.google.com.evil.com
        // are FALSE; id-requiring, so /drive/my-drive is FALSE; the bounded segment
        // skip covers /drive/folders/, /drive/u/0/folders/ and /drive/mobile/folders/.
        // THE FILES STAY NEWS: /file/d/ and /open?id= are primary sources — live
        // published 2260971a (Boulder Town Truth-in-Taxation, 2026-09-05) is one.
        // docs.google.com has ZERO folder-like listings in the corpus and gets no
        // clause, and docs.google.com/forms is migration 1333's, refused at INTAKE.
        if matches(value, .googleDriveFolder) {
            return true
        }

        // mig 1346 (1): bsky.app PROFILE ROOTS — and ONLY roots. A profile root is the
        // reverse-chronological INDEX of one account's posts: the social-platform form
        // of mig 957's /author/<name> archive. A /post/<id> permalink CONTINUES past the
        // handle and stays news, which is why the clause is anchored at the END of the
        // URL. Measured (db-ro 2026-09-06; for this host 30 d == all-time): 13 distinct
        // URLs — 11 profile roots, 2 posts. 3 articles: both profile-root articles were
        // REJECTED by the editor ("Institution's Bluesky profile page — not a dated
        // story"; and c714d0c9, a profile paraphrasing a Chrony report), while the one
        // PUBLISHED article is a POST — d67a378a, which the live editor published on
        // 2026-09-06 as a primary source (an author's own statement about withdrawing
        // from a Weber State engagement). 0 live published rows are refused, 0 drafts.
        // WHY THIS IS A SHAPE AND NOT A CATALOG ROW — mig 1341 DECISION (C), recorded
        // verbatim and implemented here: the `junk_park_hosts` PATH branch ALWAYS
        // appends a trailing %, so the catalog literally cannot express "profile root
        // but not /post/". bsky.app therefore gets NO catalog row, which is exactly what
        // keeps the editor's published POST open at intake. HOST-ANCHORED TO bsky.app ON
        // PURPOSE: x.com (362 items / 30 d), twitter.com (147), facebook.com (396),
        // instagram.com (21), threads.com (4) and threads.net (1) are UNDECIDED — mig
        // 1341 (C) left them open because institutional feeds (NWSSaltLakeCity, police
        // departments) live there, and facebook.com additionally carries the Tooele
        // attribution problem. A generic /<handle>$ shape would decide all six hosts by
        // the back door. DO NOT WIDEN.
        if matches(value, .bskyProfileRoot) {
            return true
        }

        // mig 1346 (2a): Finalsite month/day/week CALENDAR VIEW pages. mig 1325 closed
        // /events?by(day|week|month)/; the SAME two Finalsite hosts emit a second view
        // spelling that clause never saw. Measured (db-ro 2026-09-06): 19 distinct URLs
        // all-time / 8 in the last 30 d on www.ssanpete.org (17) and www.piutek12.org
        // (2), both spellings live (/monthcalendar/2026/9.html and
        // /calendar/monthcalendar/2026/8/-.html); 0 already-true. 9 articles: 6 archived
        // + 1 rejected + 2 LIVE PUBLISHED, and BOTH live rows were read in full — they
        // are calendar DIGESTS, not stories: 28bce3f5 (post-928, adjudicated by the
        // migration) opens "An undated events calendar on the South Sanpete School
        // District website lists several scheduled activities", and 29e76215 (pre-928,
        // the editor's separate call) is the May 2026 twin. NOTHING WAS NARROWED: both
        // are the class mig 1325 already refuses one spelling of. `day`/`week` match 0
        // corpus URLs today and are carried PRE-EMPTIVELY by symmetry with mig 1325's
        // own (day|week|month) triple on the SAME module — the mig 1330 /gamecast/
        // precedent. `list` is NOT carried (no evidence, no symmetry). THE TRAILING
        // SLASH IS LOAD-BEARING and is what keeps three real stories FALSE:
        // nationaldaycalendar.com/celebrations/national-hot-dog-day-… (the token is in
        // the HOST, with no preceding slash), a kutv.com slug reading months-after, and
        // a deseret.com slug reading monthly.
        if matches(value, .finalsiteXCalendarView) {
            return true
        }

        // mig 1346 (2b): Finalsite YEAR view. mig 1325's clause is (day|week|month)
        // ONLY, so eventsbyyear was never covered. Token census over the whole corpus
        // (db-ro 2026-09-06): eventsbyday 129 URLs (129 already true), eventsbyweek 28
        // (28 already true), eventsbyyear 7 (0 already true) — 2 in the last 30 d, 2
        // hosts, 0 articles EVER. The s? mirrors mig 1325's own events?by spelling.
        if matches(value, .finalsiteEventsByYear) {
            return true
        }

        // mig 1346 (2c): CMS-AGNOSTIC calendar day/week/month VIEW path. Measured
        // (db-ro 2026-09-06): 43 distinct URLs all-time over 3 hosts — joejencks.com 35
        // (a touring musician's day views), smithfieldutah.gov 7 (a Utah city's month
        // views), events.suu.edu 1 (a Localist day view) — 0 already-true, 0 articles
        // EVER. HONESTY REQUIRED: 42 of the 43 came from a single 2026-02-21 sweep and
        // only ONE sits inside the 30-day census window, so this clause is carried on
        // shape rather than on live harm. Its warrant is (i) it is the CMS-agnostic form
        // of the exact class 2a demonstrably PUBLISHED TWICE, and (ii) it has 0 false
        // positives corpus-wide — every one of the 43 matches is a calendar view. That
        // is strictly better evidenced than mig 1330's /gamecast/ arm, which was carried
        // at zero corpus URLs. The slash AFTER the keyword is load-bearing:
        // /calendar/monthly-report-2026.pdf and a bare /calendar.html are FALSE.
        //
        // MEASURED AND LEFT OPEN ON PURPOSE (do not fold these in without a census):
        // ?view=(day|week|month) and calendarview have ZERO corpus URLs all-time — a
        // bare [?&]view=month could match a non-calendar CMS page, so the FP risk is
        // unbounded and the benefit is zero. provo.edu's …/school-calendar/
        // a-b-calendar-month-view/ is 4 URLs on 2 hosts of ONE district / ONE eTLD+1,
        // with 2 articles both archived AND already soft-deleted, 0 live published, and
        // 1 of the 4 already TRUE via the mig 547 /es/ locale rule — one CMS page slug
        // is not a shape (mig 1338's law) and it reduces no measured live harm (mig
        // 1341 (A)'s law). /listcalendar/ is not carried. All three are pinned as FALSE
        // controls so the next widener re-reads this paragraph.
        if matches(value, .calendarDayWeekMonthView) {
            return true
        }

        // Docket-record and URL-parsed listing refusal remain sibling predicates;
        // composing either here would make this function a superset of the DB twin.
        return false
    }

    private enum RegexClause: String, CaseIterable, Sendable {
        case emailContactForm = #"/(email-form|contact-form)(/|$|\?)"#
        case districtOfficeDirectory = #"/district-office-directory/"#
        case legalBoilerplate = #"/(privacy|privacy-policy|terms|terms-of-service|terms-of-use)(/|$|\?)"#
        case staffRoster = #"/(staff|faculty|our-team|leadership|board-members)(/|$|\?)"#
        case npsHost = #"://(www\.)?nps\.gov/"#
        case npsReferenceDirectory = #"/(getinvolved|management|aboutus|teachers|kids|education|photosmultimedia|bookstore|historyculture)/"#
        case npsLearn = #"/learn/"#
        case npsLearnNews = #"/learn/news/"#
        case npsPlanYourVisit = #"/planyourvisit/"#
        case npsPlanYourVisitException = #"(event-details|calendar|conditions|alert|status|closure|fees|hours|current)"#
        case npsArticlesOrSubjects = #"nps\.gov/(articles|subjects)/"#
        case newsPath = #"/news/"#
        case localeVariant = #"://[^/]+/(de|fr|ru|ja|es|pt|zh|ko|vi|ar|it|nl|pl|tl|hi|fa|sm|to)(-[a-z]{2})?(/|$)"#
        case archiveHost = #"://(www\.)?(web\.archive\.org|archive\.org|archive\.sltrib\.com)/"#
        case presidencyHost = #"://(www\.)?presidency\.ucsb\.edu/"#
        case bhRobertsHost = #"://(www\.)?bhroberts\.org/"#
        case pmcHost = #"pmc\.ncbi\.nlm\.nih\.gov"#
        case pmcArticle = #"/pmc/articles/"#
        case congressHost = #"congress\.gov"#
        case congressSessionCapture = #"/(\d{1,3})(?:th|st|nd|rd)-congress(/|$)"#
        case civicAlerts = #"civicalerts\.aspx?"#
        case archivedCivicAlert = #"[?&]ARC=[0-9]+(&|$)"#
        case utahLegislatureArchive = #"://(www\.)?le\.utah\.gov/av/(floor|committee)Archive\.jsp"#
        case utahLegislatureVotes = #"://(www\.)?le\.utah\.gov/DynaBill/svotes\.jsp"#
        case legislativeSessionCapture = #"[?&][Ss]essionid=(\d{4})"#
        case roster = #"/roster(s)?(/|$|\?)"#
        case rosterDetails = #"roster_details"#
        case executableQuery = #"\.exe\?"#
        case searchQuery = #"/search/?\?q="#
        case esriMap = #"/esrimap/"#
        case aspPortal = #"(form|tracker)\.asp"#
        case aspEnglishWordGuard = #"(reform|uniform|inform|perform|transform|platform|conform)\.asp"#
        case emptyTrailingID = #"\?[^#]*&[a-z_]*id=$"#
        case waterRightsQuery = #"://([a-z0-9-]+\.)*waterrights\.utah\.gov/[^#?]*\?([^#&]*&)*(chnum|companyid|station_id)="#
        case waterRightsNamespace = #"://([a-z0-9-]+\.)*waterrights\.utah\.gov/(miscinfo|wrinfo|distinfo|streamdb|forms|asp_apps)/"#
        case congressMember = #"://([a-z0-9-]+\.)*congress\.gov/member/"#
        case civicPlusSection = #"://[^/]+\.(gov|us)/[0-9]{2,5}/[A-Za-z][A-Za-z-]*$"#
        case civicPlusYearPath = #"://[^/]+/(19|20)[0-9]{2}/"#
        case authorArchive = #"/authors?/[^/?#]+/?$"#
        case terminalPagination = #"/page/[0-9]+/?$"#
        case adNetwork = #"^https?://([a-z0-9_-]+\.)*(revcontent\.com|mfadsrvr\.com|doubleclick\.net|taboola\.com|outbrain\.com|mgid\.com|zergnet\.com|content\.ad|adblade\.com|nativo\.com|googlesyndication\.com)([:/?#@]|$)"#
        case speakerBio = #"://([a-z0-9-]+\.)*speeches\.byu\.edu/speakers/"#
        case tagIndex = #"/tags?/[^/?#]+/?$"#
        case categoryIndex = #"/categor(y|ies)/[^/?#]+/?$"#
        case apptegyRoot = #"^https?://[^/]+/o/[a-z0-9_-]+/?$"#
        case apptegyNewsOrLiveFeed = #"^https?://[^/]+/o/[a-z0-9_-]+/(news|live-feed)(/.*)?$"#
        case apptegyExactHub = #"^https?://[^/]+/o/[a-z0-9_-]+/(events|staff|faculty-and-staff|athletics|calendar|browse)/?$"#
        case apptegyPage = #"^https?://[^/]+/o/[a-z0-9_-]+/page/[a-z0-9_-]+/?$"#
        case wordpressTaxonomy = #"^https?://[^/?#]+/(author|tag|category)/[^/]+(/(page/[0-9]+))?/?(\?[^#]*)?(#.*)?$"#
        case wordpressPagination = #"^https?://[^/?#]+(?:/[^/?#]+)*/page/[0-9]+/?(\?[^#]*)?(#.*)?$"#
        case datedPath = #"/(19|20)[0-9]{2}/"#
        case calendarView = #"/events?by(day|week|month)/"#
        case newsIndexRoot = #"/(news|latest-?news|news-?releases?|newsroom|press-?releases?)/?$"#
        // mig 1330 (a): CivicPlus BLOG LISTING views. IID = blog index, CID =
        // category listing, ARC = archive page; a single POST carries BID=<n>.
        case blogListingView = #"/blog\.aspx?\?([^#]*&)?(iid|cid|arc)=[0-9]+"#
        case blogSinglePost = #"[?&]bid=[0-9]+"#
        // mig 1330 (b): boxscore / gamecast placeholder pages, host-agnostic.
        case gameBoxscore = #"-game-boxscore-[0-9]+"#
        case gameIdRecord = #"/game/_/gameId/"#
        case gamecastRecord = #"/gamecast/"#
        // mig 1338 (1): PMN public-body sitemap INDEX pages.
        case pmnPublicBodyIndex = #"/pmn/sitemap/publicbody/"#
        // mig 1338 (2): CMS related-items FILTER listings.
        case relatedFilterListing = #"/related\.html\?([^#]*&)?filter="#
        // mig 1338 (3): CivicPlus Archive.asp[x] archive MODULE index; the single
        // archived DOCUMENT (ADID) is exempted by the paired clause.
        case archiveModuleIndex = #"/archive\.aspx?\?([^#]*&)?amid=[0-9]+"#
        case archiveDocumentId = #"[?&]adid=[0-9]+"#
        // mig 1338 (4): CivicPlus module calendar VIEW; a single EVENT (eventId)
        // is exempted by the paired clause.
        case eventsModuleCalendar = #"/module/events\.htm(\?|$)"#
        case eventsModuleSingleEvent = #"[?&]eventid=[0-9]+"#
        // mig 1338 (6): /in-the-news SECTION ROOTS, terminal-anchored.
        case inTheNewsRoot = #"/in-the-news(/index)?(\.php|\.html?)?/?$"#
        // mig 1342 (1): CivicPlus /FormCenter/ form pages — a form is not a source.
        case civicPlusFormCenter = #"/formcenter(/|\?|#|$)"#
        // mig 1342 (2): CivicPlus Faq.asp[x] explainer pages (?QID=, ?TID=, bare index).
        case civicPlusFaqPage = #"/faq\.aspx?(\?|#|$)"#
        // mig 1342 (3): Google Drive FOLDER listings. HOST-BEARING, so
        // listingIndexReason must match this one against the WHOLE URL — url.path
        // drops the host. Files (/file/d/, /open?id=) stay news: live published
        // 2260971a is one.
        case googleDriveFolder = #"^https?://([a-z0-9-]+\.)*drive\.google\.com/drive/([^/?#]+/){0,3}folders/[^/?#]"#
        // mig 1346 (1): bsky.app PROFILE ROOTS. HOST-BEARING **and** END-ANCHORED, so
        // listingIndexReason must match this one against the WHOLE URL — url.path drops
        // the host, and the anchor is the only thing separating a profile INDEX from a
        // POST. The editor PUBLISHED a bsky POST as a primary source (d67a378a) — that
        // URL must stay news on both predicates.
        case bskyProfileRoot = #"^https?://(www\.)?bsky\.app/profile/[^/?#]+/?(\?[^#]*)?(#.*)?$"#
        // mig 1346 (2a): Finalsite month/day/week calendar VIEW pages — the spellings
        // mig 1325's /events?by(day|week|month)/ clause never saw. The trailing slash is
        // load-bearing.
        case finalsiteXCalendarView = #"/(day|week|month)calendar/"#
        // mig 1346 (2b): Finalsite YEAR view — mig 1325's clause is (day|week|month) only.
        case finalsiteEventsByYear = #"/events?byyear/"#
        // mig 1346 (2c): CMS-agnostic calendar day/week/month VIEW path.
        case calendarDayWeekMonthView = #"/calendar/(day|week|month)/"#

        // Source-title archive detection is independent of the URL predicates.
        case indexTitleSeparator = #"\s+[|\-–—:»]\s+"#
        case indexTitleMonthYear = #"^(january|february|march|april|may|june|july|august|september|october|november|december)\s+(19|20)\d{2}$"#
        case indexTitleDay = #"^(january|february|march|april|may|june|july|august|september|october|november|december)\s+\d{1,2},?\s+(19|20)\d{2}$"#
        case indexTitleBareMonth = #"^(january|february|march|april|may|june|july|august|september|october|november|december)$"#
        case indexTitleByPeriod = #"\bby (year|month|date)$"#

        var options: NSRegularExpression.Options {
            switch self {
            case .congressSessionCapture, .legislativeSessionCapture:
                []
            default:
                [.caseInsensitive]
            }
        }
    }

    private static let regexCompilation: (
        table: [(NSRegularExpression, clauseLabel: RegexClause)],
        failures: [String]
    ) = {
        var table: [(NSRegularExpression, clauseLabel: RegexClause)] = []
        var failures: [String] = []

        for clause in RegexClause.allCases {
            guard let expression = try? NSRegularExpression(
                pattern: clause.rawValue,
                options: clause.options
            ) else {
                failures.append(String(describing: clause))
                continue
            }
            table.append((expression, clause))
        }

        return (table, failures)
    }()

    private static let compiledRegexTable: [(NSRegularExpression, clauseLabel: RegexClause)] =
        regexCompilation.table

    private static let compileFailures: [String] = regexCompilation.failures

    /// Test hook ensuring no invalid pattern can silently under-refuse a URL.
    nonisolated static var nonNewsRegexCompileFailures: [String] {
        compileFailures
    }

    private nonisolated static func matches(_ value: String, _ clause: RegexClause) -> Bool {
        guard let expression = compiledRegexTable.first(where: { $0.clauseLabel == clause })?.0 else {
            return false
        }
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        return expression.firstMatch(in: value, options: [], range: range) != nil
    }

    private nonisolated static func firstCapture(
        in value: String,
        clause: RegexClause
    ) -> String? {
        guard let expression = compiledRegexTable.first(where: { $0.clauseLabel == clause })?.0,
              let match = expression.firstMatch(
                in: value,
                options: [],
                range: NSRange(value.startIndex..<value.endIndex, in: value)
              ),
              match.numberOfRanges > 1,
              let captureRange = Range(match.range(at: 1), in: value) else {
            return nil
        }
        return String(value[captureRange])
    }

    private nonisolated static func isLocaleVariantURL(_ urlString: String) -> Bool {
        matches(urlString, .localeVariant)
    }

    /// Port of the live body last extended by migration 793. Capture regexes
    /// remain case-sensitive where PostgreSQL used `regexp_match` rather than
    /// `~*`; the surrounding host predicates remain case-insensitive.
    private nonisolated static func isArchivedReferenceURL(_ urlString: String) -> Bool {
        if matches(urlString, .archiveHost)
            || matches(urlString, .presidencyHost)
            || matches(urlString, .bhRobertsHost)
            || matches(urlString, .pmcHost)
            || matches(urlString, .pmcArticle) {
            return true
        }

        if matches(urlString, .congressHost),
           let sessionText = firstCapture(
            in: urlString,
            clause: .congressSessionCapture
           ),
           let session = Int(sessionText),
           session < 119 {
            return true
        }

        if matches(urlString, .civicAlerts)
            && matches(urlString, .archivedCivicAlert) {
            return true
        }

        if matches(urlString, .utahLegislatureArchive) {
            return true
        }

        if matches(urlString, .utahLegislatureVotes),
           let sessionText = firstCapture(
            in: urlString,
            clause: .legislativeSessionCapture
           ),
           let session = Int(sessionText),
           session < 2026 {
            return true
        }

        return false
    }

    private nonisolated static func isAdNetworkURL(_ urlString: String) -> Bool {
        matches(urlString, .adNetwork)
    }

    /// Evaluates a signal-tier title + snippet pair. Returns `nil` if the
    /// content is clean and worth publishing, or a short reason string
    /// describing the failure (logged + persisted for editorial audits).
    ///
    /// - Parameters:
    ///   - title: The headline as extracted from the outlet.
    ///   - snippet: The body / summary text (may be empty).
    ///   - sourceURL: The article URL — used to detect "title equals
    ///     bare domain" homepage hits.
    public static func garbageReason(title rawTitle: String, snippet: String, sourceURL: String) -> String? {
        let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        // Upstream placeholder titles from signal_only ingest that escaped.
        let placeholders: Set<String> = [
            "Signal-only (news outlet)",
            "No title available",
            "Untitled",
            ""
        ]
        if placeholders.contains(title) {
            return "placeholder title"
        }

        // Court DOCKET RECORD page (2026-08-26). Three independent signals,
        // any one of which is decisive — a docket record is a court FILING
        // LEDGER, not journalism, no matter how well-formed its title reads:
        //   (a) the URL sits in known docket-record space;
        //   (b) the title is the bare "Docket for <case no.>" template;
        //   (c) the body carries >=2 docket form-field labels (re-hosted copy).
        // Placed ahead of the headline-shaped rules on purpose: PACER titles
        // ("Habeas Corpus Petition Filed by …") are perfectly well-formed and
        // would otherwise fall through to `return nil`.
        if isDocketRecordURL(sourceURL) {
            return "court docket record page (docket URL)"
        }

        // SPEAKER BIO INDEX page (2026-08-31, migration 1118). Placed beside the
        // docket rule for the same reason: a bio page's title is a perfectly
        // well-formed person's name ("John Hughes") and would otherwise fall
        // through every headline-shape rule below to `return nil`.
        if isReferenceBioURL(sourceURL) {
            return "speaker bio index page (reference directory, not an event)"
        }

        // LISTING/INDEX page (2026-08-31, migration 1128's tag/category shapes;
        // widened 2026-09-05 by migration 1325 with school-calendar VIEW pages
        // and bare news-INDEX roots). Placed beside the docket/bio rules for the
        // same reason: gemma gives the digest a perfectly news-shaped title
        // ("Lehi Free Press Archives Detail Local Arrest and City Plans",
        // "Newsroom - West Jordan City") that falls through every headline-shape
        // rule below. The reason string is per-shape so an editorial audit can
        // tell the three classes apart; the mig 1128 wording is unchanged.
        if let listingReason = listingIndexReason(sourceURL) {
            return listingReason
        }
        if title.range(
            of: #"^Docket for \d{2}[A-Za-z]?-?\d+\s*$"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil {
            return "court docket record page (docket title)"
        }
        let loweredSnippet = snippet.lowercased()
        let docketFormHits = docketFormMarkers.filter { loweredSnippet.contains($0) }.count
        if docketFormHits >= 2 {
            return "court docket record page (\(docketFormHits) docket form fields)"
        }

        // Bare outlet name → homepage hit.
        let outletName = outletDisplayName(for: sourceURL)
        if let host = URL(string: sourceURL)?.host {
            let stripped = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
            let lowered = title.lowercased()
            if lowered == stripped.lowercased() || lowered == outletName.lowercased() {
                return "title is bare outlet name → homepage"
            }
        }

        // Section / category page: "Opinion - <Outlet>", "Latest - <Outlet>",
        // "News - <Outlet>", "Sports - <Outlet>". Strip the outlet suffix and
        // check what's left.
        let suffixPatterns = [
            " - \(outletName)",
            " — \(outletName)",   // em-dash
            " | \(outletName)"     // pipe
        ]
        let sectionWords: Set<String> = [
            "opinion", "opinions", "latest", "news", "sports",
            "local government", "obituaries", "weather", "video", "podcast",
            "newsletters", "newsletter", "briefing", "subscribe",
            "sections", "categories", "topics", "archives", "tag",
            "about", "contact", "advertise", "home", "search",
            // Sprint BM — institutional/library/nav landing pages.
            "services", "library", "programs", "classes", "staff", "directory",
            "resources", "collections", "events", "calendar", "hours",
            "locations", "documents", "forms", "makerspace", "printing",
            "clubs", "departments", "agendas", "minutes", "meetings",
            "notices", "alerts", "faq", "faqs", "menu"
        ]
        for suffix in suffixPatterns where title.hasSuffix(suffix) {
            let core = String(title.dropLast(suffix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            if sectionWords.contains(core.lowercased()) {
                return "section page (\(core))"
            }
            // "Latest budget proposal..." is fine; only reject when the core
            // IS the section word, not when it merely starts with one.
        }

        // Sprint BM — institutional nav/landing pages use a "Section | Institution"
        // title template that V2 frequently mis-types as an article, e.g.
        // "Makerspace | Ephraim Library", "Home | Lake Mountain School District",
        // "Meetings | Rush Valley Town". This MIRRORS pipeline.is_non_news_page
        // Rule 10b (mig 276) — keep the two in sync. PIPE-ONLY by design: real
        // feature headlines never use " | " (verified 0 false-positives across
        // 152 AI + 106 primary-source news titles), whereas em-dash/hyphen DO
        // appear in real headlines, so they are deliberately excluded.
        if let pipeRange = title.range(of: " | ") {
            let prefix = String(title[title.startIndex..<pipeRange.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let suffix = String(title[pipeRange.upperBound...])
            let institutionWords =
                #"\b(librar(y|ies)|schools?|district|city|town|county|department|museum|cent(er|re)|academy|college|university|elementary|middle|high school|recreation|parks?|office|court|cemetery|government|fire|police|water|sewer)\b"#
            let prefixIsShort = !prefix.isEmpty && prefix.count <= 40
            let suffixIsInstitution = suffix.range(
                of: institutionWords,
                options: [.regularExpression, .caseInsensitive]
            ) != nil
            if prefixIsShort || suffixIsInstitution {
                return "institution nav page (pipe template)"
            }
        }

        // Title too short to be a real headline.
        if title.count < 12 {
            return "title too short (<12 chars)"
        }

        // Homepage tagline patterns. Common shapes:
        //   "Utah Breaking News, Top Stories & Sports"           (ksl.com)
        //   "KSL NewsRadio 102.7 FM: Utah News, Weather, Traffic" (kslnewsradio)
        //   "Latest news, weather, traffic..."                    (various)
        // The outlet's nav/SEO title, not an article headline.
        let homepageMarkers = [
            "top stories",
            "breaking news",
            "weather, traffic",
            "weather and traffic",
            "news, weather",
            "newsradio",     // "KSL NewsRadio 102.7 FM:" prefix
            "fm:"             // radio-station homepage colon
        ]
        let lowered = title.lowercased()
        let homepageHits = homepageMarkers.filter { lowered.contains($0) }.count
        if homepageHits >= 2 {
            return "homepage tagline (>=2 markers)"
        }
        if homepageHits >= 1 && snippet.count < 100 {
            return "homepage tagline + thin body"
        }

        // No usable summary AND title doesn't carry enough by itself.
        if snippet.isEmpty && title.count < 30 {
            return "empty snippet and thin title"
        }

        return nil
    }
}
