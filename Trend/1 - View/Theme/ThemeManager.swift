// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

/// Owns the user's visual preference. This is UI state, so it intentionally
/// lives outside AppBrain and never influences application behaviour.
@MainActor
@Observable
final class ThemeManager {
    private static let preferenceKey = "selectedAppColourTheme"
    private let preferences: UserDefaults

    var selectedTheme: AppColourTheme {
        didSet { preferences.set(selectedTheme.rawValue, forKey: Self.preferenceKey) }
    }

    var palette: AppThemePalette { selectedTheme.palette }

    init(preferences: UserDefaults = .standard) {
        self.preferences = preferences
        selectedTheme = preferences.string(forKey: Self.preferenceKey)
            .flatMap(AppColourTheme.init(rawValue:)) ?? .daylight
    }

    func selectNextTheme() {
        let themes = AppColourTheme.allCases
        guard let index = themes.firstIndex(of: selectedTheme) else {
            selectedTheme = .daylight
            return
        }
        selectedTheme = themes[(index + 1) % themes.count]
    }
}
