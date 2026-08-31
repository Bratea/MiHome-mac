import Foundation

enum DeviceWorkbenchStore {
    private static let prefix = "device-workbench."

    static func load(did: String) -> [String]? {
        guard let data = UserDefaults.standard.data(forKey: prefix + did) else { return nil }
        return try? JSONDecoder().decode([String].self, from: data)
    }

    static func save(_ identifiers: [String], did: String) {
        let data = try? JSONEncoder().encode(identifiers)
        UserDefaults.standard.set(data, forKey: prefix + did)
    }

    static func reset(did: String) {
        UserDefaults.standard.removeObject(forKey: prefix + did)
    }
}
