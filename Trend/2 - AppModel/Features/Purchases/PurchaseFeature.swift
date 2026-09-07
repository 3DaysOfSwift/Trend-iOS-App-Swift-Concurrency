// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

@MainActor
protocol PurchaseFeature: AnyObject {
    var habitsProduct: PurchaseProduct? { get }
    var hasUnlockedHabits: Bool { get }
    var isLoading: Bool { get }
    var isPurchasing: Bool { get }
    var message: String? { get }
    var newlyCompletedPurchaseID: UUID? { get }

    func observeTransactionUpdates()
    func refreshStoreState() async
    func purchaseHabits() async
    func restorePurchases() async
    func dismissMessage()
}
