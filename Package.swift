import PackageDescription

let package = Package(
    name: "Storage",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1)
    ]
)
