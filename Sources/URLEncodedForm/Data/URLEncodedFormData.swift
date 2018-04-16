import Bits

/// Represents application/x-www-form-urlencoded encoded data.
enum URLEncodedFormData: NestedData, ExpressibleByArrayLiteral, ExpressibleByStringLiteral, ExpressibleByDictionaryLiteral, Equatable {
    /// See `NestedData`.
    static func dictionary(_ value: [String : URLEncodedFormData]) -> URLEncodedFormData {
        return .dict(value)
    }

    /// See `NestedData`.
    static func array(_ value: [URLEncodedFormData]) -> URLEncodedFormData {
        return .arr(value)
    }

    /// Stores a string, this is the root storage.
    case str(String)

    /// Stores a dictionary of self.
    case dict([String: URLEncodedFormData])

    /// Stores an array of self.
    case arr([URLEncodedFormData])

    // MARK: Polymorphic

    /// Converts self to an `String` or returns `nil` if not convertible.
    var string: String? {
        switch self {
        case .str(let s): return s
        default: return nil
        }
    }

    /// Converts self to an `[URLEncodedFormData]` or returns `nil` if not convertible.
    var array: [URLEncodedFormData]? {
        switch self {
        case .arr(let arr): return arr
        default: return nil
        }
    }

    /// Converts self to an `[String: URLEncodedFormData]` or returns `nil` if not convertible.
    var dictionary: [String: URLEncodedFormData]? {
        switch self {
        case .dict(let dict): return dict
        default: return nil
        }
    }

    // MARK: Literal

    /// See `ExpressibleByArrayLiteral`.
    init(arrayLiteral elements: URLEncodedFormData...) {
        self = .arr(elements)
    }

    /// See `ExpressibleByStringLiteral`.
    init(stringLiteral value: String) {
        self = .str(value)
    }

    /// See `ExpressibleByDictionaryLiteral`.
    init(dictionaryLiteral elements: (String, URLEncodedFormData)...) {
        var dict: [String: URLEncodedFormData] = [:]
        elements.forEach { dict[$0.0] = $0.1 }
        self = .dict(dict)
    }
}

/// Reference type wrapper around `URLEncodedFormData`.
final class URLEncodedFormDataContext {
    /// The wrapped data.
    var data: URLEncodedFormData

    /// Creates a new `URLEncodedFormDataContext`.
    init(_ data: URLEncodedFormData) {
        self.data = data
    }
}
