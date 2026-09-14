// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct RootView: View {
    @State private var viewModel = RootViewModel()
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        @Bindable var viewModel = viewModel
        TabView {
            // Tab-bar preferences flow from each tab's content to its enclosing TabView.
            TodayView()
                .tabItem { Label("Today", systemImage: "plus.circle.fill") }
                .toolbarBackground(.ultraThinMaterial, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            ProjectionView()
                .tabItem { Label("Trend", systemImage: "chart.xyaxis.line") }
                .toolbarBackground(.ultraThinMaterial, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            HabitsView()
                .tabItem { Label("Habits", systemImage: "scope") }
                .toolbarBackground(.ultraThinMaterial, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .toolbarBackground(.ultraThinMaterial, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
        }
        .background(themeManager.palette.background.ignoresSafeArea())
        .tint(themeManager.palette.accent)
        .onOpenURL { viewModel.open($0) }
        .sheet(item: $viewModel.importSelection, onDismiss: viewModel.importDismissed) { selection in
            WeightImportView(url: selection.url)
        }
    }
}
