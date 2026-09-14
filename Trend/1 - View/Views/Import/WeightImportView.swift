// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct WeightImportView: View {
    @State private var viewModel: WeightImportViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager

    init(url: URL) {
        _viewModel = State(initialValue: WeightImportViewModel(url: url))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    Image(systemName: viewModel.result == nil ? "square.and.arrow.down" : "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(themeManager.palette.accent)
                    Text(viewModel.result == nil ? "Bring your history with you" : "History imported")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    if viewModel.isLoading {
                        SwiftUI.ProgressView("Reading your file…")
                    } else if viewModel.result != nil {
                        Text(viewModel.completionMessage).multilineTextAlignment(.center)
                        Button("Done") { dismiss() }.buttonStyle(.borderedProminent)
                    } else if viewModel.document != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(viewModel.source).font(.headline)
                            Text(viewModel.filename).font(.caption).foregroundStyle(.secondary)
                            Text("\(viewModel.count) weight entries").font(.title2.bold())
                            Text(viewModel.dateRange)
                            Text(viewModel.explanation).font(.footnote).foregroundStyle(.secondary)
                            Text("Existing entries stay. Matching IDs or the same time and weight are skipped; existing notes are kept.")
                                .font(.footnote)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(themeManager.palette.surface, in: RoundedRectangle(cornerRadius: 20))

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Most recent entries").font(.headline)
                            ForEach(viewModel.sample) { entry in
                                HStack {
                                    Text(entry.date, format: .dateTime.day().month().year().hour().minute())
                                    Spacer()
                                    Text("\(entry.kilograms.formatted(.number.precision(.fractionLength(1...4)))) kg")
                                }
                                .font(.subheadline)
                            }
                        }
                        Button {
                            Task { await viewModel.importEntries() }
                        } label: {
                            if viewModel.isImporting {
                                SwiftUI.ProgressView().frame(maxWidth: .infinity)
                            } else {
                                Text("Import weight entries").frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(!viewModel.canImport)
                    }
                    if let error = viewModel.errorMessage {
                        Text(error).foregroundStyle(themeManager.palette.error)
                        if viewModel.document == nil {
                            Button("Try again") { Task { await viewModel.load() } }
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(themeManager.palette.background.ignoresSafeArea())
            .navigationTitle("Import weight history")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(themeManager.palette.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(viewModel.result == nil ? "Cancel" : "Close") { dismiss() }
                        .disabled(viewModel.isImporting)
                }
            }
        }
        .presentationBackground(themeManager.palette.background)
        .interactiveDismissDisabled()
        .task { await viewModel.load() }
    }
}
