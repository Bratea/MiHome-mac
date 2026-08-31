import AppKit
import SwiftUI

/// The AppKit equivalent of CSS `backdrop-filter: blur(...)`. SwiftUI Material
/// is ideal inside a window, while this view specifically blurs the content
/// behind a transparent NSWindow.
struct WindowBackdropBlur: NSViewRepresentable {
    let opacity: CGFloat

    func makeNSView(context: Context) -> NSVisualEffectView {
        let effectView = NSVisualEffectView()
        effectView.material = .underWindowBackground
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.alphaValue = opacity
        return effectView
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.alphaValue = opacity
    }
}
