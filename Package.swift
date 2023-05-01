// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FirebaseAPI",
    platforms: [
        .iOS(.v16), .macOS(.v13)
    ],
    products: [
        .library(
            name: "FirestoreAPI",
            targets: ["FirestoreAPI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.21.0"),
        .package(url: "https://github.com/grpc/grpc-swift.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "FirestoreAPI",
            dependencies: [
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
