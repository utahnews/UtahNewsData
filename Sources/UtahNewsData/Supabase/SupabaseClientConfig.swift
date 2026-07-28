//
//  SupabaseClientConfig.swift
//  UtahNewsData
//
//  Shared Supabase configuration and client factory.
//  Single source of truth for all apps in the Utah News Platform.
//
//  All apps (V2PipelineTester, NewsCapture, UtahNews, URLCapture) should
//  use this instead of defining their own SupabaseConfig.
//

import Foundation
import Supabase

// MARK: - Configuration

/// Shared Supabase configuration for the Utah News Platform.
/// All pipeline and editorial data lives in the `pipeline` schema
/// on a self-hosted Supabase instance (Mac Studio, 10Gb fiber)
/// fronted by Cloudflare Tunnel at api.utah.news for HTTPS termination.
public enum SupabaseConfig: Sendable {
    /// Base URL of the self-hosted Supabase instance.
    ///
    /// Default: HTTPS via Cloudflare Tunnel → ragstudio Kong gateway on :8000.
    /// That is correct for READER-FACING clients (the UtahNews app, TestFlight,
    /// web) and MUST stay the default — no env var is set there.
    ///
    /// `SUPABASE_URL_OVERRIDE` exists for the DAEMON FLEET (V2PipelineTester +
    /// NewsCapture launchd jobs), which set it to ragstudio's tailnet endpoint
    /// `http://100.115.235.25:8000` in their plists. WHY: every Swift consumer
    /// hardcoding api.utah.news put the 26-instance V2 fleet and 5-machine NC
    /// fleet on the SAME single cloudflared tunnel readers use — on 2026-07-27
    /// a desktop reboot's fleet cold-start saturated that tunnel and reader
    /// feed requests were canceled alongside daemon RPCs (same connIndex, same
    /// minute). The tailnet is also ~21x faster (5.5ms vs 118ms measured) for
    /// daemons making thousands of serial round-trips. Both daemon apps carry
    /// ATS exceptions for the tailnet IP; the reader app does not need one
    /// because it never sets the override.
    ///
    /// Reader-visible URLs (images, HLS, share links) must NEVER be built from
    /// this value — tailnet bases are unreachable from reader devices (the
    /// 2026-07-09 340-article imageless incident; DB backstop in mig 489).
    public static let url: URL = {
        if let override = ProcessInfo.processInfo.environment["SUPABASE_URL_OVERRIDE"],
           let overrideURL = URL(string: override), overrideURL.host != nil {
            return overrideURL
        }
        return URL(string: "https://api.utah.news")!
    }()

    /// Anonymous key for Supabase access (service_role bypasses RLS)
    public static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNjQxNzY5MjAwLCJleHAiOjE3OTk1MzU2MDB9.GPTrVW7zhgw81ffqjIKKzpTsBW0vofNyBaSSgrdxnZ8"

    /// PostgreSQL schema for all pipeline tables
    public static let schema = "pipeline"
}

// MARK: - Client Factory

/// Creates a shared `SupabaseClient` configured for the Utah News Platform.
///
/// Usage in consuming apps:
/// ```swift
/// import UtahNewsData
///
/// let client = SupabaseClientFactory.makeClient()
///
/// // All queries should specify the pipeline schema:
/// let items = try await client.from(SupabaseTable.urlQueue.rawValue)
///     .schema(SupabaseConfig.schema)
///     .select()
///     .execute()
/// ```
public enum SupabaseClientFactory: Sendable {

    /// Creates a new `SupabaseClient` with the shared platform configuration.
    ///
    /// Each app should create one client instance and reuse it.
    /// The Supabase SDK handles connection pooling internally.
    public static func makeClient() -> SupabaseClient {
        SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.anonKey
        )
    }
}
