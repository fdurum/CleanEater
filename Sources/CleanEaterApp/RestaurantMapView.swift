import MapKit
import SwiftUI

/// Browse mode: shows every result as a pin with a clean/not-clean badge underneath,
/// and lets the user re-run the search over whatever area they've panned/zoomed to
/// (`ComplianceSearchService.browseCleanRestaurants`), independent of the cuisine/name
/// search the Table view uses.
struct RestaurantMapView: View {
    @ObservedObject var viewModel: SearchViewModel
    let results: [CleanRestaurantResult]
    let lookbackYears: Int

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var visibleRegion: MKCoordinateRegion?

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition, selection: $viewModel.selection) {
                ForEach(results) { result in
                    Annotation(result.place.name, coordinate: result.place.coordinate.clLocationCoordinate) {
                        VStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title2)
                                .foregroundStyle(result.summary.isClean ? Color.green : Color.orange)
                            CleanBadge(isClean: result.summary.isClean)
                        }
                    }
                    .tag(result.id)
                }
            }
            .onMapCameraChange { context in
                visibleRegion = context.region
            }

            if let errorMessage = viewModel.errorMessage {
                banner {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            } else {
                banner { searchThisAreaButton }
            }
        }
    }

    private func banner(@ViewBuilder content: () -> some View) -> some View {
        content()
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: Capsule())
            .padding(.top, 12)
    }

    private var searchThisAreaButton: some View {
        Button {
            guard let visibleRegion else { return }
            let center = Coordinate(latitude: visibleRegion.center.latitude, longitude: visibleRegion.center.longitude)
            Task {
                await viewModel.browse(center: center, radiusMiles: visibleRegion.approximateRadiusMiles, lookbackYears: lookbackYears)
            }
        } label: {
            if viewModel.isSearching {
                ProgressView()
                    .controlSize(.small)
            } else {
                Label("Search This Area", systemImage: "arrow.clockwise")
            }
        }
        .buttonStyle(.borderless)
        .disabled(viewModel.isSearching || visibleRegion == nil)
    }
}

/// A compact clean/not-clean indicator sized for a map pin, distinct from
/// `StatusBadge` (which is sized for a table row and hardcodes its own font/label
/// style, so it can't be shrunk to fit here).
private struct CleanBadge: View {
    let isClean: Bool

    var body: some View {
        Image(systemName: isClean ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
            .font(.caption2)
            .foregroundStyle(isClean ? Color.green : Color.orange)
            .padding(4)
            .background(.thinMaterial, in: Circle())
    }
}

private extension Coordinate {
    var clLocationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

private extension MKCoordinateRegion {
    /// A rough radius covering the visible map area, for feeding back into
    /// `ComplianceSearchService`'s radius-based search. Doesn't need to be exact —
    /// just a reasonable stand-in for "whatever's on screen right now."
    var approximateRadiusMiles: Double {
        let metersPerDegreeLatitude = 111_320.0
        let metersPerDegreeLongitude = metersPerDegreeLatitude * cos(center.latitude * .pi / 180)
        let latSpanMeters = span.latitudeDelta * metersPerDegreeLatitude
        let lonSpanMeters = span.longitudeDelta * metersPerDegreeLongitude
        let radiusMeters = max(latSpanMeters, lonSpanMeters) / 2
        return radiusMeters / 1609.34
    }
}
