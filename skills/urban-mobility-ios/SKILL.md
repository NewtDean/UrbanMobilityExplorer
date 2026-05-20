---
name: urban-mobility-ios
description: >-
  iOS 18 / Swift 6 / SwiftUI engineering standards for Urban Mobility Explorer.
  Enforces map-first architecture, protocol-driven data, actor-isolated cache,
  @MainActor ViewModels, Sendable domain models, and project file layout.
  Use when writing or reviewing Swift/SwiftUI code, ViewModels, MapKit sheets,
  SwiftData, networking, previews, or tests in this repository.
---

# Urban Mobility Explorer — iOS / Swift / SwiftUI Skill

> **Purpose**: This skill was used to steer AI-assisted implementation toward production-grade iOS patterns aligned with Apple’s Swift 6 concurrency model and this app’s map-first architecture. Follow it for all new code in this repo.

## When to apply

- Adding or changing Swift / SwiftUI files under `UrbanMobilityExplorer/`
- Touching `Networking/` hand-written code (not `OpenApiClientGenerated/`)
- Refactoring ViewModels, map sheets, cache, or SwiftData
- Writing unit tests or `#Preview` blocks

**Read first**: [docs/ADR/001-architecture.md](docs/ADR/001-architecture.md)

---

## 1. Platform & language baseline

| Item | Requirement |
|------|-------------|
| Deployment | **iOS 17+** (SwiftData); app target may be iOS 18 |
| Language | **Swift 6.0** with strict concurrency |
| UI | **SwiftUI** only for screens; UIKit only via `UIViewRepresentable` when unavoidable |
| Maps | **MapKit** `Map` (iOS 17+), not legacy `MKMapView` wrappers unless required |
| Persistence | **SwiftData** for favorites + disk cache models |
| Async | **async/await** + `Task`; cancel long work in `deinit` / `onDisappear` / new user actions |

### Swift 6 concurrency (non-negotiable)

```swift
// ✅ Domain & DTO mapping — Sendable value types
struct MobilityStation: Sendable, Codable { ... }

// ✅ Shared mutable state — actor
actor StationCacheActor { ... }

// ✅ UI & Observable state — MainActor
@MainActor
final class StationListViewModel: ObservableObject { ... }

// ✅ Cross-isolation from previews
nonisolated static func previewForCanvas() -> AppDependencies {
    MainActor.assumeIsolated { preview() }
}
```

- Mark cross-actor boundaries explicitly; avoid `@unchecked Sendable` unless documented.
- Prefer `nonisolated` on pure helpers in `enum GeoUtilities: Sendable`.
- Cancel prior `Task` before starting conflicting loads (`loadTask?.cancel()`).

---

## 2. Architecture layers (do not violate)

```
Features/ (SwiftUI)  →  ViewModels (@MainActor)  →  Domain/  →  Data/ + Services/
                                                              ↘ UrbanMobilityNetworking (SPM)
```

| Rule | Detail |
|------|--------|
| **Dependency direction** | Views → ViewModels → protocols (`StationDataProviding`) → implementations |
| **No DTO leakage** | OpenAPI types stay in `Data/API/`; map to `MobilityStation` in `OpenAPIDomainMapping.swift` |
| **Composition root** | New services wire in `AppDependencies`, inject via `@EnvironmentObject` |
| **Decorators** | Network resilience via `CachedStationDataProvider`, not god repositories |
| **Generated code** | **Never edit** `Networking/OpenApiClientGenerated/**`; regenerate with `Networking/Scripts/generate-openapi-clients.sh` |

---

## 3. SwiftUI & map-first UI rules

### 3.1 Map-first navigation

- **No TabView** for primary flows; root is `MapDiscoveryView`.
- Use **stacked sheets**: primary discovery sheet + `MapStackedSheet` nested sheet.
- **Do not `dismiss()` browse sheets on station select** — it clears `stackedSheet` and drops map pins (see ADR §5.2).

### 3.2 Sheet & layout metrics

- All sheet heights, FAB spacing, corner radius → `MapBottomPanelMetrics`.
- All camera framing / zoom → `MapManager` + `GeoUtilities.region(framing:…)`.
- **Never** scatter magic `CGFloat` for sheet/map coupling inside random Views.

### 3.3 City vs GPS semantics

| User mode | Distance origin | Map FAB | Weather anchor |
|-----------|-----------------|---------|----------------|
| Selected city | Network hub | `recenter(on:)` | Hub |
| Current location | Device GPS | `focusDeviceLocation(on:)` | GPS |

Implement via `walkingRouteOrigin` / `usesCurrentLocationSelection` — do not duplicate logic in Views.

### 3.4 SwiftUI style

```swift
// ✅ Small composable views, extract at ~80+ lines or second reuse
private var mapLayer: some View { ... }

// ✅ Explicit animation only where needed
.animation(.easeInOut(duration: 0.25), value: fabBottomPadding)

// ✅ Localization for user strings
String(localized: "Bike Stations")

// ❌ Avoid massive body builders (200+ lines) — split MARK sections
```

- Use `@StateObject` for owned ViewModels; `@ObservedObject` when injected.
- Prefer `.task { }` for async on appear; guard with flags to avoid duplicate bootstrap.
- `interactiveDismissDisabled(true)` only for primary discovery sheet, not every sheet.

---

## 4. ViewModel guidelines

```swift
@MainActor
final class FeatureViewModel: ObservableObject {
    @Published private(set) var items: [Item] = []
    @Published private(set) var loadState: LoadState = .idle

    private var loadTask: Task<Void, Never>?

    func refresh() {
        loadTask?.cancel()
        loadTask = Task {
            // fetch → await MainActor updates via @Published
        }
    }
}
```

- Expose **`private(set)`** on published state clients should not mutate.
- Use **enum `LoadState`**: `idle | loading | loaded | empty | error(String)`.
- Debounce search with Combine (`debounce 250ms`) on `RunLoop.main`.
- Surface `DataSourceKind` + `isStale` when data may be cached/bundled.
- **Weather refresh** only on `bootstrap`, `selectCity`, `selectCurrentLocation` — not on map camera churn.

---

## 5. Data & caching

### Fallback chain (required behavior)

```
Live API → StationCacheActor (fresh) → stale cache → Bundled JSON
```

- TTL: `APIConfiguration.cacheTTL` (5 min), stale window `staleTTL` (1 h).
- Write-through to SwiftData via `StationCacheModelActor` after successful fetches.
- Client-side **viewport filter** for `mapStations`; full list stays in `stations`.
- Ignore bogus `onMapCameraChange` regions when center drifts beyond `filterRadiusMeters`.

### Protocols over concrete types

```swift
protocol StationDataProviding: Sendable {
    func fetchStations(networkId: String, forceRefresh: Bool, query: StationSearchQuery?) async throws -> StationFetchResult
}
```

Tests inject `MockStationProvider` or `LocalBundledStationProvider` — never mock Alamofire directly in ViewModel tests.

---

## 6. Domain & business logic

- **Pure functions** for scoring/formatting: `StationRecommendationEngine`, `WeatherSnapshot+Presentation`.
- No `import SwiftUI` in `Domain/` except presentation extensions that return `Color`/`Image` (keep thin).
- Station identity: `favoriteKey` = `networkId` + `stationId`.
- Precompute `recommendationScore` at fetch time, not on every `body` refresh.

---

## 7. Networking package

- Bootstrap once in `UrbanMobilityExplorerApp.init`: `MobilityAPIBootstrap.configure(...)`.
- Hand-written HTTP helpers live in `Networking/Core/`.
- Regenerate clients after YAML changes; fix mapping in app target tests (`CityBikesDTOTests`).

---

## 8. SwiftData

- Models: `FavoriteStation`, `FavoriteNetwork`, `CachedStationRecord`, `CachedNetworkRecord`.
- Repositories: `SwiftDataFavoritesRepository` — inject after `modelContainer` in `AppDependencies.configure`.
- Favorites store **snapshots** (denormalized station fields) for offline read.

---

## 9. File header (required)

Every new hand-written Swift file:

```swift
//
//  FileName.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on YYYY/MM/DD.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//
```

**Exception**: OpenAPI generated files — do not change generator headers.

---

## 10. Testing & previews

### Unit tests

- Add tests in `UrbanMobilityExplorerTests/` for non-trivial logic (engine, cache decorator, geo, mapping).
- Use in-memory SwiftData or mocks; tests must be **deterministic** (no live network).
- Naming: `test<Behavior>_<Condition>_<Expected>()`.

### Previews

```swift
#Preview("Map – Loaded") {
    MapDiscoveryView(
        dependencies: AppDependencies.previewForCanvas(),
        viewModel: .previewForCanvas()
    )
    .previewDependencies()
}
```

- Provide preview factories on ViewModels (`previewForCanvas(stations:loadState:…)`).
- Never hit production APIs from `#Preview`.

---

## 11. Errors (no client logging)

- **Do not** add `print`, `os.Logger`, `AppLogger`, `NSLog`, or response-body debug dumps — HSBC policy requires strict control of logs.
- Surface failures via `LoadState.error`, `LocalizedError`, or in-memory state only.
- Network/persistence failures fail silently where a fallback path exists (cache, bundled JSON).

---

## 12. Code change checklist (AI / human)

Before finishing a task:

```
- [ ] Correct layer (Feature vs Domain vs Data)
- [ ] Sendable / @MainActor / actor boundaries respected
- [ ] No OpenAPI types in ViewModel public API
- [ ] Sheet/map metrics not duplicated outside MapBottomPanelMetrics / MapManager
- [ ] City vs Current location semantics preserved
- [ ] Async tasks cancelled on navigation / refresh
- [ ] File header applied (if new file)
- [ ] Unit test or preview updated when behavior changes
- [ ] xcodebuild build (+ test if logic change)
```

Build command:

```bash
xcodebuild -scheme UrbanMobilityExplorer \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

---

## 13. Anti-patterns (reject in review)

| Anti-pattern | Why |
|--------------|-----|
| Massive `ObservableObject` with URLSession | Untestable; use protocols + decorator |
| Map camera math inside SwiftUI `body` | Use `MapManager` |
| `dismiss()` on station pick from browse sheet | Breaks pin selection state |
| Refresh weather on every map pan | Wastes API; breaks loading UX |
| Editing generated OpenAPI Swift | Lost on regen |
| `NSCache` for station lists | Use `StationCacheActor` |
| Global singletons beyond `AppDependencies` | Hurts previews & tests |
| Force-unwrap production API responses | Map to `LoadState.error` |

---

## 14. Additional reference

- Layer diagrams & flows: [reference.md](reference.md)
- Product architecture ADR: [docs/ADR/001-architecture.md](docs/ADR/001-architecture.md)
- Human README: [README.md](README.md)
