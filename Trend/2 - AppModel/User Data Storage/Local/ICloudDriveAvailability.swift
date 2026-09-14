// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

actor ICloudDriveAvailability: CloudSyncStatusProviding {
    func cloudStatus() async -> CloudSyncStatus {
        FileManager.default.url(forUbiquityContainerIdentifier: nil) == nil ? .unavailable : .available
    }
}
