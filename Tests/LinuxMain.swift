#if os(Linux)

import XCTest
@testable import URLEncodedFormTests
XCTMain([
    testCase(URLEncodedFormCodableTests.allTests),
    testCase(URLEncodedFormParserTests.allTests),
    testCase(URLEncodedFormSerializerTests.allTests),
])

#endif