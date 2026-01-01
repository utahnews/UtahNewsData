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
