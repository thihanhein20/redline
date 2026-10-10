// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Redline",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Redline",
            dependencies: ["HIDSensors"]
        ),
        // C wrapper around the private IOHIDEventSystem API used for temperatures.
        .target(
            name: "HIDSensors",
            linkerSettings: [.linkedFramework("IOKit")]
        ),
        .testTarget(
            name: "RedlineTests",
            dependencies: ["Redline"]
        ),
    ]
)
