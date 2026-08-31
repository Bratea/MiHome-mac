import Foundation

enum MijiaBridgeError: LocalizedError {
    case unavailable
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .unavailable:
            "未找到本地米家协议服务。请确认 Python 服务已安装。"
        case .commandFailed(let message):
            message.isEmpty ? "米家协议服务没有返回有效结果。" : message
        }
    }
}

enum MijiaBridge {
    static func detail(did: String) throws -> DeviceControlDetail {
        try decode(run("detail", "--did", did))
    }

    static func readProperties(did: String, names: [String]) throws -> [String: JSONValue] {
        let namesData = try JSONEncoder().encode(names)
        let namesJSON = String(decoding: namesData, as: UTF8.self)
        return try decode(run("read-props", "--did", did, "--names", namesJSON))
    }

    static func writeProperty(did: String, name: String, value: JSONValue) throws {
        let valueData = try JSONEncoder().encode(value)
        let valueJSON = String(decoding: valueData, as: UTF8.self)
        _ = try run("write-prop", "--did", did, "--name", name, "--value", valueJSON)
    }

    static func runAction(did: String, name: String, params: JSONValue? = nil) throws {
        if let params {
            let paramsData = try JSONEncoder().encode(params)
            let paramsJSON = String(decoding: paramsData, as: UTF8.self)
            _ = try run("run-action", "--did", did, "--name", name, "--params", paramsJSON)
        } else {
            _ = try run("run-action", "--did", did, "--name", name)
        }
    }

    private static func run(_ arguments: String...) throws -> Data {
        guard let command = bridgeCommand() else { throw MijiaBridgeError.unavailable }
        let process = Process()
        process.executableURL = command.executable
        process.arguments = command.leadingArguments + arguments
        process.currentDirectoryURL = command.workingDirectory
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            let message = String(decoding: stderr.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            throw MijiaBridgeError.commandFailed(message)
        }
        return stdout.fileHandleForReading.readDataToEndOfFile()
    }

    private static func decode<Value: Decodable>(_ data: Data) throws -> Value {
        do { return try JSONDecoder().decode(Value.self, from: data) }
        catch { throw MijiaBridgeError.commandFailed("米家协议服务返回的数据无法解析。") }
    }

    private static func bridgeCommand() -> (executable: URL, leadingArguments: [String], workingDirectory: URL)? {
        if let resources = Bundle.main.resourceURL {
            let executable = resources.appending(path: "Protocol/MiHomeProtocol/MiHomeProtocol")
            if FileManager.default.isExecutableFile(atPath: executable.path) {
                return (executable, [], resources)
            }
        }

        if let configuredPython = ProcessInfo.processInfo.environment["MIHOME_PYTHON_PATH"] {
            let python = URL(fileURLWithPath: configuredPython)
            let root = python.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            let script = root.appending(path: "script/native_bridge.py")
            if FileManager.default.isExecutableFile(atPath: python.path), FileManager.default.fileExists(atPath: script.path) {
                return (python, [script.path], root)
            }
        }

        var root = Bundle.main.bundleURL
        for _ in 0..<3 { root.deleteLastPathComponent() }
        let python = root.appending(path: ".venv/bin/python")
        let script = root.appending(path: "script/native_bridge.py")
        guard FileManager.default.isExecutableFile(atPath: python.path), FileManager.default.fileExists(atPath: script.path) else {
            return nil
        }
        return (python, [script.path], root)
    }
}
