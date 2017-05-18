import S3
import Vapor

import enum AWSSignatureV4.Region

///A provider for configuring the `Storage` package.
public final class StorageProvider: Provider {

    public static var repositoryName: String  = "Storage"

    public enum Error: Swift.Error {
        case missingConfigurationFile
        case unsupportedDriver(String)
        case missingAccessKey
        case missingSecretKey
        case missingBucket
        case unknownRegion(String)
    }
    
    public init(config: Config) throws {
        guard let config = config["storage"] else {
            throw Error.missingConfigurationFile
        }
        
        let networkDriver = try buildNetworkDriver(config: config)
        Storage.networkDriver = networkDriver
        Storage.cdnBaseURL = config["cdnUrl"]?.string
    }
    
    public func boot(_ drop: Droplet) {}

    public func boot(_ config: Config) throws {}
    
    public func afterInit(_ drop: Droplet) {}
    
    public func beforeRun(_: Droplet) {}
    
    private func buildNetworkDriver(config: Config) throws -> NetworkDriver {
        let template = config["template"]?.string ?? "/#file"
        let networkDriver: NetworkDriver
        let driver = config["driver"]?.string ?? "s3"
        switch driver {
        case "s3":
            networkDriver = try buildS3Driver(config: config, template: template)
        default:
            throw Error.unsupportedDriver(driver)
        }
        
        return networkDriver
    }
    
    private func buildS3Driver(config: Config, template: String) throws -> S3Driver {
        guard let accessKey = config["accessKey"]?.string else {
            throw Error.missingAccessKey
        }
        
        guard let secretKey = config["secretKey"]?.string else {
            throw Error.missingSecretKey
        }
        
        guard let bucket = config["bucket"]?.string else {
            throw Error.missingBucket
        }
        
        let host = config["host"]?.string ?? "s3.amazonaws.com"
        
        let regionString = config["region"]?.string ?? "eu-west-1"
        guard let region = Region(rawValue: regionString) else {
            throw Error.unknownRegion(regionString)
        }
        
        let s3 = S3(
            host: "\(bucket).\(host)",
            accessKey: accessKey,
            secretKey: secretKey,
            region: region
        )
        
        let pathBuilder = try ConfigurablePathBuilder(template: template)
        return S3Driver(s3: s3, pathBuilder: pathBuilder)
    }
}
