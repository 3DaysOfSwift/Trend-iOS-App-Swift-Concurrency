// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

extension View {
    func habitErrorAlert(message: String?, dismiss: @escaping () -> Void) -> some View {
        alert(
            "Couldn’t record check-in",
            isPresented: Binding(
                get: { message != nil },
                set: { if !$0 { dismiss() } }
            )
        ) {
            Button("OK", action: dismiss)
        } message: {
            Text(message ?? "")
        }
    }
}
