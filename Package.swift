// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Storage",
    products: [
        .library(
            name: "Storage",
            targets: ["Storage"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "Storage",
            dependencies: [
                "Vapor"
            ]
        ),
        .testTarget(
            name: "StorageTests",
            dependencies: ["Storage"]
        )
    ]
)
