import Foundation

/// A plain lat/lon pair, independent of CoreLocation so `CleanEaterKit` has no
/// Apple-only dependencies. `CleanEaterMapKit` converts to/from `CLLocationCoordinate2D`.
public struct Coordinate: Hashable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
