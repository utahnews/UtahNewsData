//
//  CloudKitStreamingConfig.swift
//  UtahNewsData
//
//  CloudKit configuration constants for HLS video streaming.
//

import Foundation

/// CloudKit configuration for HLS video streaming.
public enum CloudKitStreamingConfig {
    /// CloudKit container identifier (shared between Development and Production).
    public static let containerID = "iCloud.com.appLaunchers.UtahNews"

    /// Custom URL scheme for CloudKit HLS streaming.
    public static let urlScheme = "cloudkit"

    // MARK: - API Tokens (environment-scoped)

    /// Development-environment API token. Authenticates HTTP requests to
    /// `/database/1/<container>/development/public/…` endpoints.
    ///
    /// Apple's CloudKit API tokens are designed to be embedded in client
    /// apps — they're not secrets in the traditional sense. A leaked token
    /// grants only the permissions declared when the token was created,
    /// not access to private data.
    public static let devApiToken = "37cd2b192c75197f89a5e65d897075668191c4d3738e0b4ee6cae9dcf38397f7"

    /// Production-environment API token.
    ///
    /// CloudKit Web Services tokens are environment-scoped: the development
    /// token does NOT authenticate production requests and vice versa.
    /// Consumers selecting via `apiToken` below get the right one per build.
    public static let prodApiToken = "a2f709f4d4b6ce36a8590bee7babe167333ba61837581f10794c2f62dca8743b"

    /// Auto-selected token for single-environment consumers (matches the
    /// `environment` selection in `CloudKitWebService.init`). HLS playback in
    /// UtahNews uses this — Debug builds hit Development, Release builds hit
    /// Production.
    ///
    /// Dual-environment writers (e.g. UtahNewsUploader's mirror-to-both-envs
    /// feature) should read `devApiToken` and `prodApiToken` explicitly
    /// instead of going through `apiToken`.
    public static let apiToken: String = {
        #if DEBUG
        return devApiToken
        #else
        return prodApiToken
        #endif
    }()
}
