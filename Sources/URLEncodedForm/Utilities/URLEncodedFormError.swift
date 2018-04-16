import Debugging

/// Errors thrown while encoding/decoding `application/x-www-form-urlencoded` data.
public struct URLEncodedFormError: Error, Debuggable {
    /// See Debuggable.identifier
    public let identifier: String

    /// See Debuggable.reason
    public let reason: String

    /// Creates a new `URLEncodedFormError`.
    public init(identifier: String, reason: String) {
        self.identifier = identifier
        self.reason = reason
    }
}
