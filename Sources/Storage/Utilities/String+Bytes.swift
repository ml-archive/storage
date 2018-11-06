extension String {
    var bytes: [UInt8] {
        return Array(self.utf8)
    }
}
