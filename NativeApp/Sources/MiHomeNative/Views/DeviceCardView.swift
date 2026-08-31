import SwiftUI

struct DeviceCardView: View {
    let device: Device
    let powerState: Bool?
    let metric: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Image(systemName: device.systemImage)
                    .font(.title2.weight(.medium))
                    .foregroundStyle(device.online ? Color.accentColor : Color.secondary)
                    .frame(width: 40, height: 40)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                Spacer(minLength: 12)

                if let powerState {
                    Image(systemName: powerState ? "power.circle.fill" : "power.circle")
                        .font(.title2)
                        .foregroundStyle(powerState ? Color.accentColor : .secondary)
                        .accessibilityLabel(powerState ? "当前已打开" : "当前已关闭")
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(device.name)
                    .font(.headline)
                    .lineLimit(2)
                Text(device.roomName == "未知" ? device.model : device.roomName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(device.online ? Color.green : Color.secondary.opacity(0.55))
                    .frame(width: 7, height: 7)
                Text(device.online ? (metric ?? "在线") : "离线")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 174, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        }
        .opacity(device.online ? 1 : 0.58)
        .accessibilityElement(children: .combine)
    }
}
