// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UtahNewsData",
    platforms: [
        .iOS("17.0"),
        .macOS("14.0"),
        .tvOS("17.0"),
        .watchOS("10.0"),
    ],
    products: [
        .library(
            name: "UtahNewsData",
            targets: ["UtahNewsData"]),
        .executable(
            name: "ImportSources",
            targets: ["ImportSources"]),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.0")
    ],
    targets: [
        .target(
            name: "UtahNewsData",
            dependencies: ["SwiftSoup"],
            resources: [
                .copy("Resources/sourcesUpdated.json")
            ]),
        .executableTarget(
            name: "ImportSources",
            dependencies: ["UtahNewsData"],
            path: "Sources/ImportSources",
            sources: [
                "ImportSources.swift", "SourcesJSONConverter.swift", "DemoConvertedSources.swift",
            ]),
        .testTarget(
            name: "UtahNewsDataTests",
            dependencies: ["UtahNewsData"]),
    ]
)
