import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var cuisineQuery: String = ""
    @Published var locationText: String = ""
    @Published private(set) var results: [CleanRestaurantResult] = []
    @Published private(set) var isSearching = false
    @Published var errorMessage: String?
    @Published var selection: CleanRestaurantResult.ID?

    private let geocoder = GeocodingService()
    private let placeSearch = MapKitPlaceSearchProvider()

    var selectedResult: CleanRestaurantResult? {
        results.first { $0.id == selection }
    }

    /// - Parameters mirror the persisted settings in `SettingsKey`; the view reads
    ///   `@AppStorage` and passes values in, keeping this model free of SwiftUI.
    func search(lookbackYears: Int, radiusMiles: Double) async {
        guard !cuisineQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Enter what you're looking for, e.g. \"Thai food.\""
            return
        }
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }

        do {
            let center = try await resolveCenter()
            let service = makeComplianceSearchService(lookbackYears: lookbackYears)
            let radiusMeters = radiusMiles * 1609.34
            results = try await service.searchCleanRestaurants(query: cuisineQuery, near: center, radiusMeters: radiusMeters)
                .sorted(by: Self.resultOrdering)
            selection = nil
        } catch {
            errorMessage = Self.friendlyMessage(for: error)
            results = []
        }
    }

    /// Every food establishment in `center`/`radiusMiles`, independent of any typed
    /// query — for "browse this map region" rather than searching for a cuisine.
    func browse(center: Coordinate, radiusMiles: Double, lookbackYears: Int) async {
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }

        do {
            let service = makeComplianceSearchService(lookbackYears: lookbackYears)
            let radiusMeters = radiusMiles * 1609.34
            results = try await service.browseCleanRestaurants(near: center, radiusMeters: radiusMeters)
                .sorted(by: Self.resultOrdering)
            selection = nil
        } catch {
            errorMessage = Self.friendlyMessage(for: error)
            results = []
        }
    }

    private func makeComplianceSearchService(lookbackYears: Int) -> ComplianceSearchService {
        ComplianceSearchService(
            placeSearch: placeSearch,
            inspectionService: KingCountyInspectionService(),
            lookbackYears: lookbackYears
        )
    }

    /// Clean restaurants first, then alphabetical within each group.
    private static func resultOrdering(_ lhs: CleanRestaurantResult, _ rhs: CleanRestaurantResult) -> Bool {
        if lhs.summary.isClean != rhs.summary.isClean {
            return lhs.summary.isClean && !rhs.summary.isClean
        }
        return lhs.place.name.localizedCaseInsensitiveCompare(rhs.place.name) == .orderedAscending
    }

    private func resolveCenter() async throws -> Coordinate {
        let trimmedLocation = locationText.trimmingCharacters(in: .whitespaces)
        guard !trimmedLocation.isEmpty else {
            throw SearchError.missingLocation
        }
        return try await geocoder.coordinate(for: trimmedLocation)
    }

    private enum SearchError: LocalizedError {
        case missingLocation

        var errorDescription: String? {
            switch self {
            case .missingLocation:
                return "Enter a neighborhood, city, or address to search near, e.g. \"Capitol Hill, Seattle.\""
            }
        }
    }

    private static func friendlyMessage(for error: Error) -> String {
        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            return description
        }
        if let serviceError = error as? KingCountyInspectionServiceError {
            switch serviceError {
            case .invalidQuery:
                return "Couldn't build a search query from that input."
            case .badResponse(let statusCode):
                return "King County's inspection data service returned an error (status \(statusCode))."
            }
        }
        return "Something went wrong: \(error.localizedDescription)"
    }
}
