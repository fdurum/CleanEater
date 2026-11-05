import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKey.lookbackYears) private var lookbackYears = SettingsDefault.lookbackYears
    @AppStorage(SettingsKey.searchRadiusMiles) private var searchRadiusMiles = SettingsDefault.searchRadiusMiles
    @AppStorage(SettingsKey.showAllResults) private var showAllResults = SettingsDefault.showAllResults

    var body: some View {
        Form {
            Stepper(value: $lookbackYears, in: 1...5) {
                Text("Lookback window: \(lookbackYears) year\(lookbackYears == 1 ? "" : "s")")
            }
            Stepper(value: $searchRadiusMiles, in: 0.5...10, step: 0.5) {
                Text("Search radius: \(searchRadiusMiles, specifier: "%.1f") mi")
            }
            Toggle("Show all results by default", isOn: $showAllResults)

            Text("\u{201c}Excellent\u{201d} (the toolbar toggle) means King County's own inspection_result never came back unsatisfactory, even if a minor violation was cited \u{2014} that's their call, not a number set here.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 340)
    }
}
