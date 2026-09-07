// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor
@Observable
final class RootViewModel {
    private let appModel: AppModel

    init(appModel: AppModel = .shared) {
        self.appModel = appModel
    }

    func applicationDidFinishLaunching() async {
        await appModel.applicationDidFinishLaunching()
    }
}
