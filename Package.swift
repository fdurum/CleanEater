// swift-tools-version:5.9
import PackageDescription

// CleanEaterMapKit and CleanEaterApp depend on MapKit/SwiftUI, which only exist on
// Apple platforms. Guarding them here keeps CleanEaterKit (the King County client,
// matcher, and aggregation logic) buildable and testable anywhere `swift test` runs.
#if canImport(Darwin)
let appleOnlyTargets: [Target] = [
    .target(
        name: "CleanEaterMapKit",
        dependencies: ["CleanEaterKit"]
    ),
    .executableTarget(
        name: "CleanEaterApp",
        dependencies: ["CleanEaterKit", "CleanEaterMapKit"]
    ),
]
let appleOnlyProducts: [Product] = [
    .library(name: "CleanEaterMapKit", targets: ["CleanEaterMapKit"]),
    .executable(name: "CleanEaterApp", targets: ["CleanEaterApp"]),
]
#else
let appleOnlyTargets: [Target] = []
let appleOnlyProducts: [Product] = []
#endif

let package = Package(
    name: "CleanEater",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "CleanEaterKit", targets: ["CleanEaterKit"])
    ] + appleOnlyProducts,
    targets: [
        .target(
            name: "CleanEaterKit"
        ),
        .testTarget(
            name: "CleanEaterKitTests",
            dependencies: ["CleanEaterKit"]
        ),
    ] + appleOnlyTargets
)
