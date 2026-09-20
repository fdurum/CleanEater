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
   zero cited violations, and was never closed.

## Project layout

```
Sources/
  CleanEaterKit/       Pure Swift + Foundation. No Apple-only frameworks.
                        King County API client, matching, aggregation,
                        the search pipeline. Unit-tested.
  CleanEaterMapKit/     MapKit/CoreLocation adapters (place search, geocoding).
  CleanEaterApp/        SwiftUI app: sidebar of recent searches, a Table of
                        results, an inspector pane for restaurant detail,
                        a Settings scene (⌘,) for lookback window / radius.
Tests/
  CleanEaterKitTests/   Matcher, aggregator, and Socrata query/decoding tests.
```

`CleanEaterKit` has no Apple-only dependencies on purpose, so its logic is
testable in CI on any platform with Swift installed. `CleanEaterMapKit` and
`CleanEaterApp` are gated behind `#if canImport(Darwin)` in `Package.swift`
and only build on macOS.

## Running it

This is a Swift package with an **executable** app target — on macOS you can
run it directly, no `.xcodeproj` required:

```
swift run CleanEaterApp
```

Or open `Package.swift` in Xcode (File ▸ Open) and run the `CleanEaterApp`
scheme like any other app target.

Run the unit tests with:

```
swift test
```

## Known limitations / next steps

- **Field names unverified against the live API.** This was written in an
  environment with no network access to `data.kingcounty.gov`, so the
  Socrata column names in `FoodEstablishmentInspection.CodingKeys` (`name`,
  `program_identifier`, `inspection_date`, etc.) are best-effort, not
  confirmed. Before relying on this, fetch
  `https://data.kingcounty.gov/resource/r878-4sxa.json?$limit=5` yourself and
  diff the keys against `CodingKeys` — fix up any mismatches there. Also
  double check whether King County publishes a newer dataset id than
  `r878-4sxa` by the time you read this.
- **No location-permission entitlement yet.** The app currently only
  resolves "where" via geocoding a typed string (no permission needed). A
  "use my current location" button would need `CLLocationManager`, which in
  turn needs `NSLocationWhenInUseUsageDescription` in an actual signed `.app`
  bundle — that requires wrapping this package in a minimal Xcode project
  (Product ▸ Archive also needs this for distribution/notarization).
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
