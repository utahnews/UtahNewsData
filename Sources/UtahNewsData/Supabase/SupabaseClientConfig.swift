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
/// on a self-hosted Supabase instance (Mac Studio, 10Gb fiber).
public enum SupabaseConfig: Sendable {
    /// Base URL of the self-hosted Supabase instance
    public static let url = URL(string: "http://204.228.156.15:8000")!

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
