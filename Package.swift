// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Redline",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Redline", targets: ["Redline"]),
        // Injected into the game process to count frames.
        .library(name: "RedlineHook", type: .dynamic, targets: ["RedlineHook"]),
    ],
    targets: [
        .executableTarget(
            name: "Redline",
            dependencies: ["HIDSensors", "FrameCounter"]
        ),
        // C wrapper around the private IOHIDEventSystem API used for temperatures.
        .target(
            name: "HIDSensors",
            linkerSettings: [.linkedFramework("IOKit")]
        ),
        // Shared-memory frame counter: written by the hook, read by Redline.
        .target(name: "FrameCounter"),
        .target(
            name: "RedlineHook",
            dependencies: ["FrameCounter"],
            publicHeadersPath: ".",
            linkerSettings: [.linkedFramework("QuartzCore")]
        ),
        .testTarget(
            name: "RedlineTests",
            dependencies: ["Redline"]
        ),
    ]
)
