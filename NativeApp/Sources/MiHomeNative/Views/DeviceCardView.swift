import SwiftUI

struct DeviceCardView: View {
    let device: Device
    let powerState: Bool?
    let metric: String?
    let onTogglePower: (() -> Void)?
    let isPowerPending: Bool
    @State private var isHovered = false
    @AppStorage("themeColor") private var themeColor = AppThemeColor.blue.rawValue
    @AppStorage("customThemeHex") private var customThemeHex = "#387AE6"
    private var tint: Color { AppThemeColor.color(for: themeColor, customHex: customThemeHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Image(systemName: device.systemImage)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(device.online ? (powerState == true ? Color.green : tint) : Color.secondary)
                    .frame(width: 46, height: 46)
                    .background(device.online ? (powerState == true ? Color.green.opacity(0.14) : tint.opacity(0.10)) : Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Spacer(minLength: 12)

                if let powerState {
                    Button {
                        onTogglePower?()
                    } label: {
                        Group {
                            if isPowerPending {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "power")
                                    .font(.system(size: 19, weight: .semibold))
                            }
                        }
                        .foregroundStyle(powerTint)
                        .frame(width: 42, height: 42)
                        .background(powerTint.opacity(0.14), in: Circle())
                        .overlay { Circle().strokeBorder(powerTint.opacity(0.22), lineWidth: 1) }
                    }
                    .buttonStyle(.plain)
                    .disabled(onTogglePower == nil || isPowerPending)
                    .help(powerState ? "关闭设备" : "开启设备")
                    .accessibilityLabel(powerState ? "关闭设备" : "开启设备")
                }
            }

            Spacer(minLength: 20)

            VStack(alignment: .leading, spacing: 5) {
                Text(device.name)
                    .font(.headline.weight(.semibold))
                    .lineLimit(2)
                Text(device.roomName == "未知" ? device.model : device.roomName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(device.online ? Color.green : Color.secondary.opacity(0.55))
                    .frame(width: 6, height: 6)
                Text(device.online ? "在线" : "离线")
                    .font(.caption)
                    .foregroundStyle(device.online ? .primary : .secondary)
                if let powerState, device.online {
                    Text(powerState ? "已开启" : "已关闭")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(powerState ? Color.green : Color.orange)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background((powerState ? Color.green : Color.orange).opacity(0.13), in: Capsule())
                } else if let metric {
                    Text(metric)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.top, 13)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 158, maxHeight: 176, alignment: .topLeading)
        .appCardSurface(cornerRadius: 18)
        .overlay {
            if powerState == true {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.green.opacity(0.12))
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    isHovered ? (powerState == true ? Color.green.opacity(0.55) : tint.opacity(0.45)) : (powerState == true ? Color.green.opacity(0.26) : Color.secondary.opacity(0.16)),
                    lineWidth: isHovered ? 1 : 0.5
                )
        }
        .shadow(color: isHovered ? Color.black.opacity(0.12) : .clear, radius: 12, y: 5)
        .scaleEffect(isHovered ? 1.01 : 1)
        .opacity(device.online ? 1 : 0.58)
        .animation(.easeOut(duration: 0.16), value: isHovered)
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .combine)
    }

    private var powerTint: Color {
        powerState == true ? .green : .orange
    }
}
