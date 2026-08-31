import AppKit
import SwiftUI

struct MenuBarView: View {
    let store: DeviceStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text("\(store.onlineCount) 台设备在线")
        Divider()
        Button("打开米家") { openWindow(id: "main") }
            .keyboardShortcut("o")
        Button("重新载入本地缓存") { store.loadCache() }
            .keyboardShortcut("r")
        Divider()
        SettingsLink()
        Divider()
        Button("退出米家") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }
}
