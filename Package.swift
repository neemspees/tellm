// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "tellm",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "tellm",
            dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser")]
        )
    ]
)
