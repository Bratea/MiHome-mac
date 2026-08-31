import AppKit
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
    case rose
    case sage
    case gold
    case custom

    var id: String { rawValue }
    var title: String {
        switch self {
        case .blue: "蓝色"
        case .mint: "薄荷"
        case .violet: "紫色"
        case .orange: "橙色"
        case .rose: "浅粉"
        case .sage: "青绿"
        case .gold: "暖黄"
        case .custom: "自定义"
        }
    }

    var color: Color {
        switch self {
        case .blue: Color(red: 0.22, green: 0.48, blue: 0.90)
        case .mint: Color(red: 0.14, green: 0.67, blue: 0.58)
        case .violet: Color(red: 0.48, green: 0.39, blue: 0.78)
        case .orange: Color(red: 0.84, green: 0.48, blue: 0.23)
        case .rose: Color(red: 0.78, green: 0.42, blue: 0.54)
        case .sage: Color(red: 0.30, green: 0.60, blue: 0.49)
        case .gold: Color(red: 0.72, green: 0.56, blue: 0.23)
        case .custom: Color(hex: UserDefaults.standard.string(forKey: "customThemeHex") ?? "#387AE6")
        }
    }

    static func color(for rawValue: String, customHex: String? = nil) -> Color {
        guard let theme = AppThemeColor(rawValue: rawValue) else { return AppThemeColor.blue.color }
        if theme == .custom, let customHex {
            return Color(hex: customHex)
        }
        return theme.color
    }

    static func canvas(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.09, green: 0.10, blue: 0.11) : Color(red: 0.94, green: 0.95, blue: 0.97)
    }

    static func card(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.15, green: 0.16, blue: 0.18) : .white
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        let red, green, blue: Double
        switch hex.count {
        case 3:
            red = Double((value >> 8) & 0xF) / 15
            green = Double((value >> 4) & 0xF) / 15
            blue = Double(value & 0xF) / 15
        default:
            red = Double((value >> 16) & 0xFF) / 255
            green = Double((value >> 8) & 0xFF) / 255
            blue = Double(value & 0xFF) / 255
        }
        self.init(red: red, green: green, blue: blue)
    }

    var hexString: String {
        let color = NSColor(self).usingColorSpace(.sRGB) ?? .systemBlue
        return String(format: "#%02X%02X%02X", Int(round(color.redComponent * 255)), Int(round(color.greenComponent * 255)), Int(round(color.blueComponent * 255)))
    }
}
