#if canImport(CoreLocation)
import CoreLocation
import CleanEaterKit

/// Turns a free-text location ("Capitol Hill, Seattle") into a coordinate, so the
/// "where" field in the UI doesn't require the user to grant location access.
public struct GeocodingService {
    private let geocoder = CLGeocoder()

    public init() {}

    public enum GeocodingError: Error {
        case noResults
    }

    public func coordinate(for locationText: String) async throws -> Coordinate {
        let placemarks = try await geocoder.geocodeAddressString(locationText)
        guard let coordinate = placemarks.first?.location?.coordinate else {
            throw GeocodingError.noResults
        }
        return Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
#endif
