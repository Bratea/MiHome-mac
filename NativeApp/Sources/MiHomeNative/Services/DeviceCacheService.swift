import Foundation

enum DeviceCacheService {
    static var cacheURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appending(path: "Library/Application Support/MiHome-Mac/devices_cache.json")
    }

    static func load() throws -> DeviceCache {
        let data = try Data(contentsOf: cacheURL)
        return try JSONDecoder().decode(DeviceCache.self, from: data)
    }
}
