import Foundation
import Observation

@MainActor
@Observable
final class RootViewModel {
    private let application: any ApplicationLifecycleFeature

    init(application: any ApplicationLifecycleFeature = AppBrain.shared) {
        self.application = application
    }

    func start() async { await application.start() }
}
