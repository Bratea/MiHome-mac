import AppKit
import SwiftUI

@main
struct MiHomeNativeApp: App {
    @State private var store = DeviceStore()

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView(store: store)
                .frame(minWidth: 1_050, minHeight: 580)
        }
        .defaultSize(width: 1_280, height: 760)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("重新载入设备缓存") { store.loadCache() }
                    .keyboardShortcut("r", modifiers: [.command])
            }
        }

        MenuBarExtra {
            MenuBarView(store: store)
        }
        label: {
            Image(systemName: store.onlineCount > 0 ? "house.fill" : "house")
                .symbolRenderingMode(.hierarchical)
                .accessibilityLabel("米家：\(store.onlineCount) 台设备在线")
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(store: store)
        }
    }
}
