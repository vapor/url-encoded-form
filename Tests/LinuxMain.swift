import XCTest

import URLEncodedFormTests

var tests = [XCTestCaseEntry]()
tests += URLEncodedFormTests.allTests()
XCTMain(tests)