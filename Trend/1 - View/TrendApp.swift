// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

@main
struct TrendApp: App {
    @State private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
                RootView()
                    .environment(themeManager)
                    .preferredColorScheme(themeManager.selectedTheme.colourScheme)
                    .animation(.easeInOut(duration: 0.35), value: themeManager.selectedTheme)
            } else {
                // Unit tests inject isolated AppModel instances. Keeping the live
                // root dormant prevents a test-host launch from opening CloudKit
                // or the developer's real simulator data store.
                Color.clear
            }
        }
    }
}
