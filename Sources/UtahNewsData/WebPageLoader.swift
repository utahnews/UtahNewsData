import SwiftUI
import Foundation
import WebKit
import SwiftSoup

@MainActor
public final class WebPageLoader: @unchecked Sendable {
    
    public static let shared = WebPageLoader()
    
    public func loadPage(url: URL) async throws -> String {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        
        webView.load(URLRequest(url: url))
        
        while webView.isLoading {
            await Task.yield()
        }
        
        let html = try await webView.evaluateJavaScript("document.documentElement.outerHTML") as? String
        if let html = html {
            return try cleanHTMLContent(html)
        } else {
            throw ParsingError.invalidHTML
        }
    }
    
    public func cleanHTMLContent(_ html: String) throws -> String {
        // Parse the HTML document
        let document: Document = try SwiftSoup.parse(html)
        
        // Remove unwanted tags that add noise
        try document.select("script, style, nav, header, footer, aside, noscript, iframe, .ad, .advertisement, .social-share").remove()
        
        // Remove tracking and analytics elements
        try document.select("[class*='analytics'], [class*='tracking'], [class*='newsletter'], [class*='popup']").remove()
        
        // Remove unwanted attributes and elements
        for element in try document.getAllElements() {
            try element.removeAttr("onclick")
            try element.removeAttr("onload")
            try element.removeAttr("style")
            try element.removeAttr("class")
            
            // Remove data- attributes
            if let attributes = try element.getAttributes() {
                for attr in attributes {
                    if attr.getKey().starts(with: "data-") {
                        try element.removeAttr(attr.getKey())
                    }
                }
            }
        }
        
        // If the page uses an <article> tag for main content, extract it
        if let articleElement = try document.select("article").first() {
            return try articleElement.html()
        }
        
        // If no article tag, try to find the main content area
        let mainSelectors = [
            ".Article__Content",
            ".Article-content",
            ".article-body",
            ".entry-content",
            ".story-content",
            "[itemprop='articleBody']",
            "main",
            "#main-content"
        ]
        
        for selector in mainSelectors {
            if let mainContent = try document.select(selector).first() {
                return try mainContent.html()
            }
        }
        
        // If no specific content area found, return the cleaned body content
        return try document.body()?.html() ?? ""
    }
} 