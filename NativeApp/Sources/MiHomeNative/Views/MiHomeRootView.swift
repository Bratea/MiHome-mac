import SwiftUI

struct MiHomeRootView: View {
    let store: DeviceStore

    var body: some View {
        Group {
            if store.isCheckingAccount {
                ProgressView("正在检查米家登录状态…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppCanvasBackground())
            } else if store.accountAvailable {
                ContentView(store: store)
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
            } else {
                QRCodeLoginSheet(store: store, allowsDismiss: false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppCanvasBackground())
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
            }
        }
        .animation(AppMotion.panel, value: store.accountAvailable)
        .task { await store.initializeAccount() }
    }
}
