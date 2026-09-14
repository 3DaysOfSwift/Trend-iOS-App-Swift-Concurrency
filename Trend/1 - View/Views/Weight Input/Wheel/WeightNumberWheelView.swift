// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct WeightNumberWheelView: View {
    @State private var viewModel = WeightNumberWheelViewModel()
    @GestureState private var isDragging = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var selection: Int
    let label: String
    let maximum: Int
    let repeats: Bool
    let width: CGFloat

    // With 122-point row spacing this reveals roughly a quarter of each
    // neighbouring glyph, rather than three complete rows.
    private let viewportHeight: CGFloat = 190

    var body: some View {
        ZStack {
            ForEach(-2...2, id: \.self) { offset in
                if let number = viewModel.neighbour(of: selection, offset: offset, maximum: maximum, repeats: repeats) {
                    let distance = Double(offset) * viewModel.rowSpacing + viewModel.dragOffset
                    let prominence = max(0, 1 - abs(distance) / viewModel.rowSpacing)
                    Text("\(number)")
                        .font(.system(size: 144, weight: .medium, design: .rounded).monospacedDigit())
                        .minimumScaleFactor(0.3)
                        .lineLimit(1)
                        .foregroundStyle(.white.opacity(0.1 + 0.9 * prominence))
                        .frame(width: width, height: 180)
                        .offset(y: Double(offset) * viewModel.rowSpacing)
                }
            }
        }
        // One transform moves the entire strip. Individual rows never resize
        // or animate their position independently of their neighbours.
        .frame(width: width, height: 180)
        .offset(y: viewModel.dragOffset)
        .frame(width: width, height: viewportHeight)
        .clipped()
        .mask {
            LinearGradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: .white, location: 0.025),
                .init(color: .white, location: 0.975),
                .init(color: .clear, location: 1)
            ], startPoint: .top, endPoint: .bottom)
        }
        .contentShape(Rectangle())
        .highPriorityGesture(
            // Claim a touch immediately, before the enclosing page's pan begins.
            DragGesture(minimumDistance: 0)
                .updating($isDragging) { _, active, _ in active = true }
                .onChanged { gesture in
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        let next = viewModel.drag(translation: gesture.translation.height,
                                                  selection: selection, maximum: maximum, repeats: repeats)
                        // Touching an empty wheel must not manufacture a zero entry.
                        if next != selection { selection = next }
                    }
                }
                .onEnded { _ in settleWheel() }
        )
        .preference(key: WeightWheelInteractionPreferenceKey.self, value: isDragging)
        .onChange(of: isDragging) { _, active in
            // Gesture cancellation must also restore the centred resting layout.
            if !active { settleWheel() }
        }
        .onDisappear { viewModel.endDrag() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue("\(selection)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: selection = viewModel.adjustedValue(selection, increasing: true, maximum: maximum, repeats: repeats)
            case .decrement: selection = viewModel.adjustedValue(selection, increasing: false, maximum: maximum, repeats: repeats)
            @unknown default: break
            }
        }
    }

    private func settleWheel() {
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.2)) {
            viewModel.endDrag()
        }
    }
}
