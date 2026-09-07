// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct RootViewModelTests {
    @Test func applicationLaunchLoadsApplicationOnlyOnce() async {
        let repository = InMemoryWeightRepository()
        let appModel = TestAppModelFactory.make(repository: repository)
        let viewModel = RootViewModel(appModel: appModel)

        await viewModel.applicationDidFinishLaunching()
        await viewModel.applicationDidFinishLaunching()

        #expect(await repository.loadCallCount == 1)
    }
}
