// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HTTP",
    products: [
        .library(
            name: "HTTP",
            targets: ["HTTP"])
    ],
    dependencies: [
        .package(url: "https://github.com/mxcl/PromiseKit.git", from: "6.2.5")
    ],
    targets: [
        .target(
            name: "HTTP",
            dependencies: ["PromiseKit"]),
        .testTarget(
            name: "HTTPTests",
            dependencies: ["HTTP"])
    ]
)
