// swift-tools-version:4.1
import PackageDescription

let package = Package(
    name: "URLEncodedForm",
    products: [
        .library(name: "URLEncodedForm", targets: ["URLEncodedForm"]),
    ],
    dependencies: [
        // 🌎 Utility package containing tools for byte manipulation, Codable, OS APIs, and debugging.
        .package(url: "https://github.com/vapor/core.git", from: "3.0.0"),
    ],
    targets: [
        .target(name: "URLEncodedForm", dependencies: ["Core"]),
        .testTarget(name: "URLEncodedFormTests", dependencies: ["URLEncodedForm"]),
    ]
)
