// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct WeightWheelInputViewModelTests {
    @Test func wholeWheelStopsButDecimalWheelWrapsInBothDirections() {
        let viewModel = WeightNumberWheelViewModel()
        #expect(viewModel.dragOffset == 0)
        #expect(viewModel.adjustedValue(69, increasing: true, maximum: 500, repeats: false) == 70)
        #expect(viewModel.adjustedValue(0, increasing: false, maximum: 500, repeats: false) == 0)
        #expect(viewModel.adjustedValue(500, increasing: true, maximum: 500, repeats: false) == 500)
        #expect(viewModel.adjustedValue(0, increasing: false, maximum: 9, repeats: true) == 9)
        #expect(viewModel.adjustedValue(9, increasing: true, maximum: 9, repeats: true) == 0)
    }

    @Test func draggingDecimalAcrossEitherBoundaryAlwaysSettlesInTheCentre() {
        let viewModel = WeightNumberWheelViewModel()
        #expect(viewModel.neighbour(of: 0, offset: -1, maximum: 9, repeats: true) == 9)
        #expect(viewModel.neighbour(of: 9, offset: 1, maximum: 9, repeats: true) == 0)
        #expect(viewModel.drag(translation: -122, selection: 9, maximum: 9, repeats: true) == 0)
        // Further callbacks use the original gesture start, not the updated binding.
        #expect(viewModel.drag(translation: -244, selection: 0, maximum: 9, repeats: true) == 1)
        viewModel.endDrag()
        #expect(viewModel.dragOffset == 0)
        #expect(viewModel.drag(translation: 122, selection: 0, maximum: 9, repeats: true) == 9)
        viewModel.endDrag()
        #expect(viewModel.dragOffset == 0)
    }

    @Test func wholeNumberDragStaysInRangeAndCancellationResetsPresentation() {
        let viewModel = WeightNumberWheelViewModel()
        #expect(viewModel.drag(translation: -122 * 31, selection: 69, maximum: 500, repeats: false) == 100)
        viewModel.endDrag()
        #expect(viewModel.drag(translation: -400, selection: 499, maximum: 500, repeats: false) == 500)
        viewModel.endDrag()
        #expect(viewModel.drag(translation: 400, selection: 0, maximum: 500, repeats: false) == 0)
        viewModel.endDrag()
        #expect(viewModel.dragOffset == 0)
        #expect(viewModel.neighbour(of: 0, offset: -1, maximum: 500, repeats: false) == nil)
        #expect(viewModel.neighbour(of: 500, offset: 1, maximum: 500, repeats: false) == nil)
    }

    @Test func changingOnlyTenthsKeepsTheOtherDigits() {
        let viewModel = WeightWheelInputViewModel()
        let updated = viewModel.replacingTenths(with: 6, in: "69.7")
        #expect(updated == "69\(viewModel.decimalSeparator)6")
        #expect(viewModel.wholeValue(in: updated) == 69)
        #expect(viewModel.replacingTenths(with: 0, in: "69.9") == "69\(viewModel.decimalSeparator)0")
        #expect(viewModel.replacingTenths(with: 9, in: "69.0") == "69\(viewModel.decimalSeparator)9")
    }

    @Test func supportsHundredsAndFourDigitPoundMeasurements() {
        let viewModel = WeightWheelInputViewModel()
        #expect(viewModel.maximumWholeValue(for: .kilograms) == 500)
        #expect(viewModel.maximumWholeValue(for: .pounds) == 1102)
        #expect(viewModel.canDisplay("1102.3", unit: .pounds))
        #expect(viewModel.wholeValue(in: "1102.3") == 1102)
        #expect(viewModel.replacingWholeValue(with: 100, in: "69.7", unit: .kilograms) == "100\(viewModel.decimalSeparator)7")
        #expect(viewModel.replacingWholeValue(with: 501, in: "69.7", unit: .kilograms) == "69.7")
        #expect(viewModel.canDisplay("500.0", unit: .kilograms))
    }

    @Test func acceptsCommaDecimalsButDoesNotSilentlyRoundKeyboardInput() {
        let viewModel = WeightWheelInputViewModel()
        #expect(viewModel.tenths(in: "69,7") == 7)
        #expect(viewModel.canDisplay("69,7", unit: .kilograms))
        #expect(!viewModel.canDisplay("69.75", unit: .kilograms))
        #expect(!viewModel.canDisplay("invalid", unit: .kilograms))
        #expect(!viewModel.canDisplay("inf", unit: .kilograms))
        #expect(!viewModel.canDisplay("-69.7", unit: .kilograms))
    }

    @Test func emptyDraftHasNoInventedMeasurement() {
        let viewModel = WeightWheelInputViewModel()
        #expect(viewModel.canDisplay("", unit: .kilograms))
        #expect(viewModel.wholeValue(in: "") == 0)
        #expect(viewModel.replacingWholeValue(with: 70, in: "", unit: .kilograms) == "70\(viewModel.decimalSeparator)0")
    }

    @Test func inputPreferencePersistsAndDefaultsToWheels() {
        let name = UUID().uuidString
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let store = UserSettingsStore(cloudSync: WheelTestCloudStatus(), defaults: defaults)
        #expect(store.weightInputStyle == .wheel)
        store.weightInputStyle = .keyboard
        let reopened = UserSettingsStore(cloudSync: WheelTestCloudStatus(), defaults: defaults)
        #expect(reopened.weightInputStyle == .keyboard)
    }
}

private struct WheelTestCloudStatus: CloudSyncStatusProviding {
    func cloudStatus() async -> CloudSyncStatus { .unavailable }
}
