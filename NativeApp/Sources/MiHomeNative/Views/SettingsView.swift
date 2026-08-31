import SwiftUI

struct SettingsView: View {
    @AppStorage("showOfflineDevices") private var showOfflineDevices = true
    @AppStorage("automaticRefresh") private var automaticRefresh = true

    var body: some View {
        Form {
            Section("显示") {
                Toggle("显示离线设备", isOn: $showOfflineDevices)
                Toggle("启动时自动载入本地缓存", isOn: $automaticRefresh)
            }
            Section("数据") {
                LabeledContent("缓存位置") {
                    Text("Application Support/MiHome-Mac")
                        .foregroundStyle(.secondary)
                }
                Text("设备控制与云端同步将通过独立的米家协议服务处理。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 470)
        .padding(20)
    }
}
