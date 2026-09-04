import Foundation
import Testing
@testable import Trend

@MainActor
struct RootViewModelTests {
    @Test func startLoadsApplicationOnlyOnce() async {
        let repository = InMemoryWeightRepository()
        let brain = TestAppBrainFactory.make(repository: repository)
        let viewModel = RootViewModel(application: brain)

        await viewModel.start()
        await viewModel.start()

        #expect(await repository.loadCallCount == 1)
    }
}
