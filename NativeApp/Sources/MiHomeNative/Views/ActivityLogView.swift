import SwiftUI

struct ActivityLogView: View {
    let store: DeviceStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("运行日志")
                        .font(.headline)
                    Text("最近的设备操作")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("清除") { store.clearActivityLogs() }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .disabled(store.activityLogs.isEmpty)
            }

            if store.activityLogs.isEmpty {
                ContentUnavailableView(
                    "暂无记录",
                    systemImage: "list.bullet.rectangle",
                    description: Text("设备操作结果会显示在这里。")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(store.activityLogs) { log in
                            ActivityLogRow(log: log)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(.regularMaterial)
    }
}

private struct ActivityLogRow: View {
    let log: ActivityLog

    private var tint: Color { log.level == .success ? .green : .red }
    private var symbol: String { log.level == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill" }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(log.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Text(log.date, format: .dateTime.hour().minute())
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Text(log.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
