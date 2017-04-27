import PackageDescription

let package = Package(
    name: "Storage",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", Version(2,0,0, prereleaseIdentifiers: ["beta"])),
        .Package(url: "https://github.com/nodes-vapor/data-uri.git", Version(1,0,0, prereleaseIdentifiers: ["beta"])),
        .Package(url: "https://github.com/nodes-vapor/aws.git", Version(1,0,0, prereleaseIdentifiers: ["beta"])),
        .Package(url: "https://github.com/manGoweb/MimeLib.git", majorVersion: 1)
    ]
)
