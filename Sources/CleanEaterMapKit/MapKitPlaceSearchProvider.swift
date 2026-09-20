#if canImport(MapKit)
import MapKit

/// Adapts `MKLocalSearch` to `PlaceSearching` so the search pipeline can be tested
/// against a fake without ever calling a real `MKLocalSearch`.
public struct MapKitPlaceSearchProvider: PlaceSearching {
    public init() {}

    public func search(query: String, near center: Coordinate, radiusMeters: Double) async throws -> [PlaceCandidate] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude),
            latitudinalMeters: radiusMeters * 2,
            longitudinalMeters: radiusMeters * 2
        )
        request.resultTypes = .pointOfInterest

        let search = MKLocalSearch(request: request)
        let response = try await search.start()

        return response.mapItems.compactMap(Self.makeCandidate)
    }

    private static func makeCandidate(from mapItem: MKMapItem) -> PlaceCandidate? {
        guard let name = mapItem.name else { return nil }
        let placemark = mapItem.placemark
        let coordinate = Coordinate(latitude: placemark.coordinate.latitude, longitude: placemark.coordinate.longitude)

        // MKMapItem has no stable identifier; a name+coordinate composite is stable
        // enough to dedupe within a single search response.
        let id = "\(name)|\(coordinate.latitude)|\(coordinate.longitude)"

        return PlaceCandidate(
            id: id,
            name: name,
            streetAddress: placemark.thoroughfareAddress,
            city: placemark.locality,
            coordinate: coordinate
        )
    }
}

private extension MKPlacemark {
    /// e.g. "123 Main St" from `subThoroughfare` + `thoroughfare`.
    var thoroughfareAddress: String? {
        switch (subThoroughfare, thoroughfare) {
        case let (.some(number), .some(street)):
            return "\(number) \(street)"
        case let (nil, .some(street)):
            return street
        default:
            return nil
        }
    }
}
#endif
