import AppKit
import SwiftUI

struct DeviceInformationSheet: View {
    let device: Device
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 12) {
                Image(systemName: device.systemImage)
                    .font(.title2.weight(.medium))
                    .foregroundStyle(device.online ? Color.accentColor : Color.secondary)
                    .frame(width: 44, height: 44)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(device.name).font(.title3.weight(.semibold))
                    Text(device.online ? "在线" : "离线")
                        .font(.subheadline)
                        .foregroundStyle(device.online ? .green : .secondary)
                }
            }

            Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 12) {
                infoRow("家庭", value: device.homeName)
                infoRow("房间", value: device.roomName)
                infoRow("型号", value: device.model)
                infoRow("设备 ID", value: device.did)
            }

            HStack {
                Button("复制设备 ID") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(device.did, forType: .string)
                }
                Spacer()
                Button("完成") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(26)
        .frame(width: 430)
    }

    @ViewBuilder
    private func infoRow(_ title: String, value: String) -> some View {
        GridRow {
            Text(title).foregroundStyle(.secondary)
            Text(value).textSelection(.enabled)
        }
    }
}
