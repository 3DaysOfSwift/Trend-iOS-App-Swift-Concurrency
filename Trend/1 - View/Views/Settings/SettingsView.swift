import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @FocusState private var goalFocused: Bool

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
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
                Section("Your data") {
                    LabeledContent("iCloud", value: viewModel.cloudStatus.label)
                    Button("Export backup", systemImage: "square.and.arrow.up") {
                        Task { await viewModel.prepareExport() }
                    }
                    Button("Import backup", systemImage: "square.and.arrow.down") { viewModel.isImporting = true }
                    Button("Delete all data", systemImage: "trash", role: .destructive) { viewModel.confirmDelete = true }
                }
                Section("About") {
                    LabeledContent("Privacy", value: "Device + private iCloud")
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
            .alert("Delete all data?", isPresented: $viewModel.confirmDelete) {
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
