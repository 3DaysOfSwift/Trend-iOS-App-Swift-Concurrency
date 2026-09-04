// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

struct PurchaseProduct: Equatable, Sendable {
    let id: String
    let displayName: String
    let description: String
    let displayPrice: String
}

enum PurchaseOutcome: Sendable {
    case purchased
    case pending
    case cancelled
}
