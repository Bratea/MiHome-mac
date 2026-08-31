import AppKit
import SwiftUI

@main
struct MiHomeNativeApp: App {
    @State private var store = DeviceStore()
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearance.system.rawValue
    @AppStorage("themeColor") private var themeColor = AppThemeColor.blue.rawValue
    @AppStorage("customThemeHex") private var customThemeHex = "#387AE6"

    private var preferredScheme: ColorScheme? {
        AppAppearance(rawValue: appearanceMode)?.colorScheme
    }

    private var tint: Color { AppThemeColor.color(for: themeColor, customHex: customThemeHex) }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView(store: store)
                .frame(minWidth: 880, minHeight: 580)
                .preferredColorScheme(preferredScheme)
                .tint(tint)
                .animation(AppMotion.theme, value: appearanceMode)
                .animation(AppMotion.theme, value: themeColor)
                .animation(AppMotion.theme, value: customThemeHex)
        }
        .defaultSize(width: 1_100, height: 720)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("重新载入设备缓存") { store.loadCache() }
                    .keyboardShortcut("r", modifiers: [.command])
            }
        }

        MenuBarExtra {
            MenuBarView(store: store)
                .tint(tint)
        }
        label: {
            Image(systemName: store.onlineCount > 0 ? "house.fill" : "house")
                .symbolRenderingMode(.hierarchical)
                .accessibilityLabel("米家：\(store.onlineCount) 台设备在线")
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .preferredColorScheme(preferredScheme)
                .tint(tint)
        }
    }
}
