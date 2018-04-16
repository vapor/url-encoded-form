import XCTest

import URLEncodedFormTests

var tests = [XCTestCaseEntry]()
tests += URLEncodedFormCodableTests.allTests()
tests += URLEncodedFormParserTests.allTests()
tests += URLEncodedFormSerializerTests.allTests()
XCTMain(tests)