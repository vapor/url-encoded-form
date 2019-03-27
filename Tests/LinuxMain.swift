import XCTest

import URLEncodedFormTests

var tests = [XCTestCaseEntry]()
tests += URLEncodedFormTests.__allTests()

XCTMain(tests)
