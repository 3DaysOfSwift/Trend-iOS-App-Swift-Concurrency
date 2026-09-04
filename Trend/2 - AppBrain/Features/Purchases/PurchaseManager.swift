// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Observation

@MainActor
@Observable
final class PurchaseManager: PurchaseFeature {
    static let habitsProductID = "com.mattharding.Trend.habits"

    private let client: any PurchaseClient
    private var transactionUpdatesTask: Task<Void, Never>?

    private(set) var habitsProduct: PurchaseProduct?
    private(set) var hasUnlockedHabits = false
    private(set) var isLoading = true
    private(set) var isPurchasing = false
    private(set) var message: String?

    init(client: any PurchaseClient) {
        self.client = client
    }

    func start() async {
        listenForTransactionUpdates()
        do {
            habitsProduct = try await client.product(withID: Self.habitsProductID)
            await refreshEntitlements()
        } catch {
            message = error.localizedDescription
        }
        isLoading = false
    }

    func purchaseHabits() async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            switch try await client.purchase(productID: Self.habitsProductID) {
            case .purchased:
                await refreshEntitlements()
            case .pending:
                message = "Your purchase is awaiting approval. Habits will unlock automatically when it completes."
            case .cancelled:
                break
            }
        } catch {
            message = error.localizedDescription
        }
    }

    func restorePurchases() async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await client.restore()
            await refreshEntitlements()
            message = hasUnlockedHabits
                ? "Trend Habits has been restored."
                : "No previous Trend Habits purchase was found."
        } catch {
            message = error.localizedDescription
        }
    }

    func dismissMessage() { message = nil }

    private func refreshEntitlements() async {
        hasUnlockedHabits = await client.hasEntitlement(for: Self.habitsProductID)
    }

    private func listenForTransactionUpdates() {
        guard transactionUpdatesTask == nil else { return }
        transactionUpdatesTask = Task { @MainActor [weak self, client] in
            for await _ in client.transactionUpdates() {
                guard let self else { return }
                await self.refreshEntitlements()
            }
        }
    }
}
