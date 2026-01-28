internal extension Dictionary where Value: Comparable {

    func mode() -> ModeResult? {
        guard let (firstKey, firstValue) = self.first else { return nil }
        var largestCountKey = ModeResult.single(firstKey)
        var largestCountValue = firstValue

        func addKey(_ key: Key) {
            switch largestCountKey {
                case .single(let existingKey):
                    largestCountKey = .multiple([existingKey, key])
                case .multiple(var keys):
                    keys.append(key)
                    largestCountKey = .multiple(keys)
            }
        }

        func replaceKey(_ key: Key) {
            largestCountKey = .single(key)
        }
        
        for (key, value) in self.dropFirst() {
            if value > largestCountValue {
                largestCountValue = value
                replaceKey(key)
            } else if value == largestCountValue {
                addKey(key)
            }
        }

        return largestCountKey
    }

    enum ModeResult {
        case single(Key)
        case multiple([Key])
    }

}
