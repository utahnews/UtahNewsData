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
