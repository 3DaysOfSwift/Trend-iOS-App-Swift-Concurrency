// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
@testable import Trend

@MainActor
final class InMemoryPurchaseClient: PurchaseClient {
    var product = PurchaseProduct(
        id: PurchaseManager.habitsProductID,
        displayName: "Trend Habits",
        description: "Track the daily signals that matter to you.",
        displayPrice: "£4.99"
    )
    var hasPurchased = false
    var nextOutcome: PurchaseOutcome = .purchased
    var updates = AsyncStream<Void> { _ in }

    func product(withID id: String) async throws -> PurchaseProduct? { product }

    func purchase(productID: String) async throws -> PurchaseOutcome {
        if case .purchased = nextOutcome { hasPurchased = true }
        return nextOutcome
    }

    func hasEntitlement(for productID: String) async -> Bool { hasPurchased }
    func restore() async throws {}
    func transactionUpdates() -> AsyncStream<Void> { updates }
}
