// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "swift_log_transport",
    platforms: [
        .iOS(.v11), .macOS(.v10_13)
    ],
    products: [
        .library(
            name: "swift_log_transport",
            targets: ["swift_log_transport"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.0")
    ],
    targets: [
        .target(
            name: "swift_log_transport",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ],
            path: "darwin"
        )
    ]
)
