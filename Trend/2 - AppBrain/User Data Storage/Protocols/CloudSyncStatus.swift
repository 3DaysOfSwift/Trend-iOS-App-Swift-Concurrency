import Foundation

enum CloudSyncStatus: Equatable, Sendable {
    case checking
    case available
    case unavailable
    case restricted
    case temporarilyUnavailable

    var label: String {
        switch self {
        case .checking: "Checking…"
        case .available: "Syncing"
        case .unavailable: "Sign in to iCloud"
        case .restricted: "Restricted"
        case .temporarilyUnavailable: "Available when online"
        }
    }
}

protocol CloudSyncStatusProviding: Sendable {
    func cloudStatus() async -> CloudSyncStatus
}

