import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: "跟随系统"
        case .light: "浅色"
        case .dark: "深色"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum AppThemeColor: String, CaseIterable, Identifiable {
    case blue
    case mint
    case violet
    case orange

    var id: String { rawValue }
    var title: String {
        switch self {
        case .blue: "蓝色"
        case .mint: "薄荷"
        case .violet: "紫色"
        case .orange: "橙色"
        }
    }

    var color: Color {
        switch self {
        case .blue: .blue
        case .mint: .mint
        case .violet: .purple
        case .orange: .orange
        }
    }

    static func color(for rawValue: String) -> Color {
        AppThemeColor(rawValue: rawValue)?.color ?? AppThemeColor.blue.color
    }

    static func canvas(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.09, green: 0.10, blue: 0.11) : Color(red: 0.94, green: 0.95, blue: 0.97)
    }

    static func card(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.15, green: 0.16, blue: 0.18) : .white
    }
}
