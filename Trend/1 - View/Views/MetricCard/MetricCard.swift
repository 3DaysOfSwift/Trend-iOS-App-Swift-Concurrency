// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct MetricCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(themeManager.palette.surface, in: RoundedRectangle(cornerRadius: 18))
    }
}
