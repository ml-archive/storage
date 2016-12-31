protocol PathBuilder {
    func build(entity: FileEntity) throws -> String
    func generateFolder(for mime: String?) -> String?
}

extension PathBuilder {
    func generateFolder(for mime: String?) -> String? {
        guard let mime = mime else { return nil }
        
        return mime.lowercased().hasPrefix("image") ? "images/original" : "data"
    }
}

struct ConfigurablePathBuilder: PathBuilder {
    var template: Template
    
    init(template: String) throws {
        self.template = try Template.compile(template)
    }
    
    func build(entity: FileEntity) throws -> String {
        return try template.renderPath(for: entity, generateFolder)
    }
}
