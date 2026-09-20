# CleanEater

A native macOS app: search for restaurants and see only the ones with **zero
King County health-code violations in the last N years** (configurable,
default 2). Search uses `MKLocalSearch`; compliance data comes from King
County's public Socrata API for its Food Establishment Inspection Data
(`r878-4sxa`).

## How it works

1. You type what you want ("Thai food") and where ("Capitol Hill, Seattle").
2. `GeocodingService` (CLGeocoder) turns "where" into a coordinate.
3. `MapKitPlaceSearchProvider` runs an `MKLocalSearch` around that coordinate.
4. For each place found, `KingCountyInspectionService` queries the Socrata API
   for inspection rows whose business name matches.
5. `RestaurantMatcher` narrows those rows down to the ones that are actually
   *this* physical location — matching by name similarity isn't enough on its
   own (chains, generic names), so it also requires the street number to
   agree.
6. `InspectionAggregator` collapses the dataset's one-row-per-violation shape
   into a single summary: inspection count, violation count, most recent
   inspection date, whether it was ever closed.
7. A restaurant is "clean" if it has at least one inspection in the window,
   zero cited violations, was never closed, and its most recent inspection
   carried King County's "Excellent" grade.

There's also a **Map** view (toggle in the toolbar) as an alternative to
typing a cuisine/name: it shows every result as a pin with a clean/not-clean
badge underneath, and a "Search This Area" button re-runs the search over
whatever region you've panned/zoomed to, via
`MapKitPlaceSearchProvider.browseRestaurants` (`MKLocalPointsOfInterestRequest`
restricted to food categories, no text query) →
`ComplianceSearchService.browseCleanRestaurants`, sharing the same King
County matching/aggregation as the text search.

## Project layout

This is an Xcode project, not a Swift package — one app, two targets:

```
Sources/
  CleanEaterKit/     King County API client, name/address matching,
                     inspection aggregation, the search pipeline.
  CleanEaterMapKit/  MapKit/CoreLocation adapters (place search, geocoding).
  CleanEaterApp/     SwiftUI: sidebar of recent searches, a Table of
                     results, an inspector pane for restaurant detail,
                     a Settings scene (⌘,) for lookback window / radius.
Tests/
  CleanEaterTests/   Matcher, aggregator, and Socrata query/decoding tests —
                     runs as the CleanEaterTests target, hosted by the app.
```

The `Sources/*` split into folders for readability, but they all compile into
the one `CleanEater` target/module — there's no cross-module boundary between
them, so no `import` between those folders is needed.

## Running it

**Open `CleanEater.xcodeproj` in Xcode and hit ⌘R.** A shared scheme is
already checked in, so there's no setup step beyond opening it. ⌘U runs the
tests (`CleanEaterTests`, a proper unit-test target hosted by the app).

Before your first build, select the CleanEater project in the navigator →
the CleanEater target → **Signing & Capabilities**, and change the bundle
identifier (currently the placeholder `com.cleaneater.CleanEater`) to your
own, and pick your team for code signing.

The `.xcodeproj` was generated with a script (using the same `node-xcode`
library React Native/Cordova use to edit Xcode projects programmatically)
rather than hand-typed, specifically to avoid the risk of a manually-edited
`project.pbxproj` silently corrupting — but it was written and validated
(round-trip parsed) in an environment without Xcode itself, so treat the
first `⌘B` as the real verification and file an issue against yourself if
anything looks off in Xcode's own project settings UI.

## Known limitations / next steps

- **MapKit names don't always match King County's on-file name.** King
  County prefixes chain locations with an internal store code (e.g. `"#807
  TUTTA BELLA"`), which MapKit never surfaces, and more generally a
  business's DBA name can drift from what's on file. `RestaurantMatcher`
  strips a leading numeric store code before scoring name similarity, but
  bigger name divergences (rebrands, a MapKit listing using a different DBA
  entirely) can still cause a miss, since the initial Socrata query
  (`KingCountyInspectionService.buildURL`) is a name substring search — if
  it returns zero rows, `RestaurantMatcher` never gets a chance to run. A
  more robust fix would query by address/zip instead of (or in addition to)
  name, since King County's own `business_id` is stable per location
  regardless of name text.
- **No location-permission entitlement yet.** The app currently only
  resolves "where" via geocoding a typed string (no permission needed). A
  "use my current location" button would need `CLLocationManager`, which in
  turn needs `NSLocationWhenInUseUsageDescription` — add that as an
  `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription` build setting (or a real
  Info.plist) on the target once you build that feature.
- **The per-restaurant King County link.** `KingCountyLink` (in
  `CleanEaterKit`) builds a deep link into King County's public ArcGIS
  Experience Builder inspection map, filtered and zoomed to one business by
  its `business_id`. This was reverse-engineered from a real share link
  copied off King County's site, so the URL form itself is confirmed — but
  since it's a client-side JS app (everything after `#` is a URL fragment,
  never sent to a server), click one of the "View" links and confirm it
  still filters correctly if King County ever changes that app's ID or
  internal data-source wiring.
- **No App Sandbox / entitlements file.** Fine for local development and
  running unsigned/self-signed. If you turn on App Sandbox for Mac App Store
  distribution or notarization, you'll need to add an entitlements file
  granting `com.apple.security.network.client` (outgoing network access) —
  without it, the King County and geocoding requests will silently fail
  under a sandboxed build.
- **Rate limiting.** Socrata's public (non-app-token) tier throttles
  aggressively. `ComplianceSearchService` queries King County once per place
  sequentially rather than in parallel to stay under that limit, but a
  future version should request a free Socrata app token and pass it as the
  `X-App-Token` header for higher limits.
- **Matching is a heuristic**, not a guarantee: it requires the street number
  to match and normalized name tokens to overlap by at least 60% (Dice
  coefficient). It can miss a real match if King County's on-file address
  differs from the one Apple Maps returns (e.g. a suite number moved), or
  produce a false negative for a business that changed its name without a
  new inspection yet. There's no false-*positive* case handled by name
  alone — the street-number check exists specifically to prevent chains from
  cross-matching each other.
- **Map/browse mode is bounded by Apple's POI index and per-request result
  caps.** `browseRestaurants` shows what `MKLocalPointsOfInterestRequest`
  returns for the visible region, which won't include every business King
  County has ever inspected (only what Apple Maps indexes), and a single
  request is capped at some number of results — a dense downtown area may
  need the region tiled into sub-requests and merged, which isn't
  implemented yet. `RestaurantMapView.approximateRadiusMiles` is also a
  rough estimate from the visible region's lat/lon span, not an exact fit.
