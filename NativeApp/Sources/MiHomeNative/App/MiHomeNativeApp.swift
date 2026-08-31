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

        MenuBarExtra("米家", systemImage: "house.fill") {
            MenuBarView(store: store)
        }

        Settings {
            SettingsView()
        }
    }
}
