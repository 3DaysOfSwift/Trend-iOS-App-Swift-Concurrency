// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import StoreKit

@MainActor
protocol PurchaseClient: AnyObject {
    func product(withID id: String) async throws -> PurchaseProduct?
    func purchase(productID: String) async throws -> PurchaseOutcome
    func hasEntitlement(for productID: String) async -> Bool
    func restore() async throws
    func transactionUpdates() -> AsyncStream<Void>
}

@MainActor
final class StoreKitPurchaseClient: PurchaseClient {
    private var products: [String: Product] = [:]

    func product(withID id: String) async throws -> PurchaseProduct? {
        guard let product = try await Product.products(for: [id]).first else { return nil }
        products[id] = product
        return PurchaseProduct(
            id: product.id,
            displayName: product.displayName,
            description: product.description,
            displayPrice: product.displayPrice
        )
    }

    func purchase(productID: String) async throws -> PurchaseOutcome {
        let product: Product
        if let cached = products[productID] {
            product = cached
        } else if let loaded = try await Product.products(for: [productID]).first {
            products[productID] = loaded
            product = loaded
        } else {
            throw PurchaseError.productUnavailable
        }

        switch try await product.purchase() {
        case .success(let verification):
            let transaction = try verified(verification)
            await transaction.finish()
            return .purchased
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            return .cancelled
        }
    }

    func hasEntitlement(for productID: String) async -> Bool {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == productID, transaction.revocationDate == nil {
                return true
            }
        }
        return false
    }

    func restore() async throws {
        try await AppStore.sync()
    }

    func transactionUpdates() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let task = Task {
                for await result in Transaction.updates {
                    guard case .verified(let transaction) = result else { continue }
                    await transaction.finish()
                    continuation.yield()
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): value
        case .unverified: throw PurchaseError.failedVerification
        }
    }
}

enum PurchaseError: LocalizedError {
    case productUnavailable
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .productUnavailable: "Trend Habits is temporarily unavailable."
        case .failedVerification: "The App Store could not verify this purchase."
        }
    }
}
