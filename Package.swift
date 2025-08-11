// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UtahNewsData",
    platforms: [
        .iOS("18.0"),
        .macOS("15.0"),
        .tvOS("18.0"),
        .watchOS("11.0"),
    ],
    products: [
        .library(
            name: "UtahNewsData",
            targets: ["UtahNewsData"]),
        .library(
            name: "UtahNewsDataModels",
            targets: ["UtahNewsDataModels"]),
        .executable(
            name: "ImportSources",
            targets: ["ImportSources"]),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.0")
    ],
    targets: [
        .target(
            name: "UtahNewsDataModels",
            dependencies: [],
            path: "Sources/UtahNewsDataModels",
            exclude: [],
            resources: [
                // No runtime resources – pure Swift structs.
            ],
            swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]
        ),
        .target(
            name: "UtahNewsData",
            dependencies: ["UtahNewsDataModels", "SwiftSoup"],
            path: "Sources/UtahNewsData",
            resources: [
                .copy("Resources/sourcesUpdated.json")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]),
        .executableTarget(
            name: "ImportSources",
            dependencies: ["UtahNewsData"],
            path: "Sources/ImportSources",
            sources: [
                "ImportSources.swift", "SourcesJSONConverter.swift", "DemoConvertedSources.swift",
            ]),
        .testTarget(
            name: "UtahNewsDataModelsTests",
            dependencies: ["UtahNewsDataModels"],
            path: "Tests/UtahNewsDataModelsTests",
            swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]
        ),
        .testTarget(
            name: "UtahNewsDataTests",
            dependencies: ["UtahNewsData", "UtahNewsDataModels"],
            path: "Tests/UtahNewsDataTests",
            swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]
        ),
    ]
)
