/// Decodes instances of `Decodable` types from `application/x-www-form-urlencoded` `Data`.
///
///     print(data) // "name=Vapor&age=3"
///     let user = try URLEncodedFormDecoder().decode(User.self, from: data)
///     print(user) // User
///
/// URL-encoded forms are commonly used by websites to send form data via POST requests. This encoding is relatively
/// efficient for small amounts of data but must be percent-encoded.  `multipart/form-data` is more efficient for sending
/// large data blobs like files.
///
/// See [Mozilla's](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/POST) docs for more information about
/// url-encoded forms.
public final class URLEncodedFormDecoder: DataDecoder {
    /// The underlying `URLEncodedFormEncodedParser`
    private let parser: URLEncodedFormParser

    /// If `true`, empty values will be omitted. Empty values are URL-Encoded keys with no value following the `=` sign.
    ///
    ///     name=Vapor&age=
    ///
    /// In the above example, `age` is an empty value.
    public var omitEmptyValues: Bool

    /// If `true`, flags will be omitted. Flags are URL-encoded keys with no following `=` sign.
    ///
    ///     name=Vapor&isAdmin&age=3
    ///
    /// In the above example, `isAdmin` is a flag.
    public var omitFlags: Bool

    /// Create a new `URLEncodedFormDecoder`.
    ///
    /// - parameters:
    ///     - omitEmptyValues: If `true`, empty values will be omitted.
    ///                        Empty values are URL-Encoded keys with no value following the `=` sign.
    ///     - omitFlags: If `true`, flags will be omitted.
    ///                  Flags are URL-encoded keys with no following `=` sign.
    public init(omitEmptyValues: Bool = false, omitFlags: Bool = false) {
        self.parser = URLEncodedFormParser()
        self.omitFlags = omitFlags
        self.omitEmptyValues = omitEmptyValues
    }

    /// Decodes an instance of the supplied `Decodable` type from `Data`.
    ///
    ///     print(data) // "name=Vapor&age=3"
    ///     let user = try URLEncodedFormDecoder().decode(User.self, from: data)
    ///     print(user) // User
    ///
    /// - parameters:
    ///     - decodable: Generic `Decodable` type (`D`) to decode.
    ///     - from: `Data` to decode a `D` from.
    /// - returns: An instance of the `Decodable` type (`D`).
    /// - throws: Any error that may occur while attempting to decode the specified type.
    public func decode<D>(_ decodable: D.Type, from data: Data) throws -> D where D : Decodable {
        let urlEncodedFormData = try self.parser.parse(percentEncoded: String(data: data, encoding: .utf8) ?? "", omitEmptyValues: self.omitEmptyValues, omitFlags: self.omitFlags)
        let decoder = _URLEncodedFormDecoder(context: .init(.dict(urlEncodedFormData)), codingPath: [])
        return try D(from: decoder)
    }
}

// MARK: Private

/// Private `Decoder`. See `URLEncodedFormDecoder` for public decoder.
private final class _URLEncodedFormDecoder: Decoder {
    /// See `Decoder`
    let codingPath: [CodingKey]

    /// See `Decoder`
    var userInfo: [CodingUserInfoKey: Any] {
        return [:]
    }

    /// The data being decoded
    let context: URLEncodedFormDataContext

    /// Creates a new `_URLEncodedFormDecoder`.
    init(context: URLEncodedFormDataContext, codingPath: [CodingKey]) {
        self.context = context
        self.codingPath = codingPath
    }

    /// See `Decoder`
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key>
        where Key: CodingKey
    {
        return .init(_URLEncodedFormKeyedDecoder<Key>(context: context, codingPath: codingPath))
    }

    /// See `Decoder`
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return _URLEncodedFormUnkeyedDecoder(context: context, codingPath: codingPath)
    }

    /// See `Decoder`
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return _URLEncodedFormSingleValueDecoder(context: context, codingPath: codingPath)
    }
}

/// Private `SingleValueDecodingContainer`.
private final class _URLEncodedFormSingleValueDecoder: SingleValueDecodingContainer {
    /// The data being decoded
    let context: URLEncodedFormDataContext

    /// See `SingleValueDecodingContainer`
    var codingPath: [CodingKey]

    /// Creates a new `_URLEncodedFormSingleValueDecoder`.
    init(context: URLEncodedFormDataContext, codingPath: [CodingKey]) {
        self.context = context
        self.codingPath = codingPath
    }

    /// See `SingleValueDecodingContainer`
    func decodeNil() -> Bool {
        return context.data.get(at: codingPath) == nil
    }

    /// See `SingleValueDecodingContainer`
    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        guard let data = context.data.get(at: codingPath) else {
            throw DecodingError.valueNotFound(T.self, at: codingPath)
        }
        if let convertible = T.self as? URLEncodedFormDataConvertible.Type {
            return try convertible.convertFromURLEncodedFormData(data) as! T
        } else {
            let decoder = _URLEncodedFormDecoder(context: context, codingPath: codingPath)
            return try T.init(from: decoder)
        }
    }
}

/// Private `KeyedDecodingContainerProtocol`.
private final class _URLEncodedFormKeyedDecoder<K>: KeyedDecodingContainerProtocol where K: CodingKey {
    /// See `KeyedDecodingContainerProtocol.`
    typealias Key = K

    /// The data being decoded
    let context: URLEncodedFormDataContext

    /// See `KeyedDecodingContainerProtocol.`
    var codingPath: [CodingKey]

    /// See `KeyedDecodingContainerProtocol.`
    var allKeys: [K] {
        guard let dictionary = context.data.get(at: codingPath)?.dictionary else {
            return []
        }
        return dictionary.keys.compactMap { K(stringValue: $0) }
    }

    /// Create a new `_URLEncodedFormKeyedDecoder`
    init(context: URLEncodedFormDataContext, codingPath: [CodingKey]) {
        self.context = context
        self.codingPath = codingPath
    }

    /// See `KeyedDecodingContainerProtocol.`
    func contains(_ key: K) -> Bool {
        return context.data.get(at: codingPath)?.dictionary?[key.stringValue] != nil
    }

    /// See `KeyedDecodingContainerProtocol.`
    func decodeNil(forKey key: K) throws -> Bool {
        return context.data.get(at: codingPath + [key]) == nil
    }

    /// See `KeyedDecodingContainerProtocol.`
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable {
        if let convertible = T.self as? URLEncodedFormDataConvertible.Type {
            guard let data = context.data.get(at: codingPath + [key]) else {
                throw DecodingError.valueNotFound(T.self, at: codingPath + [key])
            }
            return try convertible.convertFromURLEncodedFormData(data) as! T
        } else {
            let decoder = _URLEncodedFormDecoder(context: context, codingPath: codingPath + [key])
            return try T(from: decoder)
        }
    }

    /// See `KeyedDecodingContainerProtocol.`
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey>
        where NestedKey: CodingKey
    {
        return .init(_URLEncodedFormKeyedDecoder<NestedKey>(context: context, codingPath: codingPath + [key]))
    }

    /// See `KeyedDecodingContainerProtocol.`
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        return _URLEncodedFormUnkeyedDecoder(context: context, codingPath: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.`
    func superDecoder() throws -> Decoder {
        return _URLEncodedFormDecoder(context: context, codingPath: codingPath)
    }

    /// See `KeyedDecodingContainerProtocol.`
    func superDecoder(forKey key: K) throws -> Decoder {
        return _URLEncodedFormDecoder(context: context, codingPath: codingPath + [key])
    }
}

/// Private `UnkeyedDecodingContainer`.
private final class _URLEncodedFormUnkeyedDecoder: UnkeyedDecodingContainer {
    /// The data being decoded
    let context: URLEncodedFormDataContext

    /// See `UnkeyedDecodingContainer`.
    var codingPath: [CodingKey]

    /// See `UnkeyedDecodingContainer`.
    var count: Int? {
        guard let array = context.data.get(at: codingPath)?.array else {
            return nil
        }
        return array.count
    }

    /// See `UnkeyedDecodingContainer`.
    var isAtEnd: Bool {
        guard let count = self.count else {
            return true
        }
        return currentIndex >= count
    }

    /// See `UnkeyedDecodingContainer`.
    var currentIndex: Int

    /// Converts the current index to a coding key
    var index: CodingKey {
        return BasicKey(currentIndex)
    }

    /// Create a new `_URLEncodedFormUnkeyedDecoder`
    init(context: URLEncodedFormDataContext, codingPath: [CodingKey]) {
        self.context = context
        self.codingPath = codingPath
        currentIndex = 0
    }

    /// See `UnkeyedDecodingContainer`.
    func decodeNil() throws -> Bool {
        return context.data.get(at: codingPath + [index]) == nil
    }

    /// See `UnkeyedDecodingContainer`.
    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        defer { currentIndex += 1 }
        if let convertible = T.self as? URLEncodedFormDataConvertible.Type {
            guard let data = context.data.get(at: codingPath + [index]) else {
                throw DecodingError.valueNotFound(T.self, at: codingPath + [index])
            }
            return try convertible.convertFromURLEncodedFormData(data) as! T
        } else {
            let decoder = _URLEncodedFormDecoder(context: context, codingPath: codingPath + [index])
            return try T(from: decoder)
        }
    }

    /// See `UnkeyedDecodingContainer`.
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey>
        where NestedKey: CodingKey
    {
        return .init(_URLEncodedFormKeyedDecoder<NestedKey>(context: context, codingPath: codingPath + [index]))
    }

    /// See `UnkeyedDecodingContainer`.
    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        return _URLEncodedFormUnkeyedDecoder(context: context, codingPath: codingPath + [index])
    }

    /// See `UnkeyedDecodingContainer`.
    func superDecoder() throws -> Decoder {
        defer { currentIndex += 1 }
        return _URLEncodedFormDecoder(context: context, codingPath: codingPath + [index])
    }

}


// MARK: Utils

private extension DecodingError {
    static func typeMismatch(_ type: Any.Type, at path: [CodingKey]) -> DecodingError {
        let pathString = path.map { $0.stringValue }.joined(separator: ".")
        let context = DecodingError.Context(
            codingPath: path,
            debugDescription: "No \(type) was found at path \(pathString)"
        )
        return Swift.DecodingError.typeMismatch(type, context)
    }
    
    static func valueNotFound(_ type: Any.Type, at path: [CodingKey]) -> DecodingError {
        let pathString = path.map { $0.stringValue }.joined(separator: ".")
        let context = DecodingError.Context(
            codingPath: path,
            debugDescription: "No \(type) was found at path \(pathString)"
        )
        return Swift.DecodingError.valueNotFound(type, context)
    }
}
