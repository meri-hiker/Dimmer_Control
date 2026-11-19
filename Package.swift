// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HalfLight",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "HalfLight", targets: ["HalfLight"]),
        .library(name: "HalfLightCore", targets: ["HalfLightCore"])
    ],
    targets: [
        .target(name: "HalfLightCore"),
        .executableTarget(name: "HalfLight", dependencies: ["HalfLightCore"]),
        .testTarget(name: "HalfLightCoreTests", dependencies: ["HalfLightCore"])
    ]
)
