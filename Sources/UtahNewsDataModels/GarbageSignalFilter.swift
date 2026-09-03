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

    /// True when the URL is a CMS TAG/CATEGORY INDEX page — the path ENDS at
    /// the tag/category slug (migration 1128's twin, 2026-08-31). The mig 957
    /// law: a LISTING ends the path; a /category/<base>/<story-slug> permalink
    /// continues past it and never matches. Covers /tag/, /tags/, /category/,
    /// /categories/. Pagination tails (/tag/x/page/2) are the mig 957 author/
    /// pagination shapes; query-string tails (/tag/x/?utm=…) are a documented
    /// miss on both sides. gemma composes "archive digest" mashups from these
    /// pages (Lehi audit 2026-08-31: 103 of Lehi's August drafts alone).
    /// Widen this and migration 1128's clauses TOGETHER or they stop being twins.
    public static func isListingIndexURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        let path = url.path.lowercased()
        return path.range(of: #"/tags?/[^/]+/?$"#, options: .regularExpression) != nil
            || path.range(of: #"/categor(y|ies)/[^/]+/?$"#, options: .regularExpression) != nil
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

        // TAG/CATEGORY LISTING INDEX page (2026-08-31, migration 1128). Placed
        // beside the docket/bio rules for the same reason: gemma gives the
        // digest a perfectly news-shaped title ("Lehi Free Press Archives
        // Detail Local Arrest and City Plans") that falls through every
        // headline-shape rule below.
        if isListingIndexURL(sourceURL) {
            return "tag/category listing index page (listing source, not a story)"
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
