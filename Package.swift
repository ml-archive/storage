import PackageDescription

let package = Package(
    name: "Storage",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 2),
        .Package(url: "https://github.com/nodes-vapor/data-uri.git", majorVersion: 1),
        .Package(url: "https://github.com/mono0926/aws.git", majorVersion: 1),
        .Package(url: "https://github.com/manGoweb/MimeLib.git", majorVersion: 1)
    ]
)
