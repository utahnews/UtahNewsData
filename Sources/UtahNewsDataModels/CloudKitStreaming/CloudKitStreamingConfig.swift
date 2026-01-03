//
//  CloudKitStreamingConfig.swift
//  UtahNewsData
//
//  CloudKit configuration constants for HLS video streaming.
//

import Foundation

/// CloudKit configuration for HLS video streaming
public enum CloudKitStreamingConfig {
    /// CloudKit container identifier
    public static let containerID = "iCloud.com.appLaunchers.UtahNews"

    /// CloudKit Web Services API token for HTTPS streaming
    /// This token provides read-only access to the public database.
    /// It is NOT a secret - designed to be embedded in client apps.
    public static let apiToken = "37cd2b192c75197f89a5e65d897075668191c4d3738e0b4ee6cae9dcf38397f7"

    /// Custom URL scheme for CloudKit HLS streaming
    public static let urlScheme = "cloudkit"
}
