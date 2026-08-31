import SwiftUI

struct DeviceWorkbenchEditor: View {
    let deviceName: String
    let items: [WorkbenchItem]
    @Binding var selectedIdentifiers: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("自定义控制台")
                        .font(.title3.weight(.bold))
                    Text("选择并排序 \(deviceName) 的常用控制项")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(20)

            List {
                if selectedItems.isEmpty {
                    ContentUnavailableView {
                        Label("还没有显示的控制项", systemImage: "rectangle.stack.badge.minus")
                    } description: {
                        Text("勾选下方项目即可把它放回控制台。")
                    }
                    .frame(maxWidth: .infinity, minHeight: 160)
                    .listRowSeparator(.hidden)
                } else {
                    Section("控制台顺序") {
                        ForEach(Array(selectedItems.enumerated()), id: \.element.id) { index, item in
                            HStack(spacing: 8) {
                                row(for: item)
                                Button { move(item, by: -1) } label: {
                                    Image(systemName: "chevron.up")
                                }
                                .buttonStyle(.borderless)
                                .disabled(index == 0)
                                Button { move(item, by: 1) } label: {
                                    Image(systemName: "chevron.down")
                                }
                                .buttonStyle(.borderless)
                                .disabled(index == selectedItems.count - 1)
                            }
                        }
                    }
                }

                let hidden = items.filter { !selectedIdentifiers.contains($0.id) }
                if !hidden.isEmpty {
                    Section("已隐藏") {
                        ForEach(hidden) { item in
                            row(for: item)
                        }
                    }
                }
            }
            .listStyle(.inset)

            Divider()
            HStack {
                Button("恢复默认") {
                    selectedIdentifiers = items.map(\.id)
                }
                Spacer()
                Button("完成") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 430, height: 540)
    }

    private var selectedItems: [WorkbenchItem] {
        selectedIdentifiers.compactMap { identifier in items.first(where: { $0.id == identifier }) }
    }

    private func row(for item: WorkbenchItem) -> some View {
        Toggle(isOn: Binding(
            get: { selectedIdentifiers.contains(item.id) },
            set: { shouldShow in
                if shouldShow {
                    selectedIdentifiers.append(item.id)
                } else {
                    selectedIdentifiers.removeAll { $0 == item.id }
                }
            }
        )) {
            Label(item.title, systemImage: item.symbol)
                .labelStyle(.titleAndIcon)
        }
        .toggleStyle(.checkbox)
    }

    private func move(_ item: WorkbenchItem, by delta: Int) {
        guard let oldIndex = selectedIdentifiers.firstIndex(of: item.id) else { return }
        let newIndex = oldIndex + delta
        guard selectedIdentifiers.indices.contains(newIndex) else { return }
        selectedIdentifiers.swapAt(oldIndex, newIndex)
    }
}

struct WorkbenchItem: Identifiable, Hashable {
    let id: String
    let title: String
    let symbol: String
}
