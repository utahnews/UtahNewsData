//
//  URLCanonicalizer.swift
//  UtahNewsDataModels
//
//  ONE canonical spelling for every URL that enters pipeline.url_queue.
//
//  WHY THIS EXISTS
//  `pipeline.url_queue` carries UNIQUE (url) on the RAW string, so
//  `https://polk.ogdensd.org/o/pkes/` and `https://polk.ogdensd.org/o/pkes`
//  are two rows. Both get claimed, both get rendered by WebKit, both get
//  published — 117 duplicate article pairs in one 7-day window (juabsd.org 31,
//  telemundoutah 19, orem.gov 10, slc.gov 10) differed by nothing but a
//  trailing slash. 77 such pairs entered url_queue in that window, one pair
//  20 seconds apart.
//
//  THE RULES (deliberately small — every one of them is a spelling difference
//  that cannot change which document the server returns):
//    1. lowercase the scheme                    HTTPS:// → https://
//    2. lowercase the authority (host[:port])   //WWW.SLC.GOV → //www.slc.gov
//    3. drop ONE trailing slash from a NON-ROOT path   /o/pkes/ → /o/pkes
//       (a root path keeps its slash: https://x.gov/ stays https://x.gov/)
//    4. keep the query verbatim                 ?id=7 is load-bearing
//    5. keep the FRAGMENT verbatim              #Incidents-33156 is a ROUTE
//    6. keep the SCHEME AS-IS — http stays http
//
//  Every rule is a spelling difference that CANNOT change which document the
//  server returns. That is the whole test for admitting one.
//
//  HOW THIS DIFFERS FROM pipeline.canonicalize_url(text), AND WHY
//  The DB already has `pipeline.canonicalize_url` (IMMUTABLE, backs an index on
//  articles.source_url). It applies the SAME path/authority rules — including
//  locating the end of the path before a '?' or '#' so `/a/#top` becomes
//  `/a#top` — and differs in exactly ONE respect:
//
//    • canonicalize_url FORCES https. We must NOT. `articles.source_url` is a
//      MATCHING key — the scheme there is cosmetic, so collapsing http/https
//      into one bucket is free. `url_queue.url` is a FETCH TARGET and it is also
//      the PROVENANCE record of what a harvester actually found. The http→https
//      decision already has an owner one stage downstream —
//      URLValidationService.validate() rewrites scheme http→https at claim time
//      (URLValidationService.swift:195-207) — and duplicating that decision at
//      the enqueue writer would make two enumerators of the same rule, which is
//      the failure mode docs/COMPONENT_ROLES.md exists to stop. The rules above
//      provably cannot change which document the server returns; an http→https
//      rewrite provably can (it can turn a 200 into a TLS error).
//      MEASURED (7 d to 2026-08-27): forcing https would collapse a further 204
//      URL groups. That is a separate, larger decision — not this lane's.
//
//  WHY THE FRAGMENT IS KEPT (decided 2026-08-27, on measurement)
//  An earlier draft stripped it. It was dropped: a fragment is not sent to the
//  server, but it IS a client-side route, and WebKit renders the route. MEASURED
//  over the 7 d to 2026-08-27: only 48 queued URLs carry a fragment and
//  stripping bought 23 of 1,134 collapsible variants (2%) — while merging 6
//  distinct `https://udottraffic.utah.gov/map#Incidents-<id>` incidents onto the
//  single `/map` listing page, plus `waterdata.usgs.gov/...#parameterCode=…` and
//  `jobs.utah.gov/...#/industry`. The trailing slash is the defect: 1,111 of
//  1,134. Do not re-add fragment stripping without re-measuring those routes.
//
//  The DB twin of THIS function is `pipeline.url_queue_canonical_url(text)`
//  (migration 1058), invoked by the BEFORE INSERT trigger
//  `aaa0_url_queue_canonicalize` — it fires first so every downstream gate
//  (ssrf guard, ical reject, dedup gate, denylists) judges the canonical
//  spelling. The JavaScript twin is `scripts/lib/url-canon.mjs`. Swift-side
//  canonicalization keeps the wasted round-trip out of the network; the trigger
//  is the unbypassable backstop. If you change one, change Swift + JavaScript +
//  DB together and re-run `scripts/verify-url-canonicalizer.sh` and
//  `scripts/verify-url-canon.mjs`.
//

import Foundation

/// Canonical spelling for a queue URL. Pure, `nonisolated`, no I/O — safe from
/// any actor, and identical in the daemon and the app.
public nonisolated enum URLCanonicalizer {

    /// Canonical spelling of an already-parsed URL.
    ///
    /// - Returns: the canonical string, or `url.absoluteString` unchanged when
    ///   the scheme is not http/https (we never mangle an unknown scheme).
    public static func canonical(_ url: URL) -> String {
        canonical(url.absoluteString)
    }

    /// Canonical spelling of a URL string.
    ///
    /// Operates on the string directly rather than via `URLComponents` so the
    /// output is byte-for-byte what `pipeline.url_queue_canonical_url()`
    /// produces: percent-encoding, case and empty components are all left
    /// exactly as the caller spelled them apart from the six rules above.
    ///
    /// - Returns: the canonical string, or `rawValue` unchanged when the value
    ///   is empty or its scheme is not http/https.
    public static func canonical(_ rawValue: String) -> String {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return rawValue }

        // Scheme — must be http/https, matched at the FIRST "://" exactly like
        // the DB twin's `v_url ~* '^https?://'` + `position('://' in v_url)`.
        guard let separator = trimmed.range(of: "://") else { return rawValue }
        let scheme = trimmed[trimmed.startIndex..<separator.lowerBound].lowercased()
        guard scheme == "http" || scheme == "https" else { return rawValue }

        let rest = trimmed[separator.upperBound...]

        // Rule 2 — the authority runs to the first '/', '?' or '#'.
        let authorityEnd = rest.firstIndex(where: { $0 == "/" || $0 == "?" || $0 == "#" }) ?? rest.endIndex
        let authority = rest[rest.startIndex..<authorityEnd].lowercased()

        // Rules 3/4/5 — the PATH ends at the first '?' or '#'; everything from
        // there (query AND fragment) is carried through verbatim. Drop ONE
        // trailing slash from a path longer than "/" — a bare-host "/" is
        // already canonical. This is pipeline.canonicalize_url's own path rule.
        var remainder = String(rest[authorityEnd...])
        let pathEnd = remainder.firstIndex(where: { $0 == "?" || $0 == "#" }) ?? remainder.endIndex
        if remainder.distance(from: remainder.startIndex, to: pathEnd) > 1 {
            let lastPathCharacter = remainder.index(before: pathEnd)
            if remainder[lastPathCharacter] == "/" {
                remainder.remove(at: lastPathCharacter)
            }
        }

        return scheme + "://" + authority + remainder
    }
}
