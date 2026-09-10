// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct RootView: View {
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "plus.circle.fill") }
            ProjectionView()
                .tabItem { Label("Trend", systemImage: "chart.xyaxis.line") }
            HabitsView()
                .tabItem { Label("Habits", systemImage: "scope") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .background(themeManager.palette.background.ignoresSafeArea())
        .tint(themeManager.palette.accent)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
