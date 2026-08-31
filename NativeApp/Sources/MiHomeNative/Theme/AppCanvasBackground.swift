import SwiftUI

/// The app's quiet, translucent canvas. Material provides the texture while
/// the user's opacity setting preserves enough contrast for device controls.
struct AppCanvasBackground: View {
    @AppStorage("backgroundOpacity") private var backgroundOpacity = 0.72
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Rectangle()
            .fill(.regularMaterial)
            .overlay {
                LinearGradient(
                    colors: [
                        AppThemeColor.canvas(for: colorScheme).opacity(backgroundOpacity),
                        AppThemeColor.canvas(for: colorScheme).opacity(backgroundOpacity * 0.82)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .ignoresSafeArea()
    }
}
