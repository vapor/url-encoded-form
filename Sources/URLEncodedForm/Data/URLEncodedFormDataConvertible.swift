/// Capable of converting to / from `URLEncodedFormData`.
protocol URLEncodedFormDataConvertible {
    /// Converts self to `URLEncodedFormData`.
    func convertToURLEncodedFormData() throws -> URLEncodedFormData

    /// Converts `URLEncodedFormData` to self.
    static func convertFromURLEncodedFormData(_ data: URLEncodedFormData) throws -> Self
}

extension String: URLEncodedFormDataConvertible {
    /// See `URLEncodedFormDataConvertible`.
    func convertToURLEncodedFormData() throws -> URLEncodedFormData {
        return .str(self)
    }

    /// See `URLEncodedFormDataConvertible`.
    static func convertFromURLEncodedFormData(_ data: URLEncodedFormData) throws -> String {
        guard let string = data.string else {
            throw URLEncodedFormError(identifier: "string", reason: "Could not convert to `String`: \(data)")
        }

        return string
    }
}

extension FixedWidthInteger {
    /// See `URLEncodedFormDataConvertible`.
    func convertToURLEncodedFormData() throws -> URLEncodedFormData {
        return .str(description)
    }

    /// See `URLEncodedFormDataConvertible`.
    static func convertFromURLEncodedFormData(_ data: URLEncodedFormData) throws -> Self {
        guard let fwi = data.string.flatMap(Self.init) else {
            throw URLEncodedFormError(identifier: "fwi", reason: "Could not convert to `\(Self.self)`: \(data)")
        }

        return fwi
    }
}

extension Int: URLEncodedFormDataConvertible { }
extension Int8: URLEncodedFormDataConvertible { }
extension Int16: URLEncodedFormDataConvertible { }
extension Int32: URLEncodedFormDataConvertible { }
extension Int64: URLEncodedFormDataConvertible { }
extension UInt: URLEncodedFormDataConvertible { }
extension UInt8: URLEncodedFormDataConvertible { }
extension UInt16: URLEncodedFormDataConvertible { }
extension UInt32: URLEncodedFormDataConvertible { }
extension UInt64: URLEncodedFormDataConvertible { }

extension BinaryFloatingPoint {
    /// See `URLEncodedFormDataConvertible`.
    func convertToURLEncodedFormData() throws -> URLEncodedFormData {
        return .str("\(self)")
    }

    /// See `URLEncodedFormDataConvertible`.
    static func convertFromURLEncodedFormData(_ data: URLEncodedFormData) throws -> Self {
        guard let bfp = data.string.flatMap(Double.init).flatMap(Self.init) else {
            throw URLEncodedFormError(identifier: "bfp", reason: "Could not convert to `\(Self.self)`: \(data)")
        }

        return bfp
    }
}

extension Float: URLEncodedFormDataConvertible { }
extension Double: URLEncodedFormDataConvertible { }

extension Bool: URLEncodedFormDataConvertible {
    /// See `URLEncodedFormDataConvertible`.
    func convertToURLEncodedFormData() throws -> URLEncodedFormData {
        return .str(description)
    }

    /// See `URLEncodedFormDataConvertible`.
    static func convertFromURLEncodedFormData(_ data: URLEncodedFormData) throws -> Bool {
        guard let bool = data.string?.bool else {
            throw URLEncodedFormError(identifier: "bool", reason: "Could not convert to Bool: \(data)")
        }
        return bool
    }
}

extension Dictionary: URLEncodedFormDataConvertible {
    /// See `URLEncodedFormDataConvertible`.
    func convertToURLEncodedFormData() throws -> URLEncodedFormData {
        var dict: [String: URLEncodedFormData] = [:]
        for (key, val) in self {
            guard let convertible = val as? URLEncodedFormDataConvertible else {
                throw URLEncodedFormError(identifier: "convertible", reason: "Could not convert `\(Value.self)` to form-urlencoded data.")
            }
            guard let str = key as? String else {
                throw URLEncodedFormError(identifier: "key", reason: "Could not convert `\(Key.self)` to String.")
            }
            dict[str] = try convertible.convertToURLEncodedFormData()
        }
        return .dict(dict)
    }

    /// See `URLEncodedFormDataConvertible`.
    static func convertFromURLEncodedFormData(_ data: URLEncodedFormData) throws -> [Key: Value] {
        var converted: [Key: Value] = [:]
        guard let dict = data.dictionary else {
            throw URLEncodedFormError(identifier: "dictionary", reason: "Could not convert form-urlencoded data to dictionary: \(data).")
        }
        guard let convertible = Value.self as? URLEncodedFormDataConvertible.Type else {
            throw URLEncodedFormError(identifier: "convertible", reason: "Could not convert `\(Value.self)` to form-urlencoded data.")
        }
        for (str, data) in dict {
            guard let key = str as? Key else {
                throw URLEncodedFormError(identifier: "key", reason: "Could not convert `\(Key.self)` to String.")
            }
            converted[key] = try convertible.convertFromURLEncodedFormData(data) as? Value
        }
        return converted
    }
}

extension Array: URLEncodedFormDataConvertible {
    /// See `URLEncodedFormDataConvertible`.
    func convertToURLEncodedFormData() throws -> URLEncodedFormData {
        return try .arr(map({ el in
            guard let data = el as? URLEncodedFormDataConvertible else {
                throw URLEncodedFormError(identifier: "convertible", reason: "Could not convert `\(Element.self)` to form-urlencoded data.")
            }
            return try data.convertToURLEncodedFormData()
        }))
    }

    /// See `URLEncodedFormDataConvertible`.
    static func convertFromURLEncodedFormData(_ data: URLEncodedFormData) throws -> [Element] {
        guard let arr = data.array else {
            throw URLEncodedFormError(identifier: "array", reason: "Could not convert form-urlencoded data to array: \(data).")
        }
        guard let convertible = Element.self as? URLEncodedFormDataConvertible.Type else {
            throw URLEncodedFormError(identifier: "convertible", reason: "Could not convert `\(Element.self)` to form-urlencoded data.")
        }
        return try arr.map { data in
            return try convertible.convertFromURLEncodedFormData(data) as! Element
        }
    }
}
