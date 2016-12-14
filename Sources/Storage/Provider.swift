import Vapor

public final class Provider: Vapor.Provider {
    public var provided: Providable
    
    public init(config: Config) throws {
        provided = Providable()
    }
    
    public func afterInit(_ drop: Droplet) {
    }
    
    public func beforeRun(_: Droplet) {
    }
}
