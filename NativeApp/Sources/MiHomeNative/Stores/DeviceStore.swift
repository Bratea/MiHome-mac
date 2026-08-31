import Foundation
import Observation

@MainActor
@Observable
final class DeviceStore {
    private(set) var devices: [Device] = []
    private(set) var powerStates: [String: Bool?] = [:]
    private(set) var metrics: [String: String] = [:]
    private(set) var lastError: String?
    private(set) var lastLoadedAt: Date?
    private(set) var controlDetails: [String: DeviceControlDetail] = [:]
    private(set) var propertyValues: [String: [String: JSONValue]] = [:]
    private(set) var controlErrors: [String: String] = [:]
    private(set) var loadingControls: Set<String> = []
    private(set) var pendingCommands: Set<String> = []
    private(set) var activityLogs: [ActivityLog] = []
    private(set) var notification: AppNotification?

    var onlineCount: Int { devices.filter(\.online).count }
    var homes: [String] {
        Array(Set(devices.map(\.homeName))).filter { !$0.isEmpty && $0 != "未知" }.sorted()
    }

    init() {
        loadCache()
    }

    func loadCache() {
        do {
            let cache = try DeviceCacheService.load()
            devices = cache.devices.sorted { lhs, rhs in
                if lhs.online != rhs.online { return lhs.online && !rhs.online }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            powerStates = cache.knownPower
            metrics = cache.metrics
            lastLoadedAt = Date()
            lastError = nil
        } catch {
            lastError = "未找到可用的本地设备缓存。请先通过 Python 米家服务同步一次设备。"
        }
    }

    func devices(for home: String, room: String, includeOffline: Bool) -> [Device] {
        devices.filter { device in
            (home == "全部家庭" || device.homeName == home)
                && (room == "全部房间" || device.roomName == room)
                && (includeOffline || device.online)
        }
    }

    func rooms(for home: String) -> [String] {
        Array(Set(devices.filter { home == "全部家庭" || $0.homeName == home }.map(\.roomName)))
            .filter { !$0.isEmpty && $0 != "未知" }
            .sorted()
    }

    func powerState(for device: Device) -> Bool? {
        powerStates[device.did] ?? nil
    }

    func controlDetail(for did: String) -> DeviceControlDetail? { controlDetails[did] }
    func propertyValue(for did: String, name: String) -> JSONValue? { propertyValues[did]?[name] }
    func controlError(for did: String) -> String? { controlErrors[did] }
    func isLoadingControl(for did: String) -> Bool { loadingControls.contains(did) }
    func isCommandPending(_ key: String) -> Bool { pendingCommands.contains(key) }

    func clearActivityLogs() {
        activityLogs.removeAll()
    }

    func dismissNotification(id: UUID) {
        guard notification?.id == id else { return }
        notification = nil
    }

    func loadControls(for device: Device) async {
        guard !loadingControls.contains(device.did) else { return }
        loadingControls.insert(device.did)
        controlErrors[device.did] = nil
        defer { loadingControls.remove(device.did) }

        do {
            let detail = try await Task.detached { try MijiaBridge.detail(did: device.did) }.value
            controlDetails[device.did] = detail
            let readableNames = detail.props.filter(\.readable).map(\.name)
            if !readableNames.isEmpty {
                propertyValues[device.did] = try await Task.detached {
                    try MijiaBridge.readProperties(did: device.did, names: readableNames)
                }.value
            }
        } catch {
            controlErrors[device.did] = error.localizedDescription
            reportFailure(title: "读取设备功能失败", message: error.localizedDescription)
        }
    }

    func setProperty(did: String, name: String, value: JSONValue) async {
        let key = "\(did):\(name)"
        guard !pendingCommands.contains(key) else { return }
        pendingCommands.insert(key)
        controlErrors[did] = nil
        defer { pendingCommands.remove(key) }
        do {
            try await Task.detached { try MijiaBridge.writeProperty(did: did, name: name, value: value) }.value
            propertyValues[did, default: [:]][name] = value
            if name == "on", let state = value.boolValue { powerStates[did] = state }
            reportSuccess(title: "设备状态已更新", message: "\(deviceName(for: did)) · \(name)")
        } catch {
            controlErrors[did] = error.localizedDescription
            reportFailure(title: "更新设备状态失败", message: error.localizedDescription)
        }
    }

    func runAction(did: String, name: String, params: JSONValue? = nil) async {
        let key = "\(did):action:\(name)"
        guard !pendingCommands.contains(key) else { return }
        pendingCommands.insert(key)
        controlErrors[did] = nil
        defer { pendingCommands.remove(key) }
        do {
            try await Task.detached { try MijiaBridge.runAction(did: did, name: name, params: params) }.value
            reportSuccess(title: "动作已发送", message: "\(deviceName(for: did)) · \(name)")
        } catch {
            controlErrors[did] = error.localizedDescription
            reportFailure(title: "执行动作失败", message: error.localizedDescription)
        }
    }

    private func deviceName(for did: String) -> String {
        devices.first(where: { $0.did == did })?.name ?? "设备"
    }

    private func reportSuccess(title: String, message: String) {
        report(level: .success, title: title, message: message)
    }

    private func reportFailure(title: String, message: String) {
        report(level: .failure, title: title, message: message)
    }

    private func report(level: ActivityLevel, title: String, message: String) {
        activityLogs.insert(ActivityLog(date: .now, level: level, title: title, message: message), at: 0)
        activityLogs = Array(activityLogs.prefix(30))
        let newNotification = AppNotification(level: level, title: title, message: message)
        notification = newNotification
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(5))
            self?.dismissNotification(id: newNotification.id)
        }
    }
}
