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

extension Decimal: URLEncodedFormDataConvertible {
    /// See `URLEncodedFormDataConvertible`.
    func convertToURLEncodedFormData() throws -> URLEncodedFormData {
        return .str(description)
    }
    
    /// See `URLEncodedFormDataConvertible`.
    static func convertFromURLEncodedFormData(_ data: URLEncodedFormData) throws -> Decimal {
        guard let string = data.string, let d = Decimal(string: string) else {
            throw URLEncodedFormError(identifier: "decimal", reason: "Could not convert to Decimal: \(data)")
        }
        
        return d
    }
}
