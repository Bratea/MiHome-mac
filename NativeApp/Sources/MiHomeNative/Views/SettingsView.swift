import SwiftUI

struct SettingsView: View {
    @AppStorage("showOfflineDevices") private var showOfflineDevices = true
    @AppStorage("automaticRefresh") private var automaticRefresh = true
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearance.system.rawValue
    @AppStorage("themeColor") private var themeColor = AppThemeColor.blue.rawValue
    @Environment(\.colorScheme) private var colorScheme

    private var tint: Color { AppThemeColor.color(for: themeColor) }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 14) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(tint.gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("设置")
                        .font(.title2.weight(.bold))
                    Text("调整米家在这台 Mac 上的显示方式")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            SettingsCard("外观") {
                VStack(alignment: .leading, spacing: 14) {
                    Picker("显示模式", selection: $appearanceMode) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Text(appearance.title).tag(appearance.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("主题色")
                        .font(.subheadline.weight(.medium))
                    HStack(spacing: 12) {
                        ForEach(AppThemeColor.allCases) { theme in
                            Button {
                                themeColor = theme.rawValue
                            } label: {
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(theme.color)
                                        .frame(width: 28, height: 28)
                                        .overlay {
                                            if themeColor == theme.rawValue {
                                                Image(systemName: "checkmark")
                                                    .font(.caption.weight(.bold))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                    Text(theme.title)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(width: 50)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("主题色：\(theme.title)")
                        }
                    }
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
        .background(AppThemeColor.canvas(for: colorScheme))
    }
}

private struct SettingsCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
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
                .background(AppThemeColor.card(for: colorScheme), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
