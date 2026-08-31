import SwiftUI

enum AppMotion {
    static let theme = Animation.easeInOut(duration: 0.24)
    static let panel = Animation.snappy(duration: 0.28, extraBounce: 0.04)
    static let state = Animation.easeInOut(duration: 0.20)
}
