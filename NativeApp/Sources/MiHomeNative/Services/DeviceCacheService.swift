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

    static func save(_ cache: DeviceCache) throws {
        let directory = cacheURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(cache)
        try data.write(to: cacheURL, options: .atomic)
    }
}
