import Bits

/// Converts `[String: URLEncodedFormData]` structs to `Data`.
final class URLEncodedFormSerializer {
    /// Default form url encoded serializer.
    static let `default` = URLEncodedFormSerializer(sortedKeys: false)
    
    /// Produce JSON with dictionary keys sorted in lexicographic order.
    private var sortedKeys: Bool

    /// Create a new form-urlencoded data serializer.
    init(sortedKeys: Bool) {
        self.sortedKeys = sortedKeys
    }

    /// Serializes the data.
    func serialize(_ URLEncodedFormEncoded: [String: URLEncodedFormData]) throws -> Data {
        var data: [Data] = []
        var elements: [(key: String, value: URLEncodedFormData)]!

        if self.sortedKeys {
            elements = URLEncodedFormEncoded.sorted { (left, right) -> Bool in
                return left.key.compare(right.key, options: [.numeric, .caseInsensitive, .forcedOrdering]) == .orderedAscending
            }
        } else {
            elements = URLEncodedFormEncoded.map { $0 }
        }

        for (key, val) in elements {
            let key = try key.urlEncodedFormEncoded()
            let subdata = try serialize(val, forKey: key)
            data.append(subdata)
        }

        return data.joinedWithAmpersands()
    }

    /// Serializes a `URLEncodedFormData` at a given key.
    private func serialize(_ data: URLEncodedFormData, forKey key: Data) throws -> Data {
        let encoded: Data
        switch data {
        case .arr(let subArray): encoded = try serialize(subArray, forKey: key)
        case .dict(let subDict): encoded = try serialize(subDict, forKey: key)
        case .str(let string): encoded = try key + [.equals] + string.urlEncodedFormEncoded()
        }
        return encoded
    }

    /// Serializes a `[String: URLEncodedFormData]` at a given key.
    private func serialize(_ dictionary: [String: URLEncodedFormData], forKey key: Data) throws -> Data {
        var elements: [(key: String, value: URLEncodedFormData)]!

        if self.sortedKeys {
            elements = dictionary.sorted { (left, right) -> Bool in
                return left.key.compare(right.key, options: [.numeric, .caseInsensitive, .forcedOrdering]) == .orderedAscending
            }
        } else {
            elements = dictionary.map { $0 }
        }

        let values = try elements.map { (subKey, value) -> Data in
            let keyPath = try [.leftSquareBracket] + subKey.urlEncodedFormEncoded() + [.rightSquareBracket]
            return try serialize(value, forKey: key + keyPath)
        }

        return values.joinedWithAmpersands()
    }

    /// Serializes a `[URLEncodedFormData]` at a given key.
    private func serialize(_ array: [URLEncodedFormData], forKey key: Data) throws -> Data {
        let collection = try array.map { value -> Data in
            let keyPath = key + [.leftSquareBracket, .rightSquareBracket]
            return try serialize(value, forKey: keyPath)
        }

        return collection.joinedWithAmpersands()
    }
}

// MARK: Utilties

private extension Array where Element == Data {
    /// Joins an array of `Data` with ampersands.
    func joinedWithAmpersands() -> Data {
        return Data(self.joined(separator: [.ampersand]))
    }
}

private extension String {
    /// Prepares a `String` for inclusion in form-urlencoded data.
    func urlEncodedFormEncoded() throws -> Data {
        guard let string = self.addingPercentEncoding(withAllowedCharacters: _allowedCharacters) else {
            throw URLEncodedFormError(identifier: "percentEncoding", reason: "Failed to percent encode string: \(self)")
        }

        guard let encoded = string.data(using: .utf8) else {
            throw URLEncodedFormError(identifier: "utf8Encoding", reason: "Failed to utf8 encode string: \(self)")
        }

        return encoded
    }
}

/// Characters allowed in form-urlencoded data.
private var _allowedCharacters: CharacterSet = {
    var allowed = CharacterSet.urlQueryAllowed
    allowed.remove(charactersIn: "?&=[];+")
    return allowed
}()
