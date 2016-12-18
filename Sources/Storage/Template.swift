import Core

extension Byte {
    static var dollarSign: Byte {
        return "$".bytes[0]
    }
}

struct Template {
    enum Error: Swift.Error {
        case invalidAlias(String)
    }
    
    enum Alias: String {
        case file           = "$file"
        case fileName       = "$fileName"
        case fileExtension  = "$fileExtension"
        case folder         = "$folder"
        case mimeFolder     = "$mimeFolder"
    }
    
    enum PathPart {
        case literal(Bytes)
        case alias(Alias)
    }
    
    var scanner: Scanner<Byte>
    var parts: [PathPart] = []
    
    init(scanner: Scanner<Byte>) {
        self.scanner = scanner
    }
}

extension Template {
    static func compile(_ templateString: String) throws -> Template {
        var template = Template(scanner: Scanner(templateString.bytes))
        
        while let part = try template.extractPart() {
            template.parts.append(part)
        }
        
        return template
    }
    
    func renderPath(entity: FileEntity) throws -> String {
        enum Error: Swift.Error {
            case fileNameNotProvided
            case fileExtensionNotProvided
            case folderNotProvided
            case mimeFolderNotProvided
        }
        
        var pathBytes: [Byte] = []
        
        for part in parts {
            switch part {
            case .literal(let bytes):
                pathBytes += bytes
            case .alias(let alias):
                switch alias {
                case .file:
                    guard let fileName = entity.fileName else {
                        throw Error.fileNameNotProvided
                    }
                    guard let fileExtension = entity.fileExtension else {
                        throw Error.fileExtensionNotProvided
                    }
                    
                    pathBytes += "\(fileName).\(fileExtension)".bytes
                    
                case .fileName:
                    guard let fileName = entity.fileName else {
                        throw Error.fileNameNotProvided
                    }
                    pathBytes += fileName.bytes
                    
                case .fileExtension:
                    guard let fileExtension = entity.fileExtension else {
                        throw Error.fileExtensionNotProvided
                    }
                    pathBytes += fileExtension.bytes
                    
                case .folder:
                    guard let folder = entity.folder else {
                        throw Error.folderNotProvided
                    }
                    pathBytes += folder.bytes
                    
                
                //TODO: looks like template needs a way to correctly generate
                //the mime folder
                case .mimeFolder:
                    guard let mimeFolder = entity.mime else {
                        throw Error.mimeFolderNotProvided
                    }
                    pathBytes += mimeFolder.bytes
                }
            }
        }
        
        return try String(bytes: pathBytes)
    }
}

extension Template {
    mutating func extractPart() throws -> PathPart? {
        guard let byte = scanner.peek() else { return nil }
        
        if byte == Byte.dollarSign {
            return try extractAlias()
        } else {
            return extractLiteral()
        }
    }
}

extension Template {
    //convenience for adding aliases to trie
    static func insert(into trie: Trie<Alias>, _ alias: Template.Alias) {
        trie.insert(alias, for: alias.rawValue.bytes)
    }
}

extension Template {
    static let trie: Trie<Alias> = {
        let _trie = Trie<Alias>()
        insert(into: _trie, Alias.file)
        insert(into: _trie, Alias.fileName)
        insert(into: _trie, Alias.fileExtension)
        insert(into: _trie, Alias.folder)
        insert(into: _trie, Alias.mimeFolder)
        return _trie
    }()
    
    mutating func extractAlias() throws -> PathPart {
        var partial: [Byte] = []
        
        var peeked = 0
        defer { scanner.pop(peeked) }
        
        var current = Template.trie
        
        while let byte = scanner.peek(aheadBy: peeked) {
            peeked += 1
            
            guard let next = current[byte] else { break }
            
            if let value = next.value {
                if let nextByte = scanner.peek(aheadBy: peeked) {
                    guard next[nextByte] != nil else {
                        return .alias(value)
                    }
                    partial += byte
                    current = next
                    continue
                }
                
                return .alias(value)
            }
            
            partial += byte
            current = next
        }

        let invalidAlias = try String(bytes: partial)
        throw Error.invalidAlias(invalidAlias)
    }
    
    mutating func extractLiteral() -> PathPart {
        var partial: [Byte] = []
        var peeked = 0
        defer { scanner.pop(peeked) }
        
        while
            let byte = scanner.peek(aheadBy: peeked),
            byte != Byte.dollarSign
        {
            peeked += 1
            partial += byte
        }
        
        return .literal(partial)
    }
}
