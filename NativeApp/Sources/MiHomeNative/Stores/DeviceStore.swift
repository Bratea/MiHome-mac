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
    private(set) var energyStatistics: [String: (daily: EnergyStatistics, monthly: EnergyStatistics)] = [:]
    private(set) var smartScenes: [SmartScene] = []
    private(set) var isLoadingExtras: Set<String> = []
    private(set) var isSyncing = false
    private(set) var isAuthenticating = false
    private(set) var accountAvailable = false
    private(set) var qrLoginURL: String?
    private(set) var isCheckingAccount = true

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
    func energy(for did: String) -> (daily: EnergyStatistics, monthly: EnergyStatistics)? { energyStatistics[did] }
    func isLoadingExtras(for did: String) -> Bool { isLoadingExtras.contains(did) }

    func clearActivityLogs() {
        activityLogs.removeAll()
    }

    func dismissNotification(id: UUID) {
        guard notification?.id == id else { return }
        notification = nil
    }

    func refreshAccountStatus() async {
        do {
            accountAvailable = try await Task.detached { try MijiaBridge.loginStatus().available }.value
        } catch {
            accountAvailable = false
        }
    }

    func initializeAccount() async {
        isCheckingAccount = true
        await refreshAccountStatus()
        isCheckingAccount = false
    }

    func syncFromCloud() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let cache = try await Task.detached { try MijiaBridge.syncDevices() }.value
            try DeviceCacheService.save(cache)
            apply(cache)
            accountAvailable = true
            reportSuccess(title: "设备已同步", message: "已更新 \(cache.devices.count) 台设备与在线状态")
        } catch {
            reportFailure(title: "同步设备失败", message: error.localizedDescription)
        }
    }

    func startQRCodeLogin() async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        qrLoginURL = nil
        defer { isAuthenticating = false }
        do {
            let session = try await Task.detached { try MijiaBridge.beginQRCodeLogin() }.value
            guard session.requiresScan, let loginURL = session.loginURL, let payload = session.payload else {
                accountAvailable = true
                await syncFromCloud()
                reportSuccess(title: "米家账户已连接", message: "本地凭据仍然有效")
                return
            }
            qrLoginURL = loginURL
            try await Task.detached { try MijiaBridge.completeQRCodeLogin(payload: payload) }.value
            accountAvailable = true
            await syncFromCloud()
            reportSuccess(title: "扫码登录成功", message: "账户凭据已安全保存在本机")
        } catch {
            reportFailure(title: "扫码登录失败", message: error.localizedDescription)
        }
    }

    func clearQRCodeLogin() {
        qrLoginURL = nil
    }

    func logout() async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }
        do {
            try await Task.detached { try MijiaBridge.logout() }.value
            try DeviceCacheService.clear()
            devices = []
            powerStates = [:]
            metrics = [:]
            controlDetails = [:]
            propertyValues = [:]
            energyStatistics = [:]
            smartScenes = []
            accountAvailable = false
            qrLoginURL = nil
            lastLoadedAt = nil
            lastError = nil
            reportSuccess(title: "已退出登录", message: "本机米家凭据和设备缓存已移除")
        } catch {
            reportFailure(title: "退出登录失败", message: error.localizedDescription)
        }
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
            if device.model == "lumi.acpartner.mcn02" {
                await loadACPartnerExtras(for: device)
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

    func loadACPartnerExtras(for device: Device) async {
        guard !isLoadingExtras.contains(device.did) else { return }
        isLoadingExtras.insert(device.did)
        defer { isLoadingExtras.remove(device.did) }

        do {
            async let daily = Task.detached {
                try MijiaBridge.statistics(did: device.did, key: "powerCost", dataType: "stat_day", limit: 7, days: 8)
            }.value
            async let monthly = Task.detached {
                try MijiaBridge.statistics(did: device.did, key: "powerCost", dataType: "stat_month", limit: 6, days: 190)
            }.value
            energyStatistics[device.did] = try await (daily: daily, monthly: monthly)
        } catch {
            reportFailure(title: "读取用电信息失败", message: error.localizedDescription)
        }

        do {
            smartScenes = try await Task.detached { try MijiaBridge.scenes() }.value
        } catch {
            reportFailure(title: "读取智能场景失败", message: error.localizedDescription)
        }
    }

    func runScene(_ scene: SmartScene) async {
        let key = "scene:\(scene.id)"
        guard !pendingCommands.contains(key) else { return }
        pendingCommands.insert(key)
        defer { pendingCommands.remove(key) }
        do {
            try await Task.detached { try MijiaBridge.runScene(id: scene.id, homeID: scene.homeID) }.value
            reportSuccess(title: "场景已执行", message: scene.name)
        } catch {
            reportFailure(title: "执行场景失败", message: error.localizedDescription)
        }
    }

    private func deviceName(for did: String) -> String {
        devices.first(where: { $0.did == did })?.name ?? "设备"
    }

    private func apply(_ cache: DeviceCache) {
        devices = cache.devices.sorted { lhs, rhs in
            if lhs.online != rhs.online { return lhs.online && !rhs.online }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
        powerStates = cache.knownPower
        metrics = cache.metrics
        lastLoadedAt = .now
        lastError = nil
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
