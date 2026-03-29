// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SwiftLogTransportPlugin",
    platforms: [
        .iOS(.v11), .macOS(.v10_13)
    ],
    products: [
        .library(
            name: "SwiftLogTransportPlugin",
            targets: ["SwiftLogTransportPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.0")
    ],
    targets: [
        .target(
            name: "SwiftLogTransportPlugin",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ],
            path: ".",
            sources: ["ios/Classes", "macos/Classes"]
        )
    ]
)
