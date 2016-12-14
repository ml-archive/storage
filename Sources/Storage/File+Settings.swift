public protocol UploadPathBuilder {
    func build() -> String
    func generateFolder(for mime: String?) -> String
}

extension UploadPathBuilder {
    func generateFolder(for mime: String?) -> String? {
        guard let mime = mime else { return nil }
        
        return mime.lowercased().hasPrefix("image") ? "images/original" : "data"
    }
}
