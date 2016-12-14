public protocol Provider {
    var pathBuilder: UploadPathBuilder { get set }
    
    func upload(entity: UploadEntity) throws -> String
}
