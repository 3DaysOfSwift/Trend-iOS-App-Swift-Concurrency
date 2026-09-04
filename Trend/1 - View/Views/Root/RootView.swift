// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct RootView: View {
    @State private var viewModel = RootViewModel()
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "plus.circle.fill") }
            ProgressView()
                .tabItem { Label("Projection", systemImage: "chart.xyaxis.line") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .background(themeManager.palette.background.ignoresSafeArea())
        .tint(themeManager.palette.accent)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .task { await viewModel.start() }
    }
}
