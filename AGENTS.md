# AGENTS.md — UtahNewsData (shared Swift package)

Read this before editing. It is the brief for ANY coding agent working in this repo (a fresh worktree contains only
this repo's files — the platform's root `AGENTS.md` and `CLAUDE.md` are not here).

## What this package is
The canonical shared models and editorial predicates for the Utah News platform, consumed by tag (SPM,
`upToNextMajor`) from UtahNews, V2PipelineTester, NewsCapture, UTNewsDashboard and UtahNewsUploader.
Two products: `UtahNewsDataModels` (no dependencies — prefer it) and `UtahNewsData` (parsing; SwiftSoup).
**An untagged commit is invisible to every consumer.** Tagging, pushing and bumping consumers' `Package.resolved`
are the ORCHESTRATOR's job, never a lane's.

## Scope discipline
- Edit only the files your spec names. Never commit, tag or push. No network.
- A contradiction between your spec and the repo goes into your notes file; do not "fix" the repo.
- `swift build` and `swift test` from the repo root are the acceptance gate; report the literal tail of each.

## Banned-but-compiling (the compiler will not stop you)
`ObservableObject` / `@Published` / `@StateObject` / `@ObservedObject` → `@Observable`; `DispatchQueue` → `async/await`;
completion handlers in new code; Core Data; `import Combine`; `print()` outside tests; `UUID` model ids (ids are `String`);
the NaturalLanguage framework.

## Concurrency
Swift 6, strict. Consumers build with default MainActor isolation, and this package's predicates are called from
`nonisolated` enums and from actors: **public predicate API is `public nonisolated static`**, pure, no I/O, no logging.
Value types that cross actors are `nonisolated struct … : Sendable`.

## `GarbageSignalFilter` — the rules that keep getting broken
- `isNonNewsSourceURL` is the **clause-for-clause Swift twin of `pipeline.is_non_news_source_url`** and is pinned by
  `NonNewsSourceURLParityTests` against shared fixtures. Never "improve" it on one side. A new URL shape is a DB
  migration first, then this twin, then a tag.
- `isListingIndexURL` is a DELIBERATE SUPERSET of the DB child on query-string tails; `garbageReason` consults it
  rather than the strict twin. Read its doc comment before touching either.
- Regexes live in the `RegexClause` table and are compiled once. Never construct `NSRegularExpression` per call.
- `indexTitleReason(_:url:)` (1.40.0) reads the source page's own `<title>`: month-year / day / bare-month /
  terminal "by year|month|date". **The broad index vocabulary (`news`, `press releases`, `archives`…) was measured and
  rejected** — CivicPlus titles real stories `News Flash Archive - <headline>` (11 editor publishes lost / 30 d).
  Do not add it without a URL conjunct and a fresh measurement.
- Title rules are PIPE-ONLY where they mirror DB Rule 10b: em-dash and hyphen headlines are real news.

## Tests
Swift Testing (`@Test`, `#expect`). Add to the existing file for the type you touch; do not convert or reorder
existing tests. Every fixture a spec lists is asserted, positives AND negatives — the negatives are the point.
