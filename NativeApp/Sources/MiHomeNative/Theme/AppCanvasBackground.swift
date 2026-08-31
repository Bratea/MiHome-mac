import SwiftUI

/// A neutral, wallpaper-aware canvas with no grey or theme-colour overlay.
/// The system material supplies only the requested background blur.
struct AppCanvasBackground: View {
    @AppStorage("backgroundOpacity") private var backgroundOpacity = 0.72
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .opacity(backgroundOpacity)
            .ignoresSafeArea()
    }
}
