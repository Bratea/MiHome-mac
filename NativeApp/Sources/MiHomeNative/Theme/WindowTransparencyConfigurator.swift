import AppKit
import SwiftUI

/// SwiftUI does not expose the window's opaque backing layer. This tiny probe
/// only configures that AppKit edge; SwiftUI continues to own all visual state.
struct WindowTransparencyConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowProbe { WindowProbe() }
    func updateNSView(_ nsView: WindowProbe, context: Context) {}
}

final class WindowProbe: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { return }
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
    }
}
