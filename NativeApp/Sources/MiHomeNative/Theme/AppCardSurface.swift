import SwiftUI

/// A shared card treatment. Glass stays opt-in so device controls retain their
/// calm, high-contrast default appearance.
struct AppCardSurface: ViewModifier {
    let cornerRadius: CGFloat
    @AppStorage("liquidGlassEnabled") private var liquidGlassEnabled = false
    @Environment(\.colorScheme) private var colorScheme

    @ViewBuilder
    func body(content: Content) -> some View {
        if liquidGlassEnabled, #available(macOS 26.0, *) {
            content
                .background(AppThemeColor.card(for: colorScheme).opacity(0.16), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
        } else {
            content
                .background(AppThemeColor.card(for: colorScheme), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}

extension View {
    func appCardSurface(cornerRadius: CGFloat) -> some View {
        modifier(AppCardSurface(cornerRadius: cornerRadius))
    }
}
