@testable import URLEncodedForm
import XCTest

class URLEncodedFormSerializerTests: XCTestCase {
    func testPercentEncoding() throws {
        let form: [String: URLEncodedFormData] = ["aaa]": "+bbb  ccc"]
        let data = try URLEncodedFormSerializer.default.serialize(form)
        XCTAssertEqual(String(data: data, encoding: .utf8)!, "aaa%5D=%2Bbbb%20%20ccc")
    }

    func testPercentEncodingWithAmpersand() throws {
        let form: [String: URLEncodedFormData] = ["aaa": "b%26&b"]
        let data = try URLEncodedFormSerializer.default.serialize(form)
        XCTAssertEqual(String(data: data, encoding: .utf8)!, "aaa=b%2526&b")
    }

    func testNested() throws {
        let form: [String: URLEncodedFormData] = ["a": ["b": ["c": ["d": ["hello": "world"]]]]]
        let data = try URLEncodedFormSerializer.default.serialize(form)
        XCTAssertEqual(String(data: data, encoding: .utf8)!, "a[b][c][d][hello]=world")
    }

    static let allTests = [
        ("testPercentEncoding", testPercentEncoding),
        ("testPercentEncodingWithAmpersand", testPercentEncodingWithAmpersand),
        ("testNested", testNested),
    ]
}

