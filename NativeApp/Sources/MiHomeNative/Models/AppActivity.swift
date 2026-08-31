import Foundation

enum ActivityLevel: String, Sendable {
    case success
    case failure
}

struct ActivityLog: Identifiable, Sendable {
    let id = UUID()
    let date: Date
    let level: ActivityLevel
    let title: String
    let message: String
}

struct AppNotification: Identifiable, Sendable {
    let id = UUID()
    let level: ActivityLevel
    let title: String
    let message: String
}
