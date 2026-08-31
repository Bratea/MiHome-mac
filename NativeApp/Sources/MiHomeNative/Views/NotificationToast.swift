import SwiftUI

struct NotificationToast: View {
    let notification: AppNotification
    let dismiss: () -> Void

    private var tint: Color {
        notification.level == .success ? .green : .red
    }

    private var symbol: String {
        notification.level == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(tint)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(notification.title)
                    .font(.subheadline.weight(.semibold))
                Text(notification.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 4)
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("关闭通知")
        }
        .padding(14)
        .frame(width: 350, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(tint.opacity(0.24), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.14), radius: 18, y: 8)
        .contentShape(Rectangle())
        .onTapGesture(perform: dismiss)
        .accessibilityElement(children: .combine)
    }
}
