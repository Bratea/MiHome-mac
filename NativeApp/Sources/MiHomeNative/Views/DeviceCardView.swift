import SwiftUI

struct DeviceCardView: View {
    let device: Device
    let powerState: Bool?
    let metric: String?
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Image(systemName: device.systemImage)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(device.online ? Color.accentColor : Color.secondary)
                    .frame(width: 46, height: 46)
                    .background(device.online ? Color.accentColor.opacity(0.10) : Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Spacer(minLength: 12)

                if let powerState {
                    Image(systemName: powerState ? "power.circle.fill" : "power.circle")
                        .font(.title3)
                        .foregroundStyle(powerState ? Color.accentColor : .secondary)
                        .accessibilityLabel(powerState ? "当前已打开" : "当前已关闭")
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
                Text(device.online ? (metric ?? "在线") : "离线")
                    .font(.caption)
                    .foregroundStyle(device.online ? .primary : .secondary)
                Spacer()
            }
            .padding(.top, 13)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 170, maxHeight: 190, alignment: .topLeading)
        .background(isHovered ? .thinMaterial : .regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(isHovered ? Color.accentColor.opacity(0.36) : Color.secondary.opacity(0.16), lineWidth: isHovered ? 1 : 0.5)
        }
        .shadow(color: isHovered ? Color.black.opacity(0.12) : .clear, radius: 12, y: 5)
        .scaleEffect(isHovered ? 1.01 : 1)
        .opacity(device.online ? 1 : 0.58)
        .animation(.easeOut(duration: 0.16), value: isHovered)
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .combine)
    }
}
