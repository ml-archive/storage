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
    func insert(into trie: Trie<Alias>, _ alias: Template.Alias) {
        trie.insert(alias, for: alias.rawValue.bytes)
    }
}

extension Template {
    mutating func extractAlias() throws -> PathPart {
        var partial: [Byte] = []
        
        var peeked = 0
        defer { scanner.pop(peeked) }
        
        let trie = Trie<Alias>()
        insert(into: trie, Alias.file)
        insert(into: trie, Alias.fileName)
        insert(into: trie, Alias.fileExtension)
        insert(into: trie, Alias.folder)
        insert(into: trie, Alias.mimeFolder)
        
        var current = trie
        
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
