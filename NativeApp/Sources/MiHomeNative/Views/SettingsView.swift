import SwiftUI

struct SettingsView: View {
    @AppStorage("showOfflineDevices") private var showOfflineDevices = true
    @AppStorage("automaticRefresh") private var automaticRefresh = true

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 14) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("设置")
                        .font(.title2.weight(.bold))
                    Text("调整米家在这台 Mac 上的显示方式")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            SettingsCard("显示") {
                SettingsToggleRow(
                    title: "显示离线设备",
                    subtitle: "在设备列表中保留当前离线的设备",
                    isOn: $showOfflineDevices
                )
            }

            SettingsCard("同步") {
                SettingsToggleRow(
                    title: "启动时读取本地缓存",
                    subtitle: "更快显示上一次同步到的设备",
                    isOn: $automaticRefresh
                )
            }

            SettingsCard("数据") {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "internaldrive")
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("本地缓存")
                            .font(.subheadline.weight(.medium))
                        Text("Application Support/MiHome-Mac")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("设备控制与云端同步通过独立的米家协议服务处理。")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 2)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(28)
        .frame(width: 540, height: 490, alignment: .topLeading)
        .background(.background)
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String
    private let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
    }
}
