# Urban Mobility iOS — Extended Reference

Companion to [SKILL.md](SKILL.md). Read when implementing map sheets, cache, or new features.

---

## Module map (where code goes)

| You are building… | Location |
|-------------------|----------|
| Screen / sheet / component | `UrbanMobilityExplorer/Features/` or `Core/UI/Components/` |
| ViewModel | `Features/<Feature>/` or `Features/Stations/` |
| Model / protocol / pure logic | `Domain/Models/`, `Domain/Protocols/`, `Domain/Services/` |
| API client, mapping, cache, SwiftData | `Data/` |
| Location, prefs, search history | `Services/` |
| Theme, constants, geo | `Core/Design/`, `Core/Geo/` |
| OpenAPI YAML / codegen | `Networking/Scripts/`, `Networking/OpenApiClientGenerated/` |

---

## MapStackedSheet state machine

```
showDiscoveryPanel (always on, fixed height)
    │
    ├─► .browseList          → StationBrowseSheet (detents: medium → large)
    ├─► .favoritesList       → FavoritesBrowseSheet
    ├─► .cityPicker          → CityPickerSheet
    └─► .secondary(.stationDetail) + detailStation binding
```

**Invariant**: `selectedStation` / `detailStation` / `mapHighlightStation` updated together in `openStationFromMap` / `prepareMapForStationSelection`.

---

## MapManager API cheat sheet

| Method | Use when |
|--------|----------|
| `recenter(on:)` | City hub, FAB for selected city |
| `focusDeviceLocation(on:)` | Current location FAB |
| `focus(on:)` / `focusLikeStationDetail(on:)` | User tapped a station pin |
| `focusRegion(for:additionalScreenOffsetY:)` | Need region without publishing request |

Offsets: `detailFocusScreenOffset` (+88), `deviceLocationFocusScreenOffset` (-88).

---

## StationListViewModel — hot paths

| Method | Triggers |
|--------|----------|
| `bootstrap()` | Once per app launch from `MapDiscoveryView.task` |
| `selectCity(_:)` | City picker |
| `selectCurrentLocation()` | Current location row |
| `refreshCityWeather()` | Only from above three |
| `updateVisibleMapRegion(_:mapManager:)` | Map pan; guarded against drift |
| `restoreMapStationsForMapFocus()` | Opening browse/favorites sheets |

---

## SwiftUI observation (iOS 17+)

This project uses **`ObservableObject` + `@Published`** consistently. Do not mix `@Observable` macro in one feature without a project-wide migration plan.

If migrating later:

1. Migrate `AppDependencies` first.
2. Then leaf ViewModels.
3. Update preview helpers last.

---

## Accessibility minimum bar

- FAB: `.accessibilityLabel(String(localized: "Recenter map"))`
- Station rows: combine name + availability in accessibility label when adding new cells.
- Weather row: expose temperature + condition, not icon alone.

---

## Performance notes

- Cap map annotations via `APIConfiguration.maxMapStationAnnotations` (80).
- Filter `mapStations` client-side; avoid per-frame network.
- `Task(priority: .utility)` for background catalog refresh after bootstrap.
- Hydrate SwiftData cache once: `cache.hydrateFromPersistentStore`.

---

## Git / AI workflow (for reviewers)

1. User story → check ADR + this skill.
2. AI implements with skill constraints.
3. Author runs `xcodebuild test` before PR.
4. PR description cites ADR section if architectural.

Example PR note:

> Implements city weather row per SKILL §3. Weather refresh scoped to bootstrap/selectCity per SKILL §4.
