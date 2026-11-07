// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "mcmusBase",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(
            name: "mcmusBase",
            targets: ["Model", "Wrappers"]
        ),
        .library(
            name: "mcmusBaseTestSupport",
            targets: ["WrappersTestSupport"]
        ),
    ],
    targets: [
        // wrappers
        .target(name: "Wrappers"),
        .target(name: "WrappersTestSupport", dependencies: ["Wrappers"]),
        .testTarget(
            name: "WrappersTests",
            dependencies: ["Wrappers", "WrappersTestSupport"]
        ),
        // model
        .target(name: "Model", dependencies: ["Wrappers"]),
        .testTarget(
            name: "ModelTests",
            dependencies: ["Model", "Wrappers", "WrappersTestSupport"]
        ),

    ]
)
