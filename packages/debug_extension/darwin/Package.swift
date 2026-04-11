// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "RevereDebugExtension",
    platforms: [
        .iOS(.v11),
        .macOS(.v10_11)
    ],
    products: [
        .library(
            name: "RevereDebugExtension",
            targets: ["RevereDebugExtension"]),
    ],
    targets: [
        .target(
            name: "RevereDebugExtension",
            path: ".",
            exclude: [],
            sources: ["RevereDebugExtensionPlugin.swift"]
        )
    ]
)
