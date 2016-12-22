import PackageDescription

let package = Package(
    name: "Storage",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1),
        .Package(url: "https://github.com/manGoweb/S3.git", majorVersion: 1),
        .Package(url: "https://github.com/nodes-vapor/DataURI.git", majorVersion: 0)
    ]
)
