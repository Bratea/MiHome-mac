import SwiftUI

struct DeviceActionButton: View {
    let action: DeviceAction
    let isPending: Bool
    let isDisabled: Bool
    let perform: () -> Void

    @State private var showingConfirmation = false
    @AppStorage("themeColor") private var themeColor = AppThemeColor.blue.rawValue
    @AppStorage("customThemeHex") private var customThemeHex = "#387AE6"

    private var tint: Color { AppThemeColor.color(for: themeColor, customHex: customThemeHex) }

    var body: some View {
        Button {
            if action.requiresConfirmation {
                showingConfirmation = true
            } else {
                perform()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: action.systemImage)
                    .font(.body.weight(.semibold))
                    .frame(width: 20)
                    .foregroundStyle(isDisabled ? .secondary : tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(action.localizedTitle)
                        .font(.body.weight(.medium))
                    Text(action.requiresConfirmation ? "将写入设备配置" : "立即执行")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isPending {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .confirmationDialog(
            "执行“\(action.localizedTitle)”？",
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button("执行") { perform() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("此操作会向“\(action.localizedTitle)”对应的米家设备写入配置。")
        }
        .accessibilityLabel(action.localizedTitle)
    }
}

private extension DeviceAction {
    var localizedTitle: String {
        let values = desc.components(separatedBy: " / ")
        return values.last?.isEmpty == false ? values.last! : desc
    }

    var requiresConfirmation: Bool {
        name.hasPrefix("set-") || name.contains("config") || name.contains("ctrl")
    }

    var systemImage: String {
        if name.contains("play") { return "play.fill" }
        if name.contains("clean") { return "sparkles" }
        if requiresConfirmation { return "slider.horizontal.3" }
        return "bolt.fill"
    }
}
