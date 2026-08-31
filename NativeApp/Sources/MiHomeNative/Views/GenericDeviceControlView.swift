import SwiftUI

/// Capability-driven controls for every non-specialised MIoT device. The
/// control factory only renders public writable properties and actions returned
/// by the user's own Mi Home account; it never invents unsupported switches.
struct GenericDeviceControlView: View {
    let device: Device
    let detail: DeviceControlDetail
    @Bindable var store: DeviceStore

    @State private var sliderDrafts: [String: Double] = [:]
    @State private var textDrafts: [String: String] = [:]
    @State private var actionDrafts: [String: String] = [:]
    @State private var workbenchIdentifiers: [String]?
    @State private var showingWorkbenchEditor = false

    private var switches: [DeviceProperty] {
        ordered(detail.props.filter { $0.writable && $0.type == "bool" })
    }

    private var selectors: [DeviceProperty] {
        ordered(detail.props.filter { $0.writable && $0.type != "bool" && !($0.valueList ?? []).isEmpty })
    }

    private var sliders: [DeviceProperty] {
        ordered(detail.props.filter {
            $0.writable && ($0.valueList ?? []).isEmpty
                && ["int", "uint", "float"].contains($0.type) && ($0.range?.count ?? 0) == 3
        })
    }

    private var textProperties: [DeviceProperty] {
        ordered(detail.props.filter { $0.writable && $0.type == "string" && ($0.valueList ?? []).isEmpty })
    }

    private var controlledNames: Set<String> {
        Set(switches.map(\.name) + selectors.map(\.name) + sliders.map(\.name) + textProperties.map(\.name))
    }

    private var readings: [DeviceProperty] {
        detail.props.filter { $0.readable && !controlledNames.contains($0.name) }
    }

    private var metricReadings: [DeviceProperty] {
        readings.filter { ["battery-level", "temperature", "relative-humidity", "download-speed", "upload-speed", "connected-device-number", "electric-power"].contains($0.name) }
    }

    private var otherReadings: [DeviceProperty] {
        readings.filter { !metricReadings.contains($0) }
    }

    private var textActions: [DeviceAction] {
        orderedActions(detail.actions.filter { ["execute-text-directive", "play-text", "play-music", "play-radio"].contains($0.name) })
    }

    private var directActions: [DeviceAction] {
        orderedActions(detail.actions.filter { !textActions.contains($0) })
    }

    private var hasControls: Bool {
        !switches.isEmpty || !selectors.isEmpty || !sliders.isEmpty || !textProperties.isEmpty || !detail.actions.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            workbenchHeader
            overview
            controls
            status
        }
        .task(id: detail.did) {
            workbenchIdentifiers = DeviceWorkbenchStore.load(did: detail.did)
        }
        .onChange(of: workbenchIdentifiers) { _, identifiers in
            guard let identifiers else { return }
            DeviceWorkbenchStore.save(identifiers, did: detail.did)
        }
        .sheet(isPresented: $showingWorkbenchEditor) {
            DeviceWorkbenchEditor(
                deviceName: device.name,
                items: workbenchItems,
                selectedIdentifiers: Binding(
                    get: { workbenchIdentifiers ?? workbenchItems.map(\.id) },
                    set: { workbenchIdentifiers = $0 }
                )
            )
        }
    }

    private var workbenchHeader: some View {
        HStack {
            Label("设备控制台", systemImage: "rectangle.3.group")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Button("自定义") { showingWorkbenchEditor = true }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }

    private var workbenchItems: [WorkbenchItem] {
        detail.props.filter(\.writable).map {
            WorkbenchItem(id: propertyID($0), title: $0.displayName, symbol: symbol(for: $0))
        } + detail.actions.map {
            WorkbenchItem(id: actionID($0), title: $0.desc, symbol: "bolt.circle")
        }
    }

    @ViewBuilder
    private var overview: some View {
        if !metricReadings.isEmpty {
            InspectorSection("设备概览") {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(metricReadings) { property in
                        MetricTile(
                            title: property.displayName,
                            value: formattedValue(for: property),
                            symbol: metricSymbol(for: property)
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        if !hasControls {
            ContentUnavailableView {
                Label("暂未发现可控功能", systemImage: "lock.slash")
            } description: {
                Text(device.online ? "米家协议未为这台设备公开可写属性或动作。" : "设备离线；恢复在线后会重新读取可用功能。")
            }
            .frame(maxWidth: .infinity, minHeight: metricReadings.isEmpty ? 220 : 110)
        }

        if !switches.isEmpty {
            InspectorSection("开关") {
                VStack(spacing: 12) {
                    ForEach(switches) { property in
                        InspectorControlRow(property.displayName) {
                            Toggle("", isOn: booleanBinding(for: property))
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .disabled(isDisabled(property))
                        }
                    }
                }
            }
        }

        if !selectors.isEmpty {
            InspectorSection("模式与档位") {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(selectors) { property in
                        selectorControl(property)
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
                                .disabled(isDisabled(property))
                            }
                        }
                    }
                }
            }
        }

        if !textProperties.isEmpty {
            InspectorSection("文本设置") {
                VStack(spacing: 12) {
                    ForEach(textProperties) { property in
                        textControl(property)
                    }
                }
            }
        }

        if !directActions.isEmpty || !textActions.isEmpty {
            InspectorSection("设备功能") {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(directActions) { action in
                        DeviceActionButton(
                            action: action,
                            isPending: store.isCommandPending("\(device.did):action:\(action.name)"),
                            isDisabled: !device.online || store.isCommandPending("\(device.did):action:\(action.name)")
                        ) {
                            Task { await store.runAction(did: device.did, name: action.name) }
                        }
                    }

                    ForEach(textActions) { action in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("输入内容", text: textBinding(for: action))
                                .textFieldStyle(.roundedBorder)
                            DeviceActionButton(
                                action: action,
                                isPending: store.isCommandPending("\(device.did):action:\(action.name)"),
                                isDisabled: !device.online || actionDraft(for: action).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isCommandPending("\(device.did):action:\(action.name)")
                            ) {
                                let text = actionDraft(for: action).trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !text.isEmpty else { return }
                                Task { await store.runAction(did: device.did, name: action.name, params: .string(text)) }
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var status: some View {
        if !otherReadings.isEmpty {
            InspectorSection("状态") {
                VStack(spacing: 10) {
                    ForEach(otherReadings) { property in
                        InspectorControlRow(property.displayName) {
                            Text(formattedValue(for: property))
                                .textSelection(.enabled)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func selectorControl(_ property: DeviceProperty) -> some View {
        if let options = property.valueList, !options.isEmpty, options.count <= 4 {
            VStack(alignment: .leading, spacing: 8) {
                Text(property.displayName)
                HStack(spacing: 7) {
                    ForEach(options) { option in
                        let selected = store.propertyValue(for: device.did, name: property.name) == option.value
                        Button {
                            Task { await store.setProperty(did: device.did, name: property.name, value: option.value) }
                        } label: {
                            Text(option.label)
                                .font(.caption.weight(selected ? .semibold : .regular))
                                .lineLimit(1)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(selected ? .white : .primary)
                        .background(selected ? Color.accentColor : Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .disabled(isDisabled(property))
                    }
                }
            }
        } else {
            InspectorControlRow(property.displayName) {
                Picker("", selection: optionBinding(for: property)) {
                    ForEach(property.valueList ?? []) { option in
                        Text(option.label).tag(option.value)
                    }
                }
                .labelsHidden()
                .frame(width: 160)
                .pickerStyle(.menu)
                .disabled(isDisabled(property))
            }
        }
    }

    private func textControl(_ property: DeviceProperty) -> some View {
        HStack(spacing: 10) {
            Text(property.displayName)
                .lineLimit(1)
            TextField("输入内容", text: textBinding(for: property))
                .textFieldStyle(.roundedBorder)
                .disabled(isDisabled(property))
            Button("保存") {
                Task { await store.setProperty(did: device.did, name: property.name, value: .string(textDraft(for: property))) }
            }
            .buttonStyle(.bordered)
            .disabled(isDisabled(property) || textDraft(for: property).isEmpty)
        }
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

    private func textBinding(for property: DeviceProperty) -> Binding<String> {
        Binding(
            get: { textDrafts[property.name] ?? stringValue(for: property) },
            set: { textDrafts[property.name] = $0 }
        )
    }

    private func textBinding(for action: DeviceAction) -> Binding<String> {
        Binding(
            get: { actionDrafts[action.name] ?? "" },
            set: { actionDrafts[action.name] = $0 }
        )
    }

    private func sliderValue(for property: DeviceProperty, range: [Double]) -> Double {
        sliderDrafts[property.name] ?? store.propertyValue(for: device.did, name: property.name)?.numberValue ?? range[0]
    }

    private func textDraft(for property: DeviceProperty) -> String {
        textDrafts[property.name] ?? stringValue(for: property)
    }

    private func actionDraft(for action: DeviceAction) -> String {
        actionDrafts[action.name] ?? ""
    }

    private func stringValue(for property: DeviceProperty) -> String {
        guard case let .string(value)? = store.propertyValue(for: device.did, name: property.name) else { return "" }
        return value
    }

    private func propertyID(_ property: DeviceProperty) -> String { "property:\(property.name)" }
    private func actionID(_ action: DeviceAction) -> String { "action:\(action.name)" }

    private func ordered(_ properties: [DeviceProperty]) -> [DeviceProperty] {
        let selected = workbenchIdentifiers
        let visible = properties.filter { selected?.contains(propertyID($0)) ?? true }
        return visible.sorted { position(of: propertyID($0), in: selected) < position(of: propertyID($1), in: selected) }
    }

    private func orderedActions(_ actions: [DeviceAction]) -> [DeviceAction] {
        let selected = workbenchIdentifiers
        let visible = actions.filter { selected?.contains(actionID($0)) ?? true }
        return visible.sorted { position(of: actionID($0), in: selected) < position(of: actionID($1), in: selected) }
    }

    private func position(of identifier: String, in selected: [String]?) -> Int {
        selected?.firstIndex(of: identifier) ?? Int.max
    }

    private func symbol(for property: DeviceProperty) -> String {
        switch property.name {
        case "on": "power"
        case "target-temperature", "temperature": "thermometer.medium"
        case "mode": "fan"
        case "fan-level": "wind"
        case "brightness": "sun.max"
        case "battery-level": "battery.75percent"
        default: "slider.horizontal.3"
        }
    }

    private func isDisabled(_ property: DeviceProperty) -> Bool {
        !device.online || store.isCommandPending("\(device.did):\(property.name)")
    }

    private func formattedValue(for property: DeviceProperty) -> String {
        guard let value = store.propertyValue(for: device.did, name: property.name) else { return "—" }
        guard let number = value.numberValue else { return value.displayValue }
        return switch property.name {
        case "battery-level", "relative-humidity": "\(number.formatted(.number.precision(.fractionLength(0))))%"
        case "temperature": "\(number.formatted(.number.precision(.fractionLength(1))))°C"
        case "electric-power": "\(number.formatted(.number.precision(.fractionLength(1)))) W"
        case "download-speed", "upload-speed": byteRate(number)
        case "connected-device-number": "\(number.formatted(.number.precision(.fractionLength(0)))) 台"
        default: value.displayValue
        }
    }

    private func metricSymbol(for property: DeviceProperty) -> String {
        switch property.name {
        case "battery-level": "battery.75percent"
        case "temperature": "thermometer.medium"
        case "relative-humidity": "humidity"
        case "download-speed": "arrow.down.circle"
        case "upload-speed": "arrow.up.circle"
        case "connected-device-number": "network"
        case "electric-power": "bolt.fill"
        default: "chart.bar"
        }
    }

    private func byteRate(_ value: Double) -> String {
        if value >= 1_024 * 1_024 { return "\((value / 1_024 / 1_024).formatted(.number.precision(.fractionLength(1)))) MB/s" }
        if value >= 1_024 { return "\((value / 1_024).formatted(.number.precision(.fractionLength(1)))) KB/s" }
        return "\(value.formatted(.number.precision(.fractionLength(0)))) B/s"
    }
}

private struct MetricTile: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}
