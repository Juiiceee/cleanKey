// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CleanKey",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "CleanKey", targets: ["CleanKey"])
    ],
    targets: [
        .target(
            name: "CleanKeyCore"
        ),
        .executableTarget(
            name: "CleanKey",
            dependencies: ["CleanKeyCore"],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "CleanKeyCoreTests",
            dependencies: ["CleanKeyCore"]
        )
    ]
)
