// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct EntryEditorView: View {
    @State private var viewModel: EntryEditorViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var weightIsFocused: Bool
    @State private var showsDetails = false

    init(entry: WeightEntry? = nil) {
        _viewModel = State(initialValue: EntryEditorViewModel(entry: entry))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GeometryReader { proxy in
                    ScrollView {
                        VStack(spacing: 28) {
                            Spacer(minLength: 12)
                            measurementDisplay
                            details
                            if let message = viewModel.errorMessage { errorBanner(message) }
                            Spacer(minLength: 12)
                        }
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .scrollIndicators(.hidden)
                }
            }
            .background(Color.trendBackground)
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await viewModel.save() { dismiss() }
                        }
                    }
                        .fontWeight(.semibold)
                        .disabled(!viewModel.canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { weightIsFocused = false }
                }
            }
        }
        .interactiveDismissDisabled(viewModel.isSaving)
        .task {
            // Wait for the sheet transition so focus reliably presents the keypad.
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            weightIsFocused = true
        }
    }

    private var measurementDisplay: some View {
        @Bindable var viewModel = viewModel

        return VStack(spacing: 14) {
            Text("CURRENT WEIGHT")
                .font(.caption.weight(.semibold))
                .tracking(1.8)
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                TextField(
                    "0.0",
                    text: $viewModel.draft.value,
                    prompt: Text("0.0").foregroundStyle(.white.opacity(0.24))
                )
                .keyboardType(.decimalPad)
                .focused($weightIsFocused)
                .multilineTextAlignment(.center)
                .font(.system(size: 112, weight: .medium, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .tint(.white)
                .minimumScaleFactor(0.42)
                .lineLimit(1)
                .accessibilityLabel("Current weight")
                .accessibilityValue(viewModel.draft.value.isEmpty ? "Not entered" : "\(viewModel.draft.value) \(viewModel.unit.symbol)")

                Text(viewModel.unit.symbol.uppercased())
                    .font(.headline.monospaced())
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.72))
            }
            .frame(maxWidth: .infinity, minHeight: 188)
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.02, green: 0.20, blue: 0.22), Color(red: 0.02, green: 0.38, blue: 0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(.white.opacity(0.14), lineWidth: 1)
                            .padding(1)
                    }
                    .shadow(color: Color.trendTeal.opacity(0.26), radius: 24, y: 12)
            }
            .contentShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .onTapGesture { weightIsFocused = true }

            Text("Use the keypad to enter today’s measurement")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var details: some View {
        @Bindable var viewModel = viewModel

        return DisclosureGroup(isExpanded: $showsDetails) {
            VStack(spacing: 16) {
                DatePicker(
                    "Date",
                    selection: $viewModel.draft.date,
                    in: ...viewModel.latestPermittedEntryDate
                )
                Divider()
                TextField("Add a note (optional)", text: $viewModel.draft.note, axis: .vertical)
                    .lineLimit(2...4)
            }
            .padding(.top, 14)
        } label: {
            Label("Date and note", systemImage: "slider.horizontal.3")
                .font(.subheadline.weight(.semibold))
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func errorBanner(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.circle.fill")
            .font(.subheadline)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.red.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
    }
}
