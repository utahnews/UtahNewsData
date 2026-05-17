//
//  ArticleType.swift
//  UtahNewsDataModels
//
//  Sprint AA — distinguishes our own primary-source-driven articles from
//  link-out cards that point at a news outlet's signal while our
//  investigation is in progress. See SPRINT_AA_SIGNAL_TRIGGERS_DISCOVERY.md.
//

import Foundation

/// How a row in `pipeline.articles` should be rendered.
///
/// State machine:
///   nil / .fullArticle    — full original-reporting article
///   .linkOutCard          — newly arrived signal, awaiting primaries
///   .fullArticle (with upgradedAt set) — card that has been upgraded in
///                                         place after primaries matched
public enum ArticleType: String, Codable, Hashable, Sendable, CaseIterable {
    case fullArticle = "full_article"
    case linkOutCard = "link_out_card"
}
