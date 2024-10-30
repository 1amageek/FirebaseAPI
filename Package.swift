// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FirebaseAPI",
    platforms: [
        .iOS(.v15), .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "FirestoreAPI",
            targets: ["FirestoreAPI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.25.2"),
        .package(url: "https://github.com/grpc/grpc-swift.git", from: "1.24.1"),
        .package(url: "https://github.com/apple/swift-log.git", branch: "main")
    ],
    targets: [
        .target(
            name: "FirestoreAPI",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "GRPC", package: "grpc-swift"),
                .product(name: "protoc-gen-swift", package: "swift-protobuf")
            ]),
        .testTarget(
            name: "FirebaseAPITests",
            dependencies: [
                .product(name: "GRPC", package: "grpc-swift"),
                .product(name: "protoc-gen-swift", package: "swift-protobuf"),
                "FirestoreAPI"
            ]),
    ]
)
