class Trie<KeyPath: BidirectionalCollection, ValueType>
    where KeyPath.Iterator.Element: Equatable, KeyPath.Index == Int {
    typealias Key = KeyPath.Iterator.Element
    typealias Node = Trie<KeyPath, ValueType>
    
    var key: Key
    var value: ValueType?
    var children: [Node] = []
    
    var isLeaf: Bool {
        return children.count == 0
    }
    
    init(key: Key, value: ValueType? = nil) {
        self.key = key
        self.value = value
    }
}

extension Trie {
    func insert(_ keypath: KeyPath, value: ValueType) {
        insert(value: value, for: keypath)
    }
    
    func insert(value: ValueType, for keypath: KeyPath) {
        var current = self
        
        for (index, key) in keypath.enumerated() {
            guard let next = current[key] else {
                let next = Node(key: key)
                current[key] = next
                current = next
                
                if index == keypath.endIndex - 1 {
                    next.value = value
                }
                
                continue
            }
            
            if index == keypath.endIndex - 1 && next.value == nil {
                next.value = value
            }
            
            current = next
        }
    }
    
    func contains(_ keypath: KeyPath) -> ValueType? {
        var current = self
        
        for key in keypath {
            guard let next = current[key] else { return nil }
            current = next
        }
        
        return current.value
    }
}

extension Trie {
    subscript(key: Key) -> Node? {
        get { return children.first(where: { $0.key == key }) }
        set {
            guard let index = children.index(where: { $0.key == key }) else {
                guard let newValue = newValue else { return }
                children.append(newValue)
                return
            }
            
            guard let newValue = newValue else {
                children.remove(at: index)
                return
            }
            
            let child = children[index]
            if child.value == nil {
                child.value = newValue.value
            } else {
                print("warning: inserted duplicate tokens into Trie")
            }
        }
    }
}
