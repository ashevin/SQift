// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "SQift",
    products: [
        .library(
            name: "SQift",
            targets: ["SQift"]),
    ],
    targets: [
        .target(
            name: "SQift",
        ),
        .testTarget(
            name: "SQiftTests",
            dependencies: ["SQift"],
        )
    ]
)
