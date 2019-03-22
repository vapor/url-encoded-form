// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "url-encoded-form",
    products: [
        .library(name: "URLEncodedForm", targets: ["URLEncodedForm"]),
    ],
    dependencies: [ ],
    targets: [
        .target(name: "URLEncodedForm"),
        .testTarget(name: "URLEncodedFormTests", dependencies: ["URLEncodedForm"]),
    ]
)
