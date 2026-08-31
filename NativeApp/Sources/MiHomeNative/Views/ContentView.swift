import AppKit
import SwiftUI

struct ContentView: View {
    @Bindable var store: DeviceStore
    @AppStorage("showOfflineDevices") private var showOfflineDevices = true
    @State private var selectedHome = "全部家庭"
    @State private var selectedRoom = "全部房间"
    @State private var selectedDevice: Device?

    private var rooms: [String] { store.rooms(for: selectedHome) }
    private var filteredDevices: [Device] {
        store.devices(for: selectedHome, room: selectedRoom, includeOffline: showOfflineDevices)
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedHome) {
                Section("家庭") {
                    Label("全部家庭", systemImage: "house")
                        .tag("全部家庭")
                    ForEach(store.homes, id: \.self) { home in
                        Label(home, systemImage: "house.fill")
                            .tag(home)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("米家")
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(store.devices.count) 台设备")
                        Text("\(store.onlineCount) 台在线")
                            .foregroundStyle(.secondary)
                    }
                    Divider()
                    SettingsLink {
                        Label("设置", systemImage: "gearshape")
                    }
                    .buttonStyle(.plain)
                }
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
            }
        } detail: {
            HStack(spacing: 0) {
                deviceList
                    .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)

                if let device = selectedDevice {
                    Divider()
                    DeviceDetailView(device: device, store: store) {
                        selectedDevice = nil
                    }
                    .frame(width: 420)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .animation(.snappy(duration: 0.24), value: selectedDevice?.did)
        }
        .onChange(of: selectedHome) { _, _ in selectedRoom = "全部房间" }
    }

    @ViewBuilder
    private var deviceList: some View {
        if store.devices.isEmpty {
            ContentUnavailableView(
                "尚未同步设备",
                systemImage: "homekit",
                description: Text(store.lastError ?? "请在设置中检查米家连接。")
            )
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    roomPicker
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 235, maximum: 330), spacing: 16)], spacing: 16) {
                        ForEach(filteredDevices) { device in
                            Button {
                                selectedDevice = device
                            } label: {
                                DeviceCardView(
                                    device: device,
                                    powerState: store.powerState(for: device),
                                    metric: store.metrics[device.did]
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("复制设备 ID") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(device.did, forType: .string)
                                }
                            }
                            .accessibilityHint("打开设备详情")
                        }
                    }
                }
                .padding(28)
            }
            .background(.background)
            .navigationTitle(selectedHome == "全部家庭" ? "全部设备" : selectedHome)
            .toolbar { toolbarContent }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(selectedHome == "全部家庭" ? "家里的设备" : selectedHome)
                .font(.system(size: 30, weight: .bold, design: .rounded))
            HStack(spacing: 8) {
                Label("\(filteredDevices.count) 台设备", systemImage: "square.grid.2x2")
                Text("·").foregroundStyle(.tertiary)
                Label("\(filteredDevices.filter(\.online).count) 台在线", systemImage: "circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.green)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var roomPicker: some View {
        HStack(spacing: 8) {
            Picker("房间", selection: $selectedRoom) {
                Text("全部房间").tag("全部房间")
                ForEach(rooms, id: \.self) { room in Text(room).tag(room) }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .controlSize(.large)

            Spacer()

            Toggle("显示离线设备", isOn: $showOfflineDevices)
                .toggleStyle(.switch)
                .controlSize(.small)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                store.loadCache()
            } label: {
                Label("重新载入缓存", systemImage: "arrow.clockwise")
            }
            .keyboardShortcut("r", modifiers: [.command])
        }
    }
}
