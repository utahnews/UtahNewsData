# UtahNewsData Supabase Consolidation Plan

**Status:** In progress · Started v1.12.0 (2026-04-16) · Target completion v1.15.0

## Context

Per the Utah News Platform Wave 1 audit, **3 consumer apps each ship their own ~160-7,000 LOC `SupabaseService` implementation** with substantial overlap and zero code sharing:

| Consumer | Service size | Public methods | Focus |
|---|---|---|---|
| URLCapture | 160 LOC | 7 | URL submission + user tracking |
| NewsCapture | 3,373 LOC | 68 | Editorial queue, articles, audits, story intelligence |
| V2PipelineTester | 7,021 LOC (7 files) | 112 | URL queue, processed items, sources, entities, institutions, scans |

**Total:** ~180 public methods, ~10,500 LOC of mostly-duplicated schema boilerplate.

URLCapture already demonstrates the right pattern: its actor conforms to `URLQueueOperations` and inherits queue methods from shared default implementations in this package.

## Goal

Over several minor releases, extract shared surface from the three consumer services into UtahNewsData as:

1. **Domain-scoped protocols** with default implementations (not one god-class)
2. **Shared model types** for all `Supabase*` rows / inserts / RPC results
3. **Shared error types** for consistent error handling
4. **Shared utilities** for pagination, JSONB marshalling, query helpers

Consumers conform their local `SupabaseService` to the relevant protocols and delete the now-redundant method bodies. App-specific methods stay in the consumer.

## Design: Domain-Scoped Protocols (NOT One God-Class)

The three consumers have **wildly different use cases** per the responsibility matrix in the root CLAUDE.md. A single monolithic service would:
- Expose 180+ methods, most irrelevant to any given consumer
- Mix editorial workflows with pipeline internals with URL capture
- Be maintenance-hostile as the platform grows

**Instead, one protocol per bounded context:**

```swift
// Already exists (v1.x)
public protocol URLQueueOperations: Sendable {
    var supabaseClient: SupabaseClient { get }
    // addURLToQueue, checkAlreadyQueued, batchAddURLs, urlExistsInQueue, getQueueItemStatus
}

// Planned (v1.13.0)
public protocol ProcessedItemReadOperations: Sendable {
    var supabaseClient: SupabaseClient { get }
    // fetchProcessedItem(id:), fetchProcessedItemByURL, queryProcessedItems(...),
    // searchProcessedItems, getProcessedItemsStatistics
}

// Planned (v1.13.0)
public protocol CitySourceRegistryOperations: Sendable {
    var supabaseClient: SupabaseClient { get }
    // loadAllSources, loadSourcesForCity, addSource, deleteSource,
    // updateSourceQualityScore, citySourceExists
}

// Planned (v1.14.0)
public protocol EditorialQueueOperations: Sendable {
    var supabaseClient: SupabaseClient { get }
    // fetchEditorialQueue, createEditorialQueueItem, update* variants
}

// Planned (v1.14.0)
public protocol ArticleOperations: Sendable {
    var supabaseClient: SupabaseClient { get }
    // saveArticle, fetchArticle, updateArticleStatus/Content/Fields, deleteArticle
}

// Planned (v1.15.0)
public protocol PipelineObservabilityOperations: Sendable {
    var supabaseClient: SupabaseClient { get }
    // logPipelineRunStart/Complete/Failure
}
```

Consumers opt-in by adding conformance:

```swift
// NewsCapture/Services/SupabaseService.swift
actor SupabaseService: URLQueueOperations,
                       ProcessedItemReadOperations,
                       EditorialQueueOperations,
                       ArticleOperations {
    let supabaseClient: SupabaseClient = SupabaseClientFactory.makeClient()
    // Only editorial-unique methods remain here.
}
```

## Roadmap

| Version | Scope | Status |
|---|---|---|
| v1.11.1 | Baseline — URLQueueOperations, 19 model types, 66-table registry | Shipped |
| **v1.12.0** | **Shared error types (`SupabaseError`, `SupabaseUpdateError`). Design doc.** | **In progress** |
| v1.13.0 | `ProcessedItemReadOperations`, `CitySourceRegistryOperations`, shared RPC result types | Planned |
| v1.14.0 | `EditorialQueueOperations`, `ArticleOperations` | Planned |
| v1.15.0 | `PipelineObservabilityOperations`, entity CRUD consolidation | Planned |
| v2.0.0 | **Only if** breaking API changes required. Current plan is fully additive; v2.0.0 may never ship. | Deferred |

## Semver Discipline

- **Additive** (new protocol, new type, new method with default impl) → **minor** bump
- Parameter reorder, default value change, name change → **major** bump (v2.x)
- Removing a type → **major** bump

The current plan is strictly additive. Each minor version ships independently; consumers adopt at their own pace. No forced migrations.

## Non-Goals

- We are **not** attempting to build a one-size-fits-all service.
- We are **not** removing any existing API in v1.x.
- We are **not** requiring all consumers to migrate in lockstep. Each consumer adopts protocols incrementally.
- NewsCapture's "story intelligence" methods (entity clusters, topic clusters, entity trends) stay in NewsCapture — they're editorial-specific compute, not shared schema access.

## Open Questions

- **RPC functions** (`claim_next_url`, `heartbeat_url`, `get_processed_items_for_editorial`, etc.) — should UtahNewsData ship typed Swift wrappers, or keep RPC calls inline in consumers? Leaning: typed wrappers for the ones used by 2+ consumers.
- **JSONB `AnyCodable`** — `SupabaseAnyCodable` lives here; V2 duplicates as `AnyJSON`. Consolidate in v1.13.0.
- **Pagination helpers** — NewsCapture has ad-hoc `range(from:to:)` + offset loops; V2 has its own. Could be a `Paginator<T>` utility.

## Entry Criteria per Protocol

Before adding a new protocol to UtahNewsData, confirm:
1. At least 2 consumer apps use the same method set
2. Signatures are stable (not likely to change in next 2 sprints)
3. Default implementation is thread-safe (no stored state)
4. Returns only `Sendable` types

## Exit Criteria (per consumer)

Consumer app is "consolidation complete" when:
1. Its local `SupabaseService` conforms to all relevant protocols
2. It has zero duplicate method bodies (methods inherited from UtahNewsData)
3. It ships only app-specific extension methods
4. CI passes across the consumer + UtahNewsData

## Reference

- Inventory reports from Wave 1 research: see conversation artifacts
- App responsibility matrix: `/Users/markevans/Developer/UtahNewsPlatform/CLAUDE.md` § App Responsibility Matrix
- Collection authority rules: `CLAUDE.md` § Firestore Collection Authority
