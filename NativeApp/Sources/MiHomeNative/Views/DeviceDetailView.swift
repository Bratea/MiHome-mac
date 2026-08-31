import AppKit
import SwiftUI

struct DeviceDetailView: View {
    let device: Device
    @Bindable var store: DeviceStore
    let onClose: () -> Void

    @State private var actionText = ""
    @State private var sliderDrafts: [String: Double] = [:]
    @State private var showingDeviceInformation = false

    private var detail: DeviceControlDetail? { store.controlDetail(for: device.did) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if store.isLoadingControl(for: device.did), detail == nil {
                        ProgressView("正在读取设备功能…")
                            .frame(maxWidth: .infinity, minHeight: 230)
                    } else if let error = store.controlError(for: device.did), detail == nil {
                        ContentUnavailableView {
                            Label("无法读取设备功能", systemImage: "exclamationmark.triangle")
                        } description: {
                            Text(error)
                        } actions: {
                            Button("重试") { Task { await store.loadControls(for: device) } }
                        }
                        .frame(maxWidth: .infinity, minHeight: 230)
                    } else if let detail {
                        controls(for: detail)
                    }
                }
                .padding(18)
            }
            Divider()
            HStack {
                if let error = store.controlError(for: device.did) {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
                Spacer()
                Button("关闭") { onClose() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .frame(minWidth: 390, maxWidth: .infinity, maxHeight: .infinity)
        .task(id: device.did) { await store.loadControls(for: device) }
        .sheet(isPresented: $showingDeviceInformation) {
            DeviceInformationSheet(device: device)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: device.systemImage)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(device.online ? Color.accentColor : Color.secondary)
                .frame(width: 50, height: 50)
                .background(device.online ? Color.accentColor.opacity(0.10) : Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name).font(.title3.weight(.semibold))
                Text(device.roomName == "未知" ? device.homeName : "\(device.homeName) · \(device.roomName)")
                    .foregroundStyle(.secondary)
                Label(device.online ? "在线" : "离线", systemImage: "circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(device.online ? .green : .secondary)
            }
            Spacer()
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(device.did, forType: .string)
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(.borderless)
            .help("复制设备 ID")
        }
        .padding(18)
    }

    @ViewBuilder
    private func controls(for detail: DeviceControlDetail) -> some View {
        let switches = detail.props.filter { $0.writable && $0.type == "bool" }
        let selectors = detail.props.filter { $0.writable && !($0.type == "bool") && !($0.valueList ?? []).isEmpty }
        let sliders = detail.props.filter {
            $0.writable && !($0.type == "bool") && ($0.valueList ?? []).isEmpty
                && ["int", "uint", "float"].contains($0.type) && ($0.range?.count ?? 0) == 3
        }
        let controlledNames = Set(switches.map(\.name) + selectors.map(\.name) + sliders.map(\.name))
        let readings = detail.props.filter { $0.readable && !controlledNames.contains($0.name) }

        if !switches.isEmpty {
            InspectorSection("开关") {
                VStack(spacing: 12) {
                    ForEach(switches) { property in
                        InspectorControlRow(property.displayName) {
                            Toggle("", isOn: booleanBinding(for: property))
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .disabled(!device.online || store.propertyValue(for: device.did, name: property.name)?.boolValue == nil || store.isCommandPending("\(device.did):\(property.name)"))
                        }
                    }
                }
            }
        }

        if !detail.actions.isEmpty {
            InspectorSection("功能") {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(detail.actions) { action in
                        if actionNeedsText(action) {
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("输入内容", text: $actionText)
                                DeviceActionButton(
                                    action: action,
                                    isPending: store.isCommandPending("\(device.did):action:\(action.name)"),
                                    isDisabled: !device.online || actionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isCommandPending("\(device.did):action:\(action.name)")
                                ) {
                                    let text = actionText.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !text.isEmpty else { return }
                                    Task { await store.runAction(did: device.did, name: action.name, params: .string(text)) }
                                }
                            }
                        } else {
                            DeviceActionButton(
                                action: action,
                                isPending: store.isCommandPending("\(device.did):action:\(action.name)"),
                                isDisabled: !device.online || store.isCommandPending("\(device.did):action:\(action.name)")
                            ) {
                                Task { await store.runAction(did: device.did, name: action.name) }
                            }
                        }
                    }
                }
            }
        }

        if !selectors.isEmpty {
            InspectorSection("模式与档位") {
                VStack(spacing: 12) {
                    ForEach(selectors) { property in
                        InspectorControlRow(property.displayName) {
                            Picker("", selection: optionBinding(for: property)) {
                                ForEach(property.valueList ?? []) { option in
                                    Text(option.label).tag(option.value)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 150)
                            .pickerStyle(.menu)
                            .disabled(!device.online || store.propertyValue(for: device.did, name: property.name) == nil || store.isCommandPending("\(device.did):\(property.name)"))
                        }
                    }
                }
            }
        }

        if !sliders.isEmpty {
            InspectorSection("数值控制") {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(sliders) { property in
                        if let range = property.range {
                            VStack(alignment: .leading, spacing: 7) {
                                HStack {
                                    Text(property.displayName)
                                    Spacer()
                                    Text(sliderValue(for: property, range: range).formatted())
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                                Slider(
                                    value: numberBinding(for: property, range: range),
                                    in: range[0]...range[1],
                                    step: range[2],
                                    onEditingChanged: { editing in
                                        guard !editing, let value = sliderDrafts[property.name] else { return }
                                        Task { await store.setProperty(did: device.did, name: property.name, value: .number(value)) }
                                    }
                                )
                                    .disabled(!device.online || store.propertyValue(for: device.did, name: property.name)?.numberValue == nil || store.isCommandPending("\(device.did):\(property.name)"))
                            }
                        }
                    }
                }
            }
        }

        if !readings.isEmpty {
            InspectorSection("状态") {
                VStack(spacing: 10) {
                    ForEach(readings) { property in
                        InspectorControlRow(property.displayName) {
                            Text(store.propertyValue(for: device.did, name: property.name)?.displayValue ?? "—")
                                .textSelection(.enabled)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }

        Button {
            showingDeviceInformation = true
        } label: {
            Label("设备信息", systemImage: "info.circle")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    private func booleanBinding(for property: DeviceProperty) -> Binding<Bool> {
        Binding(
            get: { store.propertyValue(for: device.did, name: property.name)?.boolValue ?? false },
            set: { value in Task { await store.setProperty(did: device.did, name: property.name, value: .bool(value)) } }
        )
    }

    private func optionBinding(for property: DeviceProperty) -> Binding<JSONValue> {
        let fallback = property.valueList?.first?.value ?? .null
        return Binding(
            get: { store.propertyValue(for: device.did, name: property.name) ?? fallback },
            set: { value in Task { await store.setProperty(did: device.did, name: property.name, value: value) } }
        )
    }

    private func numberBinding(for property: DeviceProperty, range: [Double]) -> Binding<Double> {
        Binding(
            get: { sliderValue(for: property, range: range) },
            set: { sliderDrafts[property.name] = $0 }
        )
    }

    private func sliderValue(for property: DeviceProperty, range: [Double]) -> Double {
        sliderDrafts[property.name] ?? store.propertyValue(for: device.did, name: property.name)?.numberValue ?? range[0]
    }

    private func actionNeedsText(_ action: DeviceAction) -> Bool {
        ["execute-text-directive", "play-text", "play-music", "play-radio"].contains(action.name)
    }
}
