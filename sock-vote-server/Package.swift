// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SockVoteServer",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .executable(
            name: "SockVoteServer",
            targets: ["SockVoteServer"]
        ),
    ], 
    dependencies: [

        // Utility
        .package(url: "https://github.com/apple/swift-log", from: "1.6.0"),
        .package(url: "https://github.com/apple/swift-http-types.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-configuration", from: "1.0.0"),

        // Server-related
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.0.0"),
        .package(url: "https://github.com/hummingbird-project/swift-openapi-hummingbird", from: "2.0.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird", from: "2.0.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-websocket", from: "2.0.0"),

        // Plugins
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.0.0"),

    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "SockVoteServer",
            dependencies: [
                .target(name: "RoomHandling"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIHummingbird", package: "swift-openapi-hummingbird"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "Configuration", package: "swift-configuration"),
            ],
        ),
        .target(
            name: "RoomHandling",
            dependencies: [
                .target(name: "VoteHandling"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdWebSocket", package: "hummingbird-websocket"),
            ]
        ),
        .target(
            name: "VoteHandling",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
            ]
        ),

        // MARK: Tests
        .testTarget(
            name: "RoomHandlingTests",
            dependencies: [
                .target(name: "RoomHandling"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
            ]
        ),
        .testTarget(
            name: "ServerTests",
            dependencies: [
                .target(name: "SockVoteServer"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdTesting", package: "hummingbird"),
            ]
        ),
        .testTarget(
            name: "VoteHandlingTests",
            dependencies: [
                .target(name: "VoteHandling")
            ]
        ),

    ],
    swiftLanguageModes: [
        .v6, .v5,
    ]
)

// MARK: - Code Generation

//! FIXME: Workaround for YAMS bug on windows. Using the package plugin is preferrable.
//? The package plugin works on other platforms, it just doesn't work on windows.
//? Windows also currently fails to build due to swift-nio.
// This tries to work around the fact that the OpenAPI generator doesn't work properly on windows
#if !os(windows)
let roomHandlingTarget = package.targets.first { $0.name == "RoomHandling" }!
roomHandlingTarget.plugins = (roomHandlingTarget.plugins ?? []) + [
    .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator"),
]
roomHandlingTarget.exclude += [
    "GeneratedSources/Server.swift",
    "GeneratedSources/Types.swift",
]
#endif

// MARK: - Swift Settings

let swiftSettings: [SwiftSetting] = [
    .defaultIsolation(nil),
    .strictMemorySafety(),
]

let upcomingFeatures: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
]

for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) 
        + swiftSettings 
        + upcomingFeatures
}
