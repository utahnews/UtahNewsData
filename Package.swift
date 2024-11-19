// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UtahNewsData",
    platforms: [
        .iOS("17.0"),
        .macOS("14.0"),
        .tvOS("17.0"),
        .watchOS("10.0")
    ],
    products: [
        .library(
            name: "UtahNewsData",
            targets: ["UtahNewsData"]),
    ],
    targets: [
        .target(
            name: "UtahNewsData",
            dependencies: []),
    ]
)
