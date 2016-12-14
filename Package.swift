import PackageDescription

let package = Package(
    name: "Storage",
    dependencies: [
        .Package(url: "https://github.com/vapor/crypto.git", majorVersion: 1)
    ]
)
