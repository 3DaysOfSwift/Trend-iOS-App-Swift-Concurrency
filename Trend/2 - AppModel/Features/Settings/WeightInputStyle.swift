// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

enum WeightInputStyle: String, CaseIterable, Identifiable, Sendable {
    case wheel, keyboard
    var id: Self { self }
    var title: String { self == .wheel ? "Weight wheels" : "Numeric keyboard" }
}
