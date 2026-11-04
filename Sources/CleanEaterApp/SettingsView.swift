import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKey.lookbackYears) private var lookbackYears = SettingsDefault.lookbackYears
    @AppStorage(SettingsKey.searchRadiusMiles) private var searchRadiusMiles = SettingsDefault.searchRadiusMiles
    @AppStorage(SettingsKey.showAllResults) private var showAllResults = SettingsDefault.showAllResults
    @AppStorage(SettingsKey.excellentPointsThreshold) private var excellentPointsThreshold = SettingsDefault.excellentPointsThreshold

    var body: some View {
        Form {
            Stepper(value: $lookbackYears, in: 1...5) {
                Text("Lookback window: \(lookbackYears) year\(lookbackYears == 1 ? "" : "s")")
            }
            Stepper(value: $searchRadiusMiles, in: 0.5...10, step: 0.5) {
                Text("Search radius: \(searchRadiusMiles, specifier: "%.1f") mi")
            }
            Toggle("Show all results by default", isOn: $showAllResults)

            Section {
                Stepper(value: $excellentPointsThreshold, in: 0...50) {
                    Text("Excellent rating: ≤ \(excellentPointsThreshold) violation points")
                }
                Text("A restaurant counts as \u{201c}excellent\u{201d} if it was never closed and its total violation points over the lookback window stay at or under this number, even if it wasn\u{2019}t perfectly clean.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(width: 340)
    }
}
