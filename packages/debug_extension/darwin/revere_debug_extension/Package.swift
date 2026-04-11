// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "revere_debug_extension",
    platforms: [
        .iOS("12.0"),
        .macOS("10.14"),
    ],
    products: [
        .library(name: "revere-debug-extension", targets: ["revere_debug_extension"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "revere_debug_extension",
            dependencies: [
            ]
        ),
    ]
)
