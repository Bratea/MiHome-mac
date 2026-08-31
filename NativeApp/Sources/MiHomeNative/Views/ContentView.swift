import AppKit
import SwiftUI

struct ContentView: View {
    @Bindable var store: DeviceStore
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("showOfflineDevices") private var showOfflineDevices = true
    @AppStorage("liquidGlassEnabled") private var liquidGlassEnabled = false
    @State private var selectedHome = "全部家庭"
    @State private var selectedRoom = "全部房间"
    @State private var selectedDevice: Device?
    @State private var displayedDevice: Device?
    @State private var showingActivityLog = false

    private var rooms: [String] { store.rooms(for: selectedHome) }
    private var filteredDevices: [Device] {
        store.devices(for: selectedHome, room: selectedRoom, includeOffline: showOfflineDevices)
    }
    private var inspectorWidth: CGFloat { selectedDevice == nil ? 0 : 420 }

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
            .scrollContentBackground(.hidden)
            .background(.clear)
            .navigationTitle("米家")
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(store.devices.count) 台设备")
                        Text("\(store.onlineCount) 台在线")
                            .foregroundStyle(.secondary)
                    }
                    Divider()
                    HStack(spacing: 8) {
                        SettingsLink {
                            Label("设置", systemImage: "gearshape")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 9)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                        Button {
                            showingActivityLog.toggle()
                        } label: {
                            Label("日志", systemImage: "list.bullet.rectangle")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 9)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .popover(isPresented: $showingActivityLog, arrowEdge: .bottom) {
                            ActivityLogView(store: store)
                                .frame(width: 360, height: 440)
                        }
                    }
                }
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
            }
        } detail: {
            HStack(spacing: 0) {
                deviceList
                    .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
                inspector
            }
            .animation(AppMotion.layout, value: selectedDevice?.did)
        }
        .background(AppCanvasBackground())
        .background(WindowTransparencyConfigurator(enabled: liquidGlassEnabled).allowsHitTesting(false))
        .onChange(of: selectedHome) { _, _ in selectedRoom = "全部房间" }
        .onChange(of: selectedDevice?.did) { _, _ in
            if let selectedDevice {
                displayedDevice = selectedDevice
            }
        }
        .overlay(alignment: .topTrailing) {
            if let notification = store.notification {
                NotificationToast(notification: notification) {
                    store.dismissNotification(id: notification.id)
                }
                .padding(20)
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .animation(.snappy(duration: 0.28), value: store.notification?.id)
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
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 210, maximum: 240), spacing: 16)], spacing: 16) {
                        ForEach(filteredDevices) { device in
                            DeviceCardView(
                                device: device,
                                powerState: store.powerState(for: device),
                                metric: store.metrics[device.did],
                                onTogglePower: powerToggle(for: device),
                                isPowerPending: store.isCommandPending("\(device.did):on"),
                                isSelected: selectedDevice?.did == device.did
                            )
                            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .gesture(
                                TapGesture().onEnded { presentInspector(for: device) },
                                including: .gesture
                            )
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
            .contentShape(Rectangle())
            .onTapGesture {
                if selectedDevice != nil {
                    dismissInspector()
                }
            }
            .navigationTitle(selectedHome == "全部家庭" ? "全部设备" : selectedHome)
            .toolbar { toolbarContent }
        }
    }

    private func powerToggle(for device: Device) -> (() -> Void)? {
        guard store.powerState(for: device) != nil else { return nil }
        return {
            guard let isOn = store.powerState(for: device) else { return }
            Task { await store.setProperty(did: device.did, name: "on", value: .bool(!isOn)) }
        }
    }

    private var inspector: some View {
        HStack(spacing: 0) {
            Divider()
                .opacity(selectedDevice == nil ? 0 : 1)

            ZStack {
                if let device = displayedDevice {
                    DeviceDetailView(device: device, store: store) {
                        dismissInspector()
                    }
                    .id(device.did)
                    .opacity(selectedDevice == nil ? 0 : 1)
                    .transition(.opacity)
                }
            }
            .frame(width: inspectorWidth)
            .clipped()
            .allowsHitTesting(selectedDevice != nil)
        }
        .frame(width: inspectorWidth + (selectedDevice == nil ? 0 : 1))
        .clipped()
    }

    private func presentInspector(for device: Device) {
        displayedDevice = device
        withAnimation(AppMotion.layout) {
            selectedDevice = device
        }
    }

    private func dismissInspector() {
        withAnimation(AppMotion.layout) {
            selectedDevice = nil
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
