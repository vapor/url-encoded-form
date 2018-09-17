/// Encodes `Encodable` instances to `application/x-www-form-urlencoded` data.
///
///     print(user) /// User
///     let data = try URLEncodedFormEncoder().encode(user)
///     print(data) /// Data
///
/// URL-encoded forms are commonly used by websites to send form data via POST requests. This encoding is relatively
/// efficient for small amounts of data but must be percent-encoded.  `multipart/form-data` is more efficient for sending
/// large data blobs like files.
///
/// See [Mozilla's](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/POST) docs for more information about
/// url-encoded forms.
public final class URLEncodedFormEncoder: DataEncoder {
    /// Create a new `URLEncodedFormEncoder`.
    public init() {}

    /// Encodes the supplied `Encodable` object to `Data`.
    ///
    ///     print(user) // User
    ///     let data = try URLEncodedFormEncoder().encode(user)
    ///     print(data) // "name=Vapor&age=3"
    ///
    /// - parameters:
    ///     - encodable: Generic `Encodable` object (`E`) to encode.
    /// - returns: Encoded `Data`
    /// - throws: Any error that may occur while attempting to encode the specified type.
    public func encode<E>(_ encodable: E) throws -> Data where E: Encodable {
        let context = URLEncodedFormDataContext(.dict([:]))
        let encoder = _URLEncodedFormEncoder(context: context, codingPath: [])
        try encodable.encode(to: encoder)
        let serializer = URLEncodedFormSerializer()
        guard case .dict(let dict) = context.data else {
            throw URLEncodedFormError(
                identifier: "invalidTopLevel",
                reason: "form-urlencoded requires a top level dictionary"
            )
        }
        return try serializer.serialize(dict)
    }
}

/// MARK: Private

/// Private `Encoder`.
private final class _URLEncodedFormEncoder: Encoder {
    /// See `Encoder`
    var userInfo: [CodingUserInfoKey: Any] {
        return [:]
    }

    /// See `Encoder`
    let codingPath: [CodingKey]

    /// The data being decoded
    var context: URLEncodedFormDataContext

    /// Creates a new form url-encoded encoder
    init(context: URLEncodedFormDataContext, codingPath: [CodingKey]) {
        self.context = context
        self.codingPath = codingPath
    }

    /// See `Encoder`
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key>
        where Key: CodingKey
    {
        let container = _URLEncodedFormKeyedEncoder<Key>(context: context, codingPath: codingPath)
        return .init(container)
    }

    /// See `Encoder`
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return _URLEncodedFormUnkeyedEncoder(context: context, codingPath: codingPath)
    }

    /// See `Encoder`
    func singleValueContainer() -> SingleValueEncodingContainer {
        return _URLEncodedFormSingleValueEncoder(context: context, codingPath: codingPath)
    }
}

/// Private `SingleValueEncodingContainer`.
private final class _URLEncodedFormSingleValueEncoder: SingleValueEncodingContainer {
    /// See `SingleValueEncodingContainer`
    var codingPath: [CodingKey]

    /// The data being encoded
    let context: URLEncodedFormDataContext

    /// Creates a new single value encoder
    init(context: URLEncodedFormDataContext, codingPath: [CodingKey]) {
        self.context = context
        self.codingPath = codingPath
    }

    /// See `SingleValueEncodingContainer`
    func encodeNil() throws {
        // skip
    }

    /// See `SingleValueEncodingContainer`
    func encode<T>(_ value: T) throws where T: Encodable {
        if let convertible = value as? URLEncodedFormDataConvertible {
            try context.data.set(to: convertible.convertToURLEncodedFormData(), at: codingPath)
        } else {
            let encoder = _URLEncodedFormEncoder(context: context, codingPath: codingPath)
            try value.encode(to: encoder)
        }
    }
}


/// Private `KeyedEncodingContainerProtocol`.
private final class _URLEncodedFormKeyedEncoder<K>: KeyedEncodingContainerProtocol where K: CodingKey {
    /// See `KeyedEncodingContainerProtocol`
    typealias Key = K

    /// See `KeyedEncodingContainerProtocol`
    var codingPath: [CodingKey]

    /// The data being encoded
    let context: URLEncodedFormDataContext

    /// Creates a new `_URLEncodedFormKeyedEncoder`.
    init(context: URLEncodedFormDataContext, codingPath: [CodingKey]) {
        self.context = context
        self.codingPath = codingPath
    }

    /// See `KeyedEncodingContainerProtocol`
    func encodeNil(forKey key: K) throws {
        // skip
    }

    /// See `KeyedEncodingContainerProtocol`
    func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
        if let convertible = value as? URLEncodedFormDataConvertible {
            try context.data.set(to: convertible.convertToURLEncodedFormData(), at: codingPath + [key])
        } else {
            let encoder = _URLEncodedFormEncoder(context: context, codingPath: codingPath + [key])
            try value.encode(to: encoder)
        }
    }

    /// See `KeyedEncodingContainerProtocol`
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey>
        where NestedKey: CodingKey
    {
        return .init(_URLEncodedFormKeyedEncoder<NestedKey>(context: context, codingPath: codingPath + [key]))
    }

    /// See `KeyedEncodingContainerProtocol`
    func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        return _URLEncodedFormUnkeyedEncoder(context: context, codingPath: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol`
    func superEncoder() -> Encoder {
        return _URLEncodedFormEncoder(context: context, codingPath: codingPath)
    }

    /// See `KeyedEncodingContainerProtocol`
    func superEncoder(forKey key: K) -> Encoder {
        return _URLEncodedFormEncoder(context: context, codingPath: codingPath + [key])
    }

}

/// Private `UnkeyedEncodingContainer`.
private final class _URLEncodedFormUnkeyedEncoder: UnkeyedEncodingContainer {
    /// See `UnkeyedEncodingContainer`.
    var codingPath: [CodingKey]

    /// See `UnkeyedEncodingContainer`.
    var count: Int

    /// The data being encoded
    let context: URLEncodedFormDataContext

    /// Converts the current count to a coding key
    var index: CodingKey {
        return BasicKey(count)
    }

    /// Creates a new `_URLEncodedFormUnkeyedEncoder`.
    init(context: URLEncodedFormDataContext, codingPath: [CodingKey]) {
        self.context = context
        self.codingPath = codingPath
        self.count = 0
    }

    /// See `UnkeyedEncodingContainer`.
    func encodeNil() throws {
        // skip
    }

    /// See UnkeyedEncodingContainer.encode
    func encode<T>(_ value: T) throws where T: Encodable {
        defer { count += 1 }
        if let convertible = value as? URLEncodedFormDataConvertible {
            try context.data.set(to: convertible.convertToURLEncodedFormData(), at: codingPath + [index])
        } else {
            let encoder = _URLEncodedFormEncoder(context: context, codingPath: codingPath + [index])
            try value.encode(to: encoder)
        }
    }

    /// See UnkeyedEncodingContainer.nestedContainer
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey>
        where NestedKey: CodingKey
    {
        defer { count += 1 }
        return .init(_URLEncodedFormKeyedEncoder<NestedKey>(context: context, codingPath: codingPath + [index]))
    }

    /// See UnkeyedEncodingContainer.nestedUnkeyedContainer
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        defer { count += 1 }
        return _URLEncodedFormUnkeyedEncoder(context: context, codingPath: codingPath + [index])
    }

    /// See UnkeyedEncodingContainer.superEncoder
    func superEncoder() -> Encoder {
        defer { count += 1 }
        return _URLEncodedFormEncoder(context: context, codingPath: codingPath + [index])
    }
}
