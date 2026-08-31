import SwiftUI

/// The standard canvas remains calm grey; the wallpaper-aware material is
/// deliberately reserved for the opt-in Liquid Glass mode.
struct AppCanvasBackground: View {
    @AppStorage("backgroundOpacity") private var backgroundOpacity = 0.72
    @AppStorage("liquidGlassEnabled") private var liquidGlassEnabled = false
    @Environment(\.colorScheme) private var colorScheme

    private var glassOpacity: CGFloat {
        // A fully transparent backing exposes sharp text from other apps. Keep
        // a minimum visual-effect layer so glass always remains genuinely blurred.
        CGFloat(min(max(backgroundOpacity, 0.62), 0.92))
    }

    @ViewBuilder
    var body: some View {
        if liquidGlassEnabled {
            WindowBackdropBlur(opacity: glassOpacity)
                .overlay(.white.opacity(0.025))
                .ignoresSafeArea()
        } else {
            AppThemeColor.canvas(for: colorScheme)
                .ignoresSafeArea()
        }
    }
}
