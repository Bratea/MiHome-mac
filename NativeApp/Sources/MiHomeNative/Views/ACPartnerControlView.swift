import SwiftUI

/// A model-specific control surface for Mi AC Partner 2. The controls below map
/// directly to public MIoT properties; they are not visual stand-ins.
struct ACPartnerControlView: View {
    let device: Device
    let detail: DeviceControlDetail
    @Bindable var store: DeviceStore
    @AppStorage("themeColor") private var themeColor = AppThemeColor.blue.rawValue

    private var tint: Color { AppThemeColor.color(for: themeColor) }

    private var targetTemperature: DeviceProperty? { property("target-temperature") }
    private var mode: DeviceProperty? { property("mode") }
    private var fanLevel: DeviceProperty? { property("fan-level") }
    private var verticalSwing: DeviceProperty? { property("vertical-swing") }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            temperatureHero
            energyInformation
            primaryControls
            modeControls
            sceneControls
            advancedControls
        }
    }

    private var temperatureHero: some View {
        VStack(spacing: 5) {
            Text(temperatureText)
                .font(.system(size: 48, weight: .medium, design: .rounded))
                .monospacedDigit()
            Text(selectedOptionLabel(for: mode) ?? "空调")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var energyInformation: some View {
        if let energy = store.energy(for: device.did) {
            InspectorSection("用电信息") {
                HStack(spacing: 0) {
                    EnergyValue(title: "今日用电", value: kWhText(energy.daily.entries.first?.kilowattHours))
                    Divider().frame(height: 42)
                    EnergyValue(title: "近一月用电", value: kWhText(energy.monthly.entries.first?.kilowattHours))
                    Divider().frame(height: 42)
                    EnergyValue(title: "当前功率", value: powerText)
                }
            }
        } else if store.isLoadingExtras(for: device.did) {
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("正在读取用电信息…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var primaryControls: some View {
        InspectorSection("空调控制") {
            VStack(spacing: 16) {
                InspectorControlRow("开关") {
                    Toggle("", isOn: booleanBinding(for: property("on")))
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .disabled(!device.online || property("on") == nil)
                }

                if let targetTemperature, let range = targetTemperature.range {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("温度调节")
                            Spacer()
                            Text(temperatureText)
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 12) {
                            Button { adjustTemperature(by: -range[2]) } label: {
                                Image(systemName: "minus")
                            }
                            .buttonStyle(.bordered)
                            .disabled(!canAdjustTemperature(by: -range[2]))

                            Slider(
                                value: numberBinding(for: targetTemperature, range: range),
                                in: range[0]...range[1],
                                step: range[2],
                                onEditingChanged: { editing in
                                    guard !editing else { return }
                                    Task {
                                        await store.setProperty(
                                            did: device.did,
                                            name: targetTemperature.name,
                                            value: .number(currentTemperature)
                                        )
                                    }
                                }
                            )
                            .disabled(!device.online)

                            Button { adjustTemperature(by: range[2]) } label: {
                                Image(systemName: "plus")
                            }
                            .buttonStyle(.bordered)
                            .disabled(!canAdjustTemperature(by: range[2]))
                        }
                    }
                }

                if verticalSwing != nil {
                    InspectorControlRow("上下扫风") {
                        Toggle("", isOn: booleanBinding(for: verticalSwing))
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .disabled(!device.online)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var modeControls: some View {
        if let fanLevel, let options = fanLevel.valueList, !options.isEmpty {
            InspectorSection("风速") {
                optionButtons(property: fanLevel, options: options, columns: 4)
            }
        }
        if let mode, let options = mode.valueList, !options.isEmpty {
            InspectorSection("模式") {
                optionButtons(property: mode, options: options, columns: 5)
            }
        }
    }

    @ViewBuilder
    private var sceneControls: some View {
        if !store.smartScenes.isEmpty {
            InspectorSection("智能场景") {
                VStack(spacing: 8) {
                    ForEach(store.smartScenes) { scene in
                        Button {
                            Task { await store.runScene(scene) }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(tint)
                                Text(scene.name)
                                    .lineLimit(1)
                                Spacer()
                                if store.isCommandPending("scene:\(scene.id)") {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var advancedControls: some View {
        let advanced = ["ac-work-mode", "match-state"].compactMap(property)
        if !advanced.isEmpty || property("ac-state") != nil {
            InspectorSection("高级设备设置") {
                VStack(spacing: 12) {
                    ForEach(advanced) { property in
                        if let options = property.valueList, !options.isEmpty {
                            InspectorControlRow(property.displayName) {
                                Picker("", selection: optionBinding(for: property)) {
                                    ForEach(options) { option in
                                        Text(option.label).tag(option.value)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 150)
                                .pickerStyle(.menu)
                                .disabled(!device.online)
                            }
                        }
                    }
                    if let state = store.propertyValue(for: device.did, name: "ac-state")?.displayValue {
                        InspectorControlRow("空调状态") {
                            Text(state)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func optionButtons(property: DeviceProperty, options: [DevicePropertyOption], columns: Int) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns), spacing: 8) {
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
                        .background(selected ? tint.opacity(0.15) : Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                .buttonStyle(.plain)
                .foregroundStyle(selected ? tint : .primary)
                .disabled(!device.online)
            }
        }
    }

    private func property(_ name: String) -> DeviceProperty? {
        detail.props.first(where: { $0.name == name })
    }

    private var currentTemperature: Double {
        store.propertyValue(for: device.did, name: "target-temperature")?.numberValue ?? targetTemperature?.range?.first ?? 16
    }

    private var temperatureText: String { "\(currentTemperature.formatted())°C" }
    private var powerText: String {
        guard let value = store.propertyValue(for: device.did, name: "electric-power")?.numberValue else { return "—" }
        return "\(value.formatted(.number.precision(.fractionLength(1)))) W"
    }

    private func kWhText(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(value.formatted(.number.precision(.fractionLength(1)))) 度"
    }

    private func selectedOptionLabel(for property: DeviceProperty?) -> String? {
        guard let property, let current = store.propertyValue(for: device.did, name: property.name) else { return nil }
        return property.valueList?.first(where: { $0.value == current })?.label
    }

    private func booleanBinding(for property: DeviceProperty?) -> Binding<Bool> {
        Binding(
            get: { guard let property else { return false }; return store.propertyValue(for: device.did, name: property.name)?.boolValue ?? false },
            set: { value in guard let property else { return }; Task { await store.setProperty(did: device.did, name: property.name, value: .bool(value)) } }
        )
    }

    private func numberBinding(for property: DeviceProperty, range: [Double]) -> Binding<Double> {
        Binding(
            get: { currentTemperature },
            set: { value in Task { await store.setProperty(did: device.did, name: property.name, value: .number(value)) } }
        )
    }

    private func optionBinding(for property: DeviceProperty) -> Binding<JSONValue> {
        let fallback = property.valueList?.first?.value ?? .null
        return Binding(
            get: { store.propertyValue(for: device.did, name: property.name) ?? fallback },
            set: { value in Task { await store.setProperty(did: device.did, name: property.name, value: value) } }
        )
    }

    private func adjustTemperature(by delta: Double) {
        guard let property = targetTemperature else { return }
        Task { await store.setProperty(did: device.did, name: property.name, value: .number(currentTemperature + delta)) }
    }

    private func canAdjustTemperature(by delta: Double) -> Bool {
        guard let range = targetTemperature?.range else { return false }
        let result = currentTemperature + delta
        return device.online && result >= range[0] && result <= range[1]
    }
}

private struct EnergyValue: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.headline.weight(.semibold))
                .monospacedDigit()
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
    }
}
