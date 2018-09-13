import URLEncodedForm
import XCTest

class URLEncodedFormCodableTests: XCTestCase {
    func testDecode() throws {
        let data = """
        name=Tanner&age=23&pets[]=Zizek&pets[]=Foo&dict[a]=1&dict[b]=2&friends[valerio][name]=Valerio&friends[valerio][age]=32
        """.data(using: .utf8)!
        let user = try URLEncodedFormDecoder().decode(User.self, from: data)
        XCTAssertEqual(user.name, "Tanner")
        XCTAssertEqual(user.age, 23)
        XCTAssertEqual(user.pets?.count, 2)
        XCTAssertEqual(user.pets?.first, "Zizek")
        XCTAssertEqual(user.pets?.last, "Foo")
        XCTAssertEqual(user.dict?["a"], 1)
        XCTAssertEqual(user.dict?["b"], 2)
        XCTAssertEqual(user.friends, ["valerio": User(name: "Valerio", age: 32, pets: nil, dict: nil, friends: nil)])
    }

    func testEncode() throws {
        let user = User(
            name: "Tanner",
            age: 23,
            pets: ["Zizek", "Foo"],
            dict: ["a": 1, "b": 2],
            friends: ["valerio": User(name: "Valerio", age: 32, pets: [], dict: [:], friends: [:])]
        )
        let data = try URLEncodedFormEncoder().encode(user)
        let result = String(data: data, encoding: .utf8)!
        XCTAssert(result.contains("pets[]=Zizek"))
        XCTAssert(result.contains("pets[]=Foo"))
        XCTAssert(result.contains("age=23"))
        XCTAssert(result.contains("name=Tanner"))
        XCTAssert(result.contains("dict[a]=1"))
        XCTAssert(result.contains("dict[b]=2"))
        XCTAssert(result.contains("friends[valerio][name]=Valerio"))
        XCTAssert(result.contains("friends[valerio][age]=32"))
    }

    func testCodable() throws {
        let a = User(name: "Tanner", age: 23, pets: ["Zizek", "Foo"], dict: ["a": 1, "b": 2], friends: nil)
        let body = try URLEncodedFormEncoder().encode(a)
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

    /// https://github.com/vapor/url-encoded-form/issues/3
    func testGH3() throws {
        struct Foo: Codable {
            var flag: Bool
        }
        let foo = try URLEncodedFormDecoder().decode(Foo.self, from: "flag=1")
        XCTAssertEqual(foo.flag, true)
    }

    static let allTests = [
        ("testDecode", testDecode),
        ("testEncode", testEncode),
        ("testCodable", testCodable),
        ("testDecodeIntArray", testDecodeIntArray),
        ("testRawEnum", testRawEnum),
        ("testGH3", testGH3),
    ]
}

struct User: Codable, Equatable {
    static func ==(lhs: User, rhs: User) -> Bool {
        return lhs.name == rhs.name
            && lhs.age == rhs.age
            && lhs.pets == rhs.pets
            && lhs.dict == rhs.dict
            && lhs.friends == rhs.friends
    }

    var name: String
    var age: Int
    var pets: [String]?
    var dict: [String: Int]?
    var friends: [String: User]?
}
