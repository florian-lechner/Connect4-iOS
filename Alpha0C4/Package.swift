// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Alpha0C4",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Alpha0C4",
            targets: ["Alpha0C4"]),
    ],
    targets: [
        .binaryTarget(name: "Alpha0C4", path: "./Sources/Alpha0C4.xcframework"),
    ]
)
