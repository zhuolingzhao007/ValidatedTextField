// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ValidatedTextField",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "ValidatedTextField",
            targets: ["ValidatedTextField"]
        ),
    ],
    dependencies: [
        // No external dependencies - pure UIKit
    ],
    targets: [
        .target(
            name: "ValidatedTextField",
            dependencies: [
                // No dependencies - pure UIKit
            ],
            path: "Sources/ValidatedTextField"
        ),
    ]
)
