import Foundation
import Testing
@testable import UtahNewsDataModels

struct URLCanonicalizerTests {

    @Test("HTTP schemes are lowercased and other schemes are unchanged")
    func canonicalizesOnlyHTTPSchemes() {
        #expect(URLCanonicalizer.canonical("HTTPS://Example.org/story") == "https://example.org/story")
        #expect(URLCanonicalizer.canonical("HTTP://Example.org/story") == "http://example.org/story")
        #expect(URLCanonicalizer.canonical("ftp://Example.org/story/") == "ftp://Example.org/story/")
        #expect(URLCanonicalizer.canonical("Example.org/story/") == "Example.org/story/")
    }

    @Test("Authority is lowercased without changing path case")
    func lowercasesAuthorityOnly() {
        #expect(URLCanonicalizer.canonical("https://WWW.Example.ORG:8443/News/Story")
            == "https://www.example.org:8443/News/Story")
    }

    @Test("Exactly one trailing slash is stripped from a non-root path")
    func stripsOneNonRootTrailingSlash() {
        #expect(URLCanonicalizer.canonical("https://example.org/news/") == "https://example.org/news")
        #expect(URLCanonicalizer.canonical("https://example.org/news//") == "https://example.org/news/")
    }

    @Test("Root slash is retained")
    func retainsRootSlash() {
        #expect(URLCanonicalizer.canonical("https://Example.org/") == "https://example.org/")
    }

    @Test("Query and fragment are retained verbatim after path canonicalization")
    func retainsQueryAndFragment() {
        #expect(URLCanonicalizer.canonical("https://Example.org/Path/?Q=One%20Two#Route-ABC")
            == "https://example.org/Path?Q=One%20Two#Route-ABC")
        #expect(URLCanonicalizer.canonical("https://Example.org?Q=A/B#Route")
            == "https://example.org?Q=A/B#Route")
    }

    @Test("Empty and whitespace-only inputs are unchanged")
    func retainsEmptyInputs() {
        #expect(URLCanonicalizer.canonical("") == "")
        #expect(URLCanonicalizer.canonical(" \t\n ") == " \t\n ")
    }

    @Test("Redirect URL shapes follow the shared path rule")
    func canonicalizesRedirectShapes() {
        #expect(URLCanonicalizer.canonical("https://Example.org/Path/") == "https://example.org/Path")
        #expect(URLCanonicalizer.canonical("https://example.org/path/?q=1") == "https://example.org/path?q=1")
        #expect(URLCanonicalizer.canonical("https://example.org/path/#frag") == "https://example.org/path#frag")
    }

    @Test("URL overload uses the same canonical spelling")
    func canonicalizesParsedURL() throws {
        let url = try #require(URL(string: "https://Example.org/Path/?q=1"))
        #expect(URLCanonicalizer.canonical(url) == "https://example.org/Path?q=1")
    }
}
