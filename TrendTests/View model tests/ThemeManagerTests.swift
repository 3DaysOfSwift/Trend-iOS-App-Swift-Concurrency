// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct ThemeManagerTests {
    @Test func startsWithDaylightWhenNoPreferenceExists() {
        let preferences = isolatedPreferences()

        let manager = ThemeManager(preferences: preferences)

        #expect(manager.selectedTheme == .daylight)
    }

    @Test func remembersTheSelectedTheme() {
        let preferences = isolatedPreferences()
        let manager = ThemeManager(preferences: preferences)

        manager.selectedTheme = .midnight

        #expect(ThemeManager(preferences: preferences).selectedTheme == .midnight)
    }

    @Test func cyclingMovesThroughEveryThemeAndReturnsToDaylight() {
        let manager = ThemeManager(preferences: isolatedPreferences())

        manager.selectNextTheme()
        #expect(manager.selectedTheme == .midnight)
        manager.selectNextTheme()
        #expect(manager.selectedTheme == .quiet)
        manager.selectNextTheme()
        #expect(manager.selectedTheme == .daylight)
    }

    private func isolatedPreferences() -> UserDefaults {
        let suiteName = "ThemeManagerTests.\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName)!
    }
}
