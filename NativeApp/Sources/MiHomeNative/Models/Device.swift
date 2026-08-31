import Foundation

struct Device: Identifiable, Codable, Hashable, Sendable {
    let did: String
    var name: String
    let model: String
    let homeName: String
    let roomName: String
    var online: Bool

    var id: String { did }

    enum CodingKeys: String, CodingKey {
        case did, name, model, online
        case homeName = "home_name"
        case roomName = "room_name"
    }

    var systemImage: String {
        let identifier = model.lowercased()
        if identifier.contains("acpartner") || identifier.contains("aircondition") { return "air.conditioner.horizontal" }
        if identifier.contains("light") { return "lightbulb" }
        if identifier.contains("router") { return "wifi.router" }
        if identifier.contains("sensor") || identifier.contains("ht") { return "thermometer.medium" }
        if identifier.contains("watch") { return "applewatch" }
        if identifier.contains("speaker") { return "hifispeaker" }
        return "square.grid.2x2"
    }
}

struct DeviceCache: Codable, Sendable {
    let version: Int
    let devices: [Device]
    let knownPower: [String: Bool?]
    let metrics: [String: String]

    enum CodingKeys: String, CodingKey {
        case version, devices, metrics
        case knownPower = "known_power"
    }
}

struct QRLoginSession: Codable, Sendable {
    let requiresScan: Bool
    let loginURL: String?
    let payload: String?

    enum CodingKeys: String, CodingKey {
        case requiresScan = "requires_scan"
        case loginURL = "login_url"
        case payload
    }
}

struct LoginStatus: Codable, Sendable {
    let available: Bool
}

struct DeviceControlDetail: Codable, Sendable {
    let did: String
    let name: String
    let model: String
    let props: [DeviceProperty]
    let actions: [DeviceAction]
}

struct DeviceProperty: Codable, Identifiable, Hashable, Sendable {
    let name: String
    let desc: String
    let type: String
    let readable: Bool
    let writable: Bool
    let range: [Double]?
    let valueList: [DevicePropertyOption]?

    var id: String { name }

    /// MIoT descriptors commonly contain an English / Chinese pair. The inspector
    /// intentionally uses the concise Chinese label so narrow macOS columns stay legible.
    var displayName: String {
        let labels = desc.split(separator: "/", maxSplits: 1).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let last = labels.last else { return desc }
        let label = String(last)
        return label.isEmpty ? desc : label
    }

    enum CodingKeys: String, CodingKey {
        case name, desc, type, readable, writable, range
        case valueList = "value_list"
    }
}

struct DevicePropertyOption: Codable, Identifiable, Hashable, Sendable {
    let value: JSONValue
    let description: String
    let chineseDescription: String?

    var id: JSONValue { value }
    var label: String { chineseDescription ?? description }

    enum CodingKeys: String, CodingKey {
        case value, description
        case chineseDescription = "desc_zh_cn"
    }
}

struct DeviceAction: Codable, Identifiable, Hashable, Sendable {
    let name: String
    let desc: String

    var id: String { name }
}

struct EnergyStatistics: Codable, Sendable {
    let entries: [EnergyStatistic]
}

struct EnergyStatistic: Codable, Identifiable, Hashable, Sendable {
    let timestamp: Int
    let value: Double?

    var id: Int { timestamp }
    var kilowattHours: Double? { value.map { $0 / 1_000 } }
}

struct SmartScene: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let homeID: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case homeID = "home_id"
    }
}

enum JSONValue: Codable, Hashable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(Bool.self) { self = .bool(value) }
        else if let value = try? container.decode(Double.self) { self = .number(value) }
        else { self = .string(try container.decode(String.self)) }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    var numberValue: Double? {
        if case .number(let value) = self { return value }
        return nil
    }

    var displayValue: String {
        switch self {
        case .string(let value): value
        case .number(let value): value.formatted()
        case .bool(let value): value ? "开启" : "关闭"
        case .null: "—"
        }
    }
}
