// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

/// A complete visual identity for Trend. Semantic colours such as success and
/// error deliberately remain recognisable in every theme.
enum AppColourTheme: String, CaseIterable, Identifiable {
    case daylight
    case midnight
    case quiet

    var id: Self { self }

    var name: String {
        switch self {
        case .daylight: "Daylight"
        case .midnight: "Midnight"
        case .quiet: "Quiet"
        }
    }

    var description: String {
        switch self {
        case .daylight: "Bright, fresh and energetic"
        case .midnight: "Calm, luminous and focused"
        case .quiet: "Warm, natural and understated"
        }
    }

    var symbol: String {
        switch self {
        case .daylight: "sun.max.fill"
        case .midnight: "moon.stars.fill"
        case .quiet: "leaf.fill"
        }
    }

    var colourScheme: ColorScheme {
        switch self {
        case .daylight, .quiet: .light
        case .midnight: .dark
        }
    }

    var palette: AppThemePalette {
        switch self {
        case .daylight:
            AppThemePalette(
                accent: Color(red: 0.00, green: 0.63, blue: 0.59),
                chart: Color(red: 0.00, green: 0.57, blue: 0.64),
                background: Color(red: 0.96, green: 0.97, blue: 0.99),
                surface: .white,
                weightDisplayTop: Color(red: 0.04, green: 0.11, blue: 0.19),
                weightDisplayBottom: Color(red: 0.02, green: 0.29, blue: 0.38),
                success: Color(red: 0.16, green: 0.80, blue: 0.35),
                error: Color(red: 0.96, green: 0.24, blue: 0.29),
                warning: Color(red: 1.00, green: 0.58, blue: 0.12)
            )
        case .midnight:
            AppThemePalette(
                accent: Color(red: 0.24, green: 0.90, blue: 0.84),
                chart: Color(red: 0.22, green: 0.84, blue: 0.92),
                background: Color(red: 0.025, green: 0.045, blue: 0.085),
                surface: Color(red: 0.07, green: 0.10, blue: 0.16),
                weightDisplayTop: Color(red: 0.08, green: 0.10, blue: 0.24),
                weightDisplayBottom: Color(red: 0.04, green: 0.34, blue: 0.42),
                success: Color(red: 0.22, green: 0.86, blue: 0.43),
                error: Color(red: 1.00, green: 0.31, blue: 0.38),
                warning: Color(red: 1.00, green: 0.66, blue: 0.20)
            )
        case .quiet:
            AppThemePalette(
                accent: Color(red: 0.31, green: 0.52, blue: 0.43),
                chart: Color(red: 0.27, green: 0.48, blue: 0.40),
                background: Color(red: 0.96, green: 0.95, blue: 0.91),
                surface: Color(red: 0.995, green: 0.985, blue: 0.95),
                weightDisplayTop: Color(red: 0.16, green: 0.22, blue: 0.20),
                weightDisplayBottom: Color(red: 0.25, green: 0.40, blue: 0.34),
                success: Color(red: 0.22, green: 0.68, blue: 0.33),
                error: Color(red: 0.82, green: 0.25, blue: 0.25),
                warning: Color(red: 0.85, green: 0.48, blue: 0.12)
            )
        }
    }
}

struct AppThemePalette {
    let accent: Color
    let chart: Color
    let background: Color
    let surface: Color
    let weightDisplayTop: Color
    let weightDisplayBottom: Color
    let success: Color
    let error: Color
    let warning: Color
}
