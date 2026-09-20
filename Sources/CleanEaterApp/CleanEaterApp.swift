import SwiftUI

@main
struct CleanEaterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 700, minHeight: 420)
        }

        Settings {
            SettingsView()
        }
    }
}
