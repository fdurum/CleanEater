import SwiftUI
#if canImport(CleanEaterKit)
import CleanEaterKit
#endif

struct RestaurantDetailView: View {
    let result: CleanRestaurantResult

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.place.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    if let address = result.place.streetAddress {
                        Text([address, result.place.city].compactMap { $0 }.joined(separator: ", "))
                            .foregroundStyle(.secondary)
                    }
                }

                StatusBadge(summary: result.summary)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    detailRow(label: "Inspections", value: "\(result.summary.inspectionCount) since this app's lookback window began")
                    detailRow(label: "Violations", value: "\(result.summary.violationCount)")
                    if let mostRecent = result.summary.mostRecentInspectionDate {
                        detailRow(label: "Most recent inspection", value: Self.dateFormatter.string(from: mostRecent))
                    }
                    if result.summary.wasEverClosed {
                        detailRow(label: "Closed by health department", value: "Yes, within the lookback window")
                    }
                }

                if let reportURL = KingCountyLink.inspectionReportURL(forRestaurantNamed: result.place.name) {
                    Link(destination: reportURL) {
                        Label("View King County Inspection Report", systemImage: "arrow.up.forward.square")
                    }
                }

                Spacer()

                Text("Source: King County Food Establishment Inspection Data")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
            .padding()
        }
        .frame(minWidth: 260)
    }

    private func detailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
        }
    }
}
