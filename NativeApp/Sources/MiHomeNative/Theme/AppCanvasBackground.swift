import SwiftUI

/// The standard canvas remains calm grey; the wallpaper-aware material is
/// deliberately reserved for the opt-in Liquid Glass mode.
struct AppCanvasBackground: View {
    @AppStorage("backgroundOpacity") private var backgroundOpacity = 0.72
    @AppStorage("liquidGlassEnabled") private var liquidGlassEnabled = false
    @Environment(\.colorScheme) private var colorScheme

    @ViewBuilder
    var body: some View {
        if liquidGlassEnabled {
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
        } else {
            AppThemeColor.canvas(for: colorScheme)
                .ignoresSafeArea()
        }
    }
}
