public protocol PathBuilder {
    func build(entity: FileEntity) throws -> String
    func generateFolder(for mime: String?) -> String?
}

extension PathBuilder {
    public func generateFolder(for mime: String?) -> String? {
        guard let mime = mime else { return nil }
        
        return mime.lowercased().hasPrefix("image") ? "images/original" : "data"
    }
}

public final class ConfigurablePathBuilder: PathBuilder {
    var template: Template
    
    public init(template: String) throws {
        self.template = try Template.compile(template)
    }
    
    public func build(entity: FileEntity) throws -> String {
        return try template.renderPath(entity: entity)
    }
}
