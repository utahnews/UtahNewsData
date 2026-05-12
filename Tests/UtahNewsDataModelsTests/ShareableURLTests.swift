//
//  ShareableURLTests.swift
//  UtahNewsDataModelsTests
//
//  Verifies canonical share-URL builders for Article / Video / Audio.
//

import Foundation
import Testing
@testable import UtahNewsDataModels

@Suite("Shareable URL builders")
struct ShareableURLTests {

    @Test("Article shareableURL uses /article/{id}")
    func testArticleShareableURL() {
        let article = Article(
            id: "abc-123",
            title: "Test",
            url: "https://upstream.example.com/story",
            publishedAt: Date()
        )
        #expect(article.shareableURL.absoluteString == "https://utah.news/article/abc-123")
        #expect(article.shareableURL.scheme == "https")
        #expect(article.shareableURL.host == "utah.news")
    }

    @Test("Video shareableURL uses /v/{id}")
    func testVideoShareableURL() {
        let video = Video(
            id: "vid-42",
            title: "Test",
            url: "https://videos.utah.news/test.m3u8",
            duration: 60,
            resolution: "1080p"
        )
        #expect(video.shareableURL.absoluteString == "https://utah.news/v/vid-42")
    }

    @Test("Audio shareableURL uses /a/{id}")
    func testAudioShareableURL() {
        let audio = Audio(
            id: "aud-7",
            title: "Test",
            url: "https://audio.utah.news/test.mp3",
            duration: 60,
            bitrate: 128
        )
        #expect(audio.shareableURL.absoluteString == "https://utah.news/a/aud-7")
    }

    @Test("Shareable URL percent-encodes ids that need it")
    func testEncoding() {
        // Real IDs are alphanumeric, but verify defensive encoding.
        let article = Article(
            id: "id with space",
            title: "Test",
            url: "https://example.com",
            publishedAt: Date()
        )
        #expect(article.shareableURL.absoluteString == "https://utah.news/article/id%20with%20space")
    }
}
