import SwiftUI

@main
struct TrendApp: App {
    var body: some Scene {
        WindowGroup {
            if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
                RootView()
            } else {
                // Unit tests inject isolated AppBrain instances. Keeping the live
                // root dormant prevents a test-host launch from opening CloudKit
                // or the developer's real simulator data store.
                Color.clear
            }
        }
    }
}
