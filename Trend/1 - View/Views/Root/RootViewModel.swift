// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor
@Observable
final class RootViewModel {
    private let appBrain: AppBrain

    init(appBrain: AppBrain = .shared) {
        self.appBrain = appBrain
    }

    func applicationDidFinishLaunching() async {
        await appBrain.applicationDidFinishLaunching()
    }
}
