// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(ThemeManager.self) private var themeManager
    @FocusState private var goalFocused: Bool

    var body: some View {
        @Bindable var viewModel = viewModel
        @Bindable var themeManager = themeManager

        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $themeManager.selectedTheme) {
                        ForEach(AppColourTheme.allCases) { theme in
                            Label(theme.name, systemImage: theme.symbol)
                                .tag(theme)
                        }
                    }

                    Text(themeManager.selectedTheme.description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Units") {
                    Picker("Weight", selection: $viewModel.unit) {
                        ForEach(WeightUnit.allCases) {
                            Text($0 == .kilograms ? "Kilograms" : "Pounds").tag($0)
                        }
                    }
                }
                Section("Goal") {
                    HStack {
                        TextField("Optional", text: $viewModel.goalText).keyboardType(.decimalPad).focused($goalFocused)
                        Text(viewModel.unit.symbol).foregroundStyle(.secondary)
                        Button("Save") {
                            Task { await viewModel.saveGoal(); goalFocused = false }
                        }
                        .disabled(!viewModel.canSaveGoal)
                    }
                }
                Section("Weight entry") {
                    Picker("Input style", selection: $viewModel.weightInputStyle) {
                        ForEach(WeightInputStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    Text("Weight wheels start at your last recorded weight. Scroll the whole number or decimal, then press + to record your measurement.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Your data") {
                    NavigationLink {
                        HistoryView()
                    } label: {
                        Label("Weight history", systemImage: "clock.arrow.circlepath")
                    }
                    NavigationLink {
                        HabitHistoryView()
                    } label: {
                        Label("Habit history", systemImage: "scope")
                    }
                    NavigationLink("Backups and recovery") { BackupsView() }
                    LabeledContent("iCloud Drive", value: viewModel.cloudStatus.label)
                    Button("Export weight history", systemImage: "square.and.arrow.up") {
                        Task { await viewModel.prepareExport() }
                    }
                    Button("Import weight history", systemImage: "square.and.arrow.down") { viewModel.isImporting = true }
                    Button("Delete weight history", systemImage: "trash", role: .destructive) { viewModel.confirmDelete = true }
                }
                Section("About") {
                    LabeledContent("Storage", value: "On-device + iCloud backups")
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                }
            }
            .navigationTitle("Settings")
            .task { await viewModel.refreshCloudStatus() }
            .refreshable { await viewModel.refreshCloudStatus() }
            .fileExporter(isPresented: $viewModel.isExporting, document: viewModel.exportDocument, contentType: .json, defaultFilename: "Trend Backup") { result in
                if case .failure(let error) = result { viewModel.message = error.localizedDescription }
            }
            .fileImporter(isPresented: $viewModel.isImporting, allowedContentTypes: [.json]) { result in
                Task { await viewModel.importFile(result) }
            }
            .alert("Delete weight history?", isPresented: $viewModel.confirmDelete) {
                Button("Delete", role: .destructive) { Task { await viewModel.deleteAllData() } }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone unless you exported a backup.")
            }
            .alert("Trend", isPresented: Binding(
                get: { viewModel.message != nil },
                set: { if !$0 { viewModel.message = nil } }
            )) {
                Button("OK") { viewModel.message = nil }
            } message: {
                Text(viewModel.message ?? "")
            }
        }
    }
}
