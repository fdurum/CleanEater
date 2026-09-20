import Foundation

/// End-to-end pipeline: search for places, look each one up in King County's
/// inspection data, and return every candidate together with its compliance summary
/// (the UI decides whether to show only clean ones or explain why each one qualifies).
public final class ComplianceSearchService {
    private let placeSearch: PlaceSearching
    private let inspectionService: KingCountyInspectionServiceProtocol
    private let lookbackYears: Int
    private let now: @Sendable () -> Date

    public init(
        placeSearch: PlaceSearching,
        inspectionService: KingCountyInspectionServiceProtocol,
        lookbackYears: Int = 2,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.placeSearch = placeSearch
        self.inspectionService = inspectionService
        self.lookbackYears = lookbackYears
        self.now = now
    }

    /// - Returns: One result per place found, each carrying its compliance summary.
    ///   Callers that only want "zero violations in the last N years" should filter
    ///   on `result.summary.isClean`.
    public func searchCleanRestaurants(query: String, near center: Coordinate, radiusMeters: Double) async throws -> [CleanRestaurantResult] {
        let cutoff = cutoffDate()
        let places = try await placeSearch.search(query: query, near: center, radiusMeters: radiusMeters)

        var results: [CleanRestaurantResult] = []
        results.reserveCapacity(places.count)

        // Sequential rather than a task group: Socrata's public tier applies fairly
        // aggressive per-client rate limits, and this keeps request volume predictable.
        for place in places {
            let rows = try await inspectionService.fetchInspections(matchingName: place.name, since: cutoff, limit: 1000)
            let matched = RestaurantMatcher.matchingRows(for: place, in: rows)
            let summary = InspectionAggregator.summarize(rows: matched, since: cutoff)
            results.append(CleanRestaurantResult(place: place, summary: summary))
        }
        return results
    }

    private func cutoffDate() -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .year, value: -lookbackYears, to: now()) ?? now()
    }
}
