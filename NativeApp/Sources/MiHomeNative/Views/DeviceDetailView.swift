import AppKit
import SwiftUI

struct DeviceDetailView: View {
    let device: Device
    @Bindable var store: DeviceStore
    let onClose: () -> Void

    @State private var showingDeviceInformation = false
    @AppStorage("themeColor") private var themeColor = AppThemeColor.blue.rawValue
    @AppStorage("customThemeHex") private var customThemeHex = "#387AE6"
    @Environment(\.colorScheme) private var colorScheme

    private var tint: Color { AppThemeColor.color(for: themeColor, customHex: customThemeHex) }

    private var detail: DeviceControlDetail? { store.controlDetail(for: device.did) }
    private var powerState: Bool? { store.propertyValue(for: device.did, name: "on")?.boolValue ?? store.powerState(for: device) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if store.isLoadingControl(for: device.did), detail == nil {
                        ProgressView("正在读取设备功能…")
                            .frame(maxWidth: .infinity, minHeight: 230)
                    } else if let error = store.controlError(for: device.did), detail == nil {
                        ContentUnavailableView {
                            Label("无法读取设备功能", systemImage: "exclamationmark.triangle")
                        } description: {
                            Text(error)
                        } actions: {
                            Button("重试") { Task { await store.loadControls(for: device) } }
                        }
                        .frame(maxWidth: .infinity, minHeight: 230)
                    } else if let detail {
                        controls(for: detail)
                            .id(detail.did)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .padding(18)
            }
            Divider()
            HStack {
                if let error = store.controlError(for: device.did) {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
                Spacer()
                Button("关闭") { onClose() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(AppMotion.panel, value: device.did)
        .animation(AppMotion.panel, value: detail?.did)
        .animation(AppMotion.state, value: powerState)
        .task(id: device.did) { await store.loadControls(for: device) }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: device.systemImage)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(device.online ? tint : Color.secondary)
                .frame(width: 50, height: 50)
                .background(device.online ? tint.opacity(0.10) : Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name).font(.title3.weight(.semibold))
                Text(device.roomName == "未知" ? device.homeName : "\(device.homeName) · \(device.roomName)")
                    .foregroundStyle(.secondary)
                HStack(spacing: 5) {
                    Label(device.online ? "在线" : "离线", systemImage: "circle.fill")
                    if device.online, let powerState {
                        Text("·")
                        Text(powerState ? "已开启" : "已关闭")
                    }
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(device.online ? .green : .secondary)
            }
            Spacer()
            VStack(spacing: 6) {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(device.did, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help("复制设备 ID")

                Button {
                    showingDeviceInformation = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.borderless)
                .help("设备信息")
                .popover(isPresented: $showingDeviceInformation, arrowEdge: .trailing) {
                    DeviceInformationPopover(device: device)
                        .frame(width: 340)
                }
                .animation(AppMotion.panel, value: showingDeviceInformation)
            }
        }
        .padding(18)
    }

    @ViewBuilder
    private func controls(for detail: DeviceControlDetail) -> some View {
        if device.model == "lumi.acpartner.mcn02" {
            ACPartnerControlView(device: device, detail: detail, store: store)
        } else {
            GenericDeviceControlView(device: device, detail: detail, store: store)
        }
    }
}
