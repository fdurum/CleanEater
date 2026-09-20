import Foundation

/// `@AppStorage` key names, shared between `ContentView` and `SettingsView` so both
/// read/write the same `UserDefaults` entries without risking a typo'd string.
///
/// (Deliberately not an `ObservableObject` wrapping `@AppStorage` properties: that
/// combination doesn't reliably publish changes to SwiftUI. Each view declares its
/// own `@AppStorage` bindings using these keys instead.)
enum SettingsKey {
    static let lookbackYears = "lookbackYears"
    static let searchRadiusMiles = "searchRadiusMiles"
    static let showAllResults = "showAllResults"
}

enum SettingsDefault {
    static let lookbackYears = 2
    static let searchRadiusMiles = 3.0
    static let showAllResults = false
}
