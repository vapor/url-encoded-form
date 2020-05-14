import URLEncodedForm
import XCTest

class URLEncodedFormCodableTests: XCTestCase {
    func testDecode() throws {
        let data = """
        name=Tanner&age=23&pets[]=Zizek&pets[]=Foo&dict[a]=1&dict[b]=2&foos[]=baz&nums[]=3.14&url=https%3A%2F%2Fvapor.codes
        """.data(using: .utf8)!

        let user = try URLEncodedFormDecoder().decode(User.self, from: data)
        XCTAssertEqual(user.name, "Tanner")
        XCTAssertEqual(user.age, 23)
        XCTAssertEqual(user.pets.count, 2)
        XCTAssertEqual(user.pets.first, "Zizek")
        XCTAssertEqual(user.pets.last, "Foo")
        XCTAssertEqual(user.dict["a"], 1)
        XCTAssertEqual(user.dict["b"], 2)
        XCTAssertEqual(user.foos[0], .baz)
        XCTAssertEqual(user.nums[0], 3.14)
        XCTAssertEqual(user.url, URL(string: "https://vapor.codes"))
    }

    func testEncode() throws {
        let user = User(name: "Tanner", age: 23, pets: ["Zizek", "Foo"], dict: ["a": 1, "b": 2], foos: [.baz], nums: [3.14], url: URL(string: "https://vapor.codes")!)
        let data = try URLEncodedFormEncoder().encode(user)
        let result = String(data: data, encoding: .utf8)!
        XCTAssert(result.contains("pets[]=Zizek"))
        XCTAssert(result.contains("pets[]=Foo"))
        XCTAssert(result.contains("age=23"))
        XCTAssert(result.contains("name=Tanner"))
        XCTAssert(result.contains("dict[a]=1"))
        XCTAssert(result.contains("dict[b]=2"))
        XCTAssert(result.contains("foos[]=baz"))
        XCTAssert(result.contains("nums[]=3.14"))
        XCTAssert(result.contains("url=https://vapor.codes"))
    }

    func testCodable() throws {
        let a = User(name: "Tanner", age: 23, pets: ["Zizek", "Foo"], dict: ["a": 1, "b": 2], foos: [], nums: [], url: URL(string: "https://vapor.codes")!)
        let body = try URLEncodedFormEncoder().encode(a)
        print(String(data: body, encoding: .utf8)!)
        let b = try URLEncodedFormDecoder().decode(User.self, from: body)
        XCTAssertEqual(a, b)
    }

    func testDecodeIntArray() throws {
        let data = """
        array[]=1&array[]=2&array[]=3
        """.data(using: .utf8)!

        let content = try URLEncodedFormDecoder().decode([String: [Int]].self, from: data)
        XCTAssertEqual(content["array"], [1, 2, 3])
    }

    func testRawEnum() throws {
        enum PetType: String, Codable {
            case cat, dog
        }
        struct Pet: Codable {
            var name: String
            var type: PetType
        }
        let ziz = try URLEncodedFormDecoder().decode(Pet.self, from: "name=Ziz&type=cat")
        XCTAssertEqual(ziz.name, "Ziz")
        XCTAssertEqual(ziz.type, .cat)
        let data = try URLEncodedFormEncoder().encode(ziz)
        let string = String(data: data, encoding: .ascii)
        XCTAssertEqual(string?.contains("name=Ziz"), true)
        XCTAssertEqual(string?.contains("type=cat"), true)
    }

    func testSortedDictionary() throws {
        let user = User(name: "Tanner", age: 23, pets: ["Zizek", "Foo"], dict: ["a": 1, "b": 2])
        let encoder = URLEncodedFormEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(user)
        let string = String(data: data, encoding: .ascii)
        XCTAssertEqual(string, "age=23&dict[a]=1&dict[b]=2&name=Tanner&pets[]=Zizek&pets[]=Foo")
    }

    /// https://github.com/vapor/url-encoded-form/issues/3
    func testGH3() throws {
        struct Foo: Codable {
            var flag: Bool
        }
        let foo = try URLEncodedFormDecoder().decode(Foo.self, from: "flag=1")
        XCTAssertEqual(foo.flag, true)
    }

    /// https://github.com/vapor/url-encoded-form/issues/3
    func testEncodeReserved() throws {
        struct Foo: Codable {
            var reserved: String
        }
        let foo = Foo(reserved: "?&=[];+")
        let data = try URLEncodedFormEncoder().encode(foo)
        XCTAssertEqual(String(decoding: data, as: UTF8.self), "reserved=%3F%26%3D%5B%5D%3B%2B")
    }

    static let allTests = [
        ("testDecode", testDecode),
        ("testEncode", testEncode),
        ("testCodable", testCodable),
        ("testDecodeIntArray", testDecodeIntArray),
        ("testRawEnum", testRawEnum),
        ("testSortedDictionary", testSortedDictionary),
        ("testGH3", testGH3),
        ("testEncodeReserved", testEncodeReserved),
    ]
}

struct User: Codable, Equatable {
    static func ==(lhs: User, rhs: User) -> Bool {
        return lhs.name == rhs.name
            && lhs.age == rhs.age
            && lhs.pets == rhs.pets
            && lhs.dict == rhs.dict
    }

    var name: String
    var age: Int
    var pets: [String]
    var dict: [String: Int]
    var foos: [Foo]
    var nums: [Decimal]
    var url: URL
}

enum Foo: String, Codable {
    case foo, bar, baz
}
