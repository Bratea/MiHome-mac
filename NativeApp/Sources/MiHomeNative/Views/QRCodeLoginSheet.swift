import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

struct QRCodeLoginSheet: View {
    let store: DeviceStore
    @Environment(\.dismiss) private var dismiss
    @State private var hasStarted = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: store.accountAvailable && !store.isAuthenticating ? "checkmark.circle.fill" : "qrcode")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(store.accountAvailable && !store.isAuthenticating ? .green : .blue)

            VStack(spacing: 6) {
                Text(store.accountAvailable && !store.isAuthenticating ? "米家账户已连接" : "扫码登录米家")
                    .font(.title3.weight(.bold))
                Text(store.accountAvailable && !store.isAuthenticating
                     ? "现在可以把云端设备同步到这台 Mac。"
                     : "请在米家 App 中扫描二维码，登录信息只保存于本机。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Group {
                if let url = store.qrLoginURL, let image = qrImage(for: url) {
                    Image(nsImage: image)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 224, height: 224)
                        .padding(14)
                        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .black.opacity(0.09), radius: 12, y: 5)
                } else if store.isAuthenticating {
                    ProgressView("正在等待扫码…")
                        .frame(width: 252, height: 252)
                } else {
                    Image(systemName: "checkmark")
                        .font(.system(size: 58, weight: .semibold))
                        .foregroundStyle(.green)
                        .frame(width: 252, height: 252)
                }
            }
            .animation(AppMotion.layout, value: store.qrLoginURL)
            .animation(AppMotion.layout, value: store.isAuthenticating)

            HStack {
                Button("取消") {
                    store.clearQRCodeLogin()
                    dismiss()
                }
                Spacer()
                if store.accountAvailable && !store.isAuthenticating {
                    Button("同步设备") {
                        Task { await store.syncFromCloud() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(store.isSyncing)
                }
            }
        }
        .padding(30)
        .frame(width: 390)
        .task {
            guard !hasStarted else { return }
            hasStarted = true
            await store.startQRCodeLogin()
        }
        .onChange(of: store.accountAvailable) { _, connected in
            guard connected, !store.isAuthenticating else { return }
            store.clearQRCodeLogin()
        }
    }

    private func qrImage(for string: String) -> NSImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let transformed = output.transformed(by: .init(scaleX: 10, y: 10))
        guard let cgImage = CIContext().createCGImage(transformed, from: transformed.extent) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: transformed.extent.width, height: transformed.extent.height))
    }
}
