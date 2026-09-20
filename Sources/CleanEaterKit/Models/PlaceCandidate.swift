import Foundation

/// A restaurant/place returned by a search provider (e.g. `MKLocalSearch` via
/// `CleanEaterMapKit`), before it has been matched against King County's data.
public struct PlaceCandidate: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let streetAddress: String?
    public let city: String?
    public let coordinate: Coordinate

    public init(
        id: String,
        name: String,
        streetAddress: String?,
        city: String?,
        coordinate: Coordinate
    ) {
        self.id = id
        self.name = name
        self.streetAddress = streetAddress
        self.city = city
        self.coordinate = coordinate
    }
}

/// Something that can search for nearby places by natural-language query.
/// `CleanEaterMapKit` implements this with `MKLocalSearch`; tests can supply a fake.
public protocol PlaceSearching: Sendable {
    func search(query: String, near center: Coordinate, radiusMeters: Double) async throws -> [PlaceCandidate]
}
