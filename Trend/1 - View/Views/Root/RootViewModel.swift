// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor @Observable
final class RootViewModel {
    var importSelection: WeightImportSelection?
    private var pendingImports: [URL] = []

    func open(_ url: URL) {
        // Opening another document must not interrupt an import in progress.
        if importSelection != nil { pendingImports.append(url) }
        else { importSelection = WeightImportSelection(url: url) }
    }

    func importDismissed() {
        if !pendingImports.isEmpty {
            importSelection = WeightImportSelection(url: pendingImports.removeFirst())
        }
    }
}

