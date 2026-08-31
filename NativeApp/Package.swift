// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MiHomeNative",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "MiHomeNative", targets: ["MiHomeNative"]),
    ],
    targets: [
        .executableTarget(name: "MiHomeNative"),
    ]
)
