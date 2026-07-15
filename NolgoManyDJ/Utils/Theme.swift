import SwiftUI

// MARK: - App Color Palette
// White base with navy, blue, and cyan accents inspired by the refreshed art-gallery direction.
extension Color {
    // Primary - vivid gallery blue
    static let appPrimary = Color(hex: "2E6BFF")
    static let appPrimaryLight = Color(hex: "A7EAF4")
    static let appPrimaryDark = Color(hex: "061B52")

    // Secondary - clear cyan
    static let appSecondary = Color(hex: "11B8D6")
    static let appSecondaryLight = Color(hex: "DDF8FF")

    // Accent - fresh signal green
    static let appAccent = Color(hex: "32E982")
    static let appAccentLight = Color(hex: "E9FFF3")

    // Background
    static let appBackground = Color(hex: "F7FBFF")
    static let appCardBackground = Color(hex: "FFFFFF")
    static let appSurfaceDim = Color(hex: "EDF5FF")

    // Text
    static let appTextPrimary = Color(hex: "08192F")
    static let appTextSecondary = Color(hex: "526B86")
    static let appTextTertiary = Color(hex: "9BAFC5")

    // Utility
    static let appDivider = Color(hex: "DDEBFA")
}

// Allow `.appPrimary`-style lookup in SwiftUI APIs that infer `ShapeStyle`.
extension ShapeStyle where Self == Color {
    static var appPrimary: Color { Color.appPrimary }
    static var appPrimaryLight: Color { Color.appPrimaryLight }
    static var appPrimaryDark: Color { Color.appPrimaryDark }
    static var appSecondary: Color { Color.appSecondary }
    static var appSecondaryLight: Color { Color.appSecondaryLight }
    static var appAccent: Color { Color.appAccent }
    static var appAccentLight: Color { Color.appAccentLight }
    static var appBackground: Color { Color.appBackground }
    static var appCardBackground: Color { Color.appCardBackground }
    static var appSurfaceDim: Color { Color.appSurfaceDim }
    static var appTextPrimary: Color { Color.appTextPrimary }
    static var appTextSecondary: Color { Color.appTextSecondary }
    static var appTextTertiary: Color { Color.appTextTertiary }
    static var appDivider: Color { Color.appDivider }
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
struct AppFont {
    static func title(_ size: CGFloat = 24) -> Font {
        .system(size: size, weight: .bold)
    }

    static func subtitle(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .semibold)
    }

    static func heading(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .bold)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular)
    }

    static func caption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium)
    }

    static func label(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .semibold)
    }

    static func storyQuote(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .regular)
    }
}

// MARK: - Spacing
struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

struct AppRadius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 20
    static let xl: CGFloat = 28
}
