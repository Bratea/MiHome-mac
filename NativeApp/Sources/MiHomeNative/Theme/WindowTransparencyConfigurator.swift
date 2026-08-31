import AppKit
import SwiftUI

/// SwiftUI does not expose the window's opaque backing layer. This tiny probe
/// only configures that AppKit edge; SwiftUI continues to own all visual state.
struct WindowTransparencyConfigurator: NSViewRepresentable {
    let enabled: Bool

    func makeNSView(context: Context) -> WindowProbe {
        let probe = WindowProbe()
        probe.isTransparent = enabled
        return probe
    }
    func updateNSView(_ nsView: WindowProbe, context: Context) {
        nsView.isTransparent = enabled
        nsView.applyWindowAppearance(isTransparent: enabled)
    }
}

final class WindowProbe: NSView {
    var isTransparent = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyWindowAppearance(isTransparent: isTransparent)
    }

    func applyWindowAppearance(isTransparent: Bool) {
        guard let window else { return }
        window.isOpaque = !isTransparent
        window.backgroundColor = isTransparent ? .clear : .windowBackgroundColor
        window.titlebarAppearsTransparent = isTransparent
    }
}
