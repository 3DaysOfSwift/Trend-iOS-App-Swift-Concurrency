// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Testing
@testable import Trend

@MainActor
struct PurchaseManagerTests {
    @Test func startLoadsProductWithoutInventingAnEntitlement() async {
        let client = InMemoryPurchaseClient()
        let manager = PurchaseManager(client: client)

        await manager.start()

        #expect(manager.habitsProduct?.displayName == "Trend Habits")
        #expect(!manager.hasUnlockedHabits)
        #expect(!manager.isLoading)
    }

    @Test func completedPurchaseUnlocksHabits() async {
        let client = InMemoryPurchaseClient()
        let manager = PurchaseManager(client: client)
        await manager.start()

        await manager.purchaseHabits()

        #expect(manager.hasUnlockedHabits)
    }

    @Test func cancelledPurchaseLeavesHabitsLocked() async {
        let client = InMemoryPurchaseClient()
        client.nextOutcome = .cancelled
        let manager = PurchaseManager(client: client)
        await manager.start()

        await manager.purchaseHabits()

        #expect(!manager.hasUnlockedHabits)
        #expect(manager.message == nil)
    }

    @Test func restoreReadsTheCustomersExistingEntitlement() async {
        let client = InMemoryPurchaseClient()
        client.hasPurchased = true
        let manager = PurchaseManager(client: client)

        await manager.restorePurchases()

        #expect(manager.hasUnlockedHabits)
        #expect(manager.message == "Trend Habits has been restored.")
    }
}
