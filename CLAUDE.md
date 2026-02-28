# CLAUDE.md

This file provides guidance to Claude Code when working with the UtahNewsData Swift Package.

## Project Overview

**UtahNewsData** is the shared data models and utilities package for the Utah News Platform. It provides canonical data models used across all iOS/macOS applications in the platform.

**Status:** Active (Critical shared dependency)

## Platform Requirements

- iOS 26.0+ / macOS 26.0+ / tvOS 26.0+ / watchOS 26.0+
- Swift 6 with strict concurrency enabled
- Xcode 26+

## Build Commands

```bash
# Build the package
swift build

# Run tests
swift test

# Build for release
swift build -c release

# Open in Xcode
open Package.swift
```

## Package Structure

### Library Products

| Product | Description | Dependencies |
|---------|-------------|--------------|
| `UtahNewsDataModels` | Lightweight models only | None |
| `UtahNewsData` | Full package with parsing utilities | SwiftSoup |

**Import Guidance:**
```swift
// In app code, prefer lightweight models (no SwiftSoup dependency)
import UtahNewsDataModels

// For parsing/scraping operations only
import UtahNewsData
```

### Key Models

All models use **String IDs** (not UUID) for Firebase compatibility:

- `Article` - News article content
- `Video` - Video content metadata
- `Audio` - Podcast/audio content
- `Person` - Named individuals
- `Organization` - Named organizations
- `Location` - Geographic locations with coordinates
- `Source` - News source definitions
- `NewsEvent` - Event data
- `MediaItem` - Generic media container

### Executables

- `ImportSources` - Tool for importing news sources

## Dependency Workflow (CRITICAL - READ FIRST)

UtahNewsData is the shared foundation of the entire Utah News Platform. **All consumer apps reference it as a remote SPM dependency from GitHub**, not as a local package.

### After Making Changes to UtahNewsData

Every time you modify UtahNewsData, you MUST follow this workflow:

1. **Build and test locally:** `swift build && swift test`
2. **Commit and push to GitHub:** `git push origin main`
3. **Update each consuming project** to pull the new version:
   - UtahNews, NewsCapture, V2PipelineTester, UTNewsDashboard
   - In each project: `xcodebuild -resolvePackageDependencies` (or Xcode > File > Packages > Update)
   - **Build each project** to verify no compilation errors
   - Commit the updated `Package.resolved` in each project

### Why This Matters

Each project's `Package.resolved` pins UtahNewsData to a specific Git commit. If you add a new property or method to a model here but don't push to GitHub and update each project, they will still compile against the OLD version and get "has no member" errors.

### Consuming Projects

| Project | GitHub Repo | Package.resolved Location |
|---------|-------------|---------------------------|
| UtahNews | utahnews/UtahNews | `UtahNews.xcodeproj/.../swiftpm/Package.resolved` |
| NewsCapture | utahnews/NewsCapture | `NewsCapture.xcodeproj/.../swiftpm/Package.resolved` |
| V2PipelineTester | utahnews/V2PipelineTester | `V2PipelineTester.xcodeproj/.../swiftpm/Package.resolved` |
| UTNewsDashboard | utahnews/UTNewsDashboard | `UTNewsDashboard.xcodeproj/.../swiftpm/Package.resolved` |

### Quick Verification

```bash
# Check which commit a project is using
grep -A 3 "utahnewsdata" <Project>/<Project>.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

# Compare against latest UtahNewsData commit
cd UtahNewsData/ && git log --oneline -1
```

## Model Conventions

### Required for All Models

```swift
struct MyModel: Identifiable, Codable, Sendable {
    let id: String  // String, NOT UUID (Firebase compatibility)
    // ... other properties
}
```

### Key Patterns

| Pattern | Requirement |
|---------|-------------|
| ID Type | `String` (not UUID) |
| Protocols | `Identifiable`, `Codable`, `Sendable` |
| Coordinates | Use `Coordinates` struct for Location |
| Timestamps | Use `Date` type |

## Scripts

Located in `scripts/` directory:

```bash
# Update consolidated model reference
./scripts/consolidate_models.sh

# Regenerate README
swift scripts/generate_readme.swift
```

**Run these after model changes.**

## Required Patterns

| Pattern | Usage |
|---------|-------|
| `Sendable` | All models must be Sendable |
| `Codable` | All models for serialization |
| String IDs | Firebase compatibility |
| Strict concurrency | Package uses Swift 6 strict mode |

## Prohibited Patterns

These patterns are **BANNED** per global CLAUDE.md standards:

| Prohibited | Use Instead |
|------------|-------------|
| `UUID` for IDs | `String` |
| `ObservableObject` | Not applicable (models only) |
| Non-Sendable types | Make all types `Sendable` |
| Mutable shared state | Use value types or actors |

## CloudKitStreaming Library

The `CloudKitStreaming` module provides HLS video streaming from CloudKit without native SDK dependencies. Located in `Sources/UtahNewsDataModels/CloudKitStreaming/`.

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    CloudKitHLSResourceLoader                     │
│  AVAssetResourceLoaderDelegate for cloudkit:// URL scheme       │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌──────────────────┐  ┌────────────────┐ │
│  │ CloudKitWeb     │  │ PlaybackURLCache │  │ DynamicManifest│ │
│  │ Service         │  │                  │  │ Generator      │ │
│  │                 │  │ Caches segment   │  │                │ │
│  │ HTTP API calls  │  │ download URLs    │  │ Rewrites m3u8  │ │
│  │ to CloudKit     │  │ with expiry      │  │ with HTTPS URLs│ │
│  └─────────────────┘  └──────────────────┘  └────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Key Files

| File | Purpose |
|------|---------|
| `CloudKitHLSResourceLoader.swift` | AVAssetResourceLoaderDelegate for `cloudkit://` URLs |
| `CloudKitWebService.swift` | HTTP client for CloudKit Web Services API |
| `PlaybackURLCache.swift` | Caches segment download URLs with expiry tracking |
| `DynamicManifestGenerator.swift` | Rewrites HLS manifests with current HTTPS URLs |
| `CloudKitStreamingConfig.swift` | Container ID, API token, URL scheme constants |
| `CloudKitStreamingError.swift` | Error types for streaming operations |

### CloudKit Web Services Authentication

**CRITICAL:** CloudKit Web Services uses **query parameters** for authentication, NOT HTTP headers.

```swift
// ✅ CORRECT - API token as query parameter
var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
components.queryItems = [URLQueryItem(name: "ckAPIToken", value: apiToken)]
var request = URLRequest(url: components.url!)

// ❌ WRONG - This header does NOT exist in CloudKit Web Services
request.setValue(apiToken, forHTTPHeaderField: "X-Apple-CloudKit-Request-APIToken")
```

**Apple's CloudKit Web Services authentication methods:**
- `ckAPIToken` - Query parameter for API token (public database read access)
- `ckWebAuthToken` - Query parameter for user auth (private database, optional for public)
- Server-to-Server keys use signature headers (different from API token)

### Usage Pattern

```swift
// 1. Create resource loader
let loader = CloudKitHLSResourceLoader()

// 2. Enable HTTPS streaming (configures API token)
await loader.enableHTTPSStreaming()

// 3. Inject master manifest (from Firestore)
loader.injectMasterManifest(content: manifestContent, for: videoSlug)

// 4. Prefetch segment URLs (optional, improves startup)
try await loader.prefetchURLs(for: videoSlug)

// 5. Create AVURLAsset with cloudkit:// URL
let asset = AVURLAsset(url: URL(string: "cloudkit://\(slug)/master.m3u8")!)
asset.resourceLoader.setDelegate(loader, queue: loaderQueue)

// 6. Create player
let player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
```

### Why No Native CKContainer SDK

The native `CKContainer` SDK requires entitlements matching the CloudKit container's bundle ID. Consumer apps (like UtahNews) may not have these entitlements, causing "Invalid bundle ID for container" errors.

**Solution:** Use CloudKit Web Services HTTP API exclusively:
- Works with any app that has the API token
- No entitlements required
- Full public database read access

## Dependencies

| Dependency | Purpose | Product |
|------------|---------|---------|
| SwiftSoup | HTML parsing | `UtahNewsData` only |

## Testing

```bash
# Run all tests
swift test

# Run specific test
swift test --filter ModelTests
```

## Integration Notes

This package is consumed by:
- UtahNews (consumer app)
- V2PipelineTester (pipeline)
- NewsCapture (editorial tool)
- Other platform apps

**Breaking changes affect multiple apps.** Test thoroughly before modifying public interfaces.

---

See global `~/.claude/CLAUDE.md` for complete compliance requirements.
