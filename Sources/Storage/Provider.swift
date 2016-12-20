import S3
import Vapor
import S3SignerAWS

///A provider for configuring the `Storage` package.
public final class Provider: Vapor.Provider {
    public enum Error: Swift.Error {
        case missingConfigurationFile
        case unsupportedDriver(String)
        case missingAccessKey
        case missingSecretKey
        case unknownRegion(String)
    }
    
    public var provided: Providable {
        return Providable()
    }
    
    public init(config: Config) throws {
        guard let config = config["storage"] else {
            throw Error.missingConfigurationFile
        }
        
        let networkDriver = try buildNetworkDriver(config: config)
        Storage.networkDriver = networkDriver
    }
    
    public func boot(_ drop: Droplet) {}
    
    public func afterInit(_ drop: Droplet) {}
    
    public func beforeRun(_: Droplet) {}
    
    private func buildNetworkDriver(config: Config) throws -> NetworkDriver {
        let template = config["template"]?.string ?? "$folder/$file"
        let networkDriver: NetworkDriver
        let driver = config["driver"]?.string ?? "aws"
        switch driver {
        case "aws":
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
        
        let bucket = config["bucket"]?.string
        
        let regionString = config["region"]?.string ?? "eu-west-1"
        guard let region = Region(rawValue: regionString) else {
            throw Error.unknownRegion(regionString)
        }
        
        let s3 = S3(
            accessKey: accessKey,
            secretKey: secretKey,
            bucketName: bucket,
            region: region
        )
        
        let pathBuilder = try ConfigurablePathBuilder(template: template)
        return S3Driver(s3: s3, pathBuilder: pathBuilder)
    }
}
