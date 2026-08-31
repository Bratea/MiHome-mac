import SwiftUI

struct SettingsView: View {
    let store: DeviceStore
    @AppStorage("showOfflineDevices") private var showOfflineDevices = true
    @AppStorage("automaticRefresh") private var automaticRefresh = true
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearance.system.rawValue
    @AppStorage("themeColor") private var themeColor = AppThemeColor.blue.rawValue
    @AppStorage("customThemeHex") private var customThemeHex = "#387AE6"
    @AppStorage("liquidGlassEnabled") private var liquidGlassEnabled = false
    @AppStorage("backgroundOpacity") private var backgroundOpacity = 0.82
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingQRCodeLogin = false

    private var tint: Color { AppThemeColor.color(for: themeColor, customHex: customThemeHex) }
    private var customColor: Binding<Color> {
        Binding(get: { Color(hex: customThemeHex) }, set: { customThemeHex = $0.hexString })
    }

    var body: some View {
        ScrollView(.vertical) {
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
                    HStack(spacing: 10) {
                        ForEach(AppThemeColor.allCases) { theme in
                            Button {
                                themeColor = theme.rawValue
                            } label: {
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(theme == .custom ? Color(hex: customThemeHex) : theme.color)
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
                                .frame(width: 48)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("主题色：\(theme.title)")
                        }
                    }

                    if themeColor == AppThemeColor.custom.rawValue {
                        ColorPicker("自定义颜色", selection: customColor, supportsOpacity: false)
                            .font(.subheadline)
                    }

                    Divider()
                    SettingsToggleRow(
                        title: "Liquid Glass",
                        subtitle: "给卡片和弹出面板启用 Apple 系统玻璃质感",
                        isOn: $liquidGlassEnabled
                    )

                    if liquidGlassEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("背景透明度")
                                    .font(.body.weight(.medium))
                                Spacer()
                                Text("\(Int(backgroundOpacity * 100))%")
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            Slider(value: $backgroundOpacity, in: 0.62...0.90, step: 0.01)
                                .tint(tint)
                            Text("使用系统 backdrop blur，底下应用的文字会被模糊处理。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
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

            SettingsCard("米家账户") {
                HStack(spacing: 12) {
                    Image(systemName: store.accountAvailable ? "checkmark.icloud.fill" : "icloud")
                        .font(.title3)
                        .foregroundStyle(store.accountAvailable ? .green : .secondary)
                        .frame(width: 30)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(store.accountAvailable ? "账户已连接" : "尚未连接米家账户")
                            .font(.body.weight(.medium))
                        Text(store.accountAvailable ? "可同步云端设备、在线状态与基础数据" : "通过手机米家 App 扫码登录")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 12)
                    VStack(alignment: .trailing, spacing: 8) {
                        Button("扫码登录") { showingQRCodeLogin = true }
                            .buttonStyle(.bordered)
                        Button {
                            Task { await store.syncFromCloud() }
                        } label: {
                            if store.isSyncing { ProgressView().controlSize(.small) }
                            else { Text("同步设备") }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!store.accountAvailable || store.isSyncing)
                    }
                }
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
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 570, height: 610, alignment: .topLeading)
        .scrollIndicators(.visible)
        .background(AppCanvasBackground())
        .background(WindowTransparencyConfigurator(enabled: liquidGlassEnabled).allowsHitTesting(false))
        .animation(AppMotion.theme, value: appearanceMode)
        .animation(AppMotion.theme, value: themeColor)
        .animation(AppMotion.theme, value: customThemeHex)
        .animation(AppMotion.layout, value: liquidGlassEnabled)
        .onAppear {
            if backgroundOpacity < 0.62 {
                backgroundOpacity = 0.82
            }
        }
        .task { await store.refreshAccountStatus() }
        .sheet(isPresented: $showingQRCodeLogin) {
            QRCodeLoginSheet(store: store)
        }
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
                .appCardSurface(cornerRadius: 14)
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
