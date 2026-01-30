internal extension Dictionary {

    mutating func removeValues<E: Error>(
        where filter: (_ value: Value) throws(E) -> Bool
    ) throws(E) {
        for (k, v) in self {
            if try filter(v) {
                self.removeValue(forKey: k)   
            }
        }
    }

}
