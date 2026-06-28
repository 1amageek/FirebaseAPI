// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FirebaseAPI",
    platforms: [
        .macOS(.v15), .iOS(.v18), .watchOS(.v11), .tvOS(.v18), .visionOS(.v2)
    ],
    products: [
        .library(
            name: "FirestoreAPI",
            targets: ["FirestoreAPI"]),
        .library(
            name: "FirestoreAdminServer",
            targets: ["FirestoreAdminServer"]),
        .library(
            name: "FirestoreMongoCore",
            targets: ["FirestoreMongoCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/1amageek/swift-protobuf.git", branch: "main"),
        .package(url: "https://github.com/1amageek/swift-crypto.git", branch: "main"),
        .package(url: "https://github.com/1amageek/grpc-swift-2.git", branch: "main"),
        .package(url: "https://github.com/1amageek/grpc-swift-nio-transport.git", branch: "main"),
        .package(url: "https://github.com/1amageek/grpc-swift-protobuf.git", branch: "main"),
        .package(url: "https://github.com/1amageek/swift-log.git", branch: "main")
    ],
    targets: [
        .target(
            name: "FirestoreCore"),
        .target(
            name: "FirestoreAuthCore"),
        .target(
            name: "FirestoreAuth",
            dependencies: [
                "FirestoreAuthCore",
                "FirestoreCore",
                .product(name: "CryptoExtras", package: "swift-crypto")
            ]),
        .target(
            name: "FirestorePipeline",
            dependencies: [
                "FirestoreCore"
            ]),
        .target(
            name: "FirestoreRuntimeConfig",
            dependencies: [
                "FirestoreCore"
            ]),
        .target(
            name: "FirestoreProtobuf",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ]),
        .target(
            name: "FirestoreGRPCStubs",
            dependencies: [
                "FirestoreProtobuf",
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "GRPCProtobuf", package: "grpc-swift-protobuf"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ]),
        .target(
            name: "FirestoreRPCSupport",
            dependencies: [
                "FirestoreCore",
                "FirestoreProtobuf"
            ]),
        .target(
            name: "FirestoreRPC",
            dependencies: [
                "FirestoreCore",
                "FirestoreRuntimeConfig",
                "FirestoreRPCSupport",
                "FirestoreProtobuf",
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ]),
        .target(
            name: "FirestorePipelineRPC",
            dependencies: [
                "FirestoreCore",
                "FirestorePipeline",
                "FirestoreRPCSupport",
                "FirestoreProtobuf",
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ]),
        .target(
            name: "FirestoreRuntimeSupport",
            dependencies: [
                "FirestoreCore",
                "FirestorePipeline"
            ]),
        .target(
            name: "FirestoreCodable",
            dependencies: [
                "FirestoreCore"
            ]),
        .target(
            name: "FirestoreGeoQuery",
            dependencies: [
                "FirestoreCore"
            ]),
        .target(
            name: "FirestoreMongoCore",
            dependencies: [
                "FirestoreCore"
            ]),
        .target(
            name: "FirestoreAdmin",
            dependencies: [
                "FirestoreCore",
                "FirestorePipeline",
                "FirestoreRuntimeSupport",
                "FirestoreRuntimeConfig"
            ]),
        .target(
            name: "FirestoreAdminCodable",
            dependencies: [
                "FirestoreAdmin",
                "FirestoreCodable",
                "FirestoreCore"
            ]),
        .target(
            name: "FirestoreAdminGRPCBootstrap",
            dependencies: [
                "FirestoreAdmin",
                "FirestoreAuthCore",
                "FirestoreAuth",
                "FirestoreCore",
                "FirestoreRuntimeConfig",
                "FirestoreGRPCTransport"
            ]),
        .target(
            name: "FirestoreGRPCTransport",
            dependencies: [
                "FirestoreCore",
                "FirestoreAuthCore",
                "FirestoreRuntimeConfig",
                "FirestorePipeline",
                "FirestoreRuntimeSupport",
                "FirestoreRPC",
                "FirestorePipelineRPC",
                "FirestoreProtobuf",
                "FirestoreGRPCStubs",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift-nio-transport")
            ]),
        .target(
            name: "FirestoreAPI",
            dependencies: [
                "FirestoreCore",
                "FirestoreAuthCore",
                "FirestoreAuth",
                "FirestorePipeline",
                "FirestoreRuntimeConfig",
                "FirestoreRuntimeSupport",
                "FirestoreCodable",
                "FirestoreGeoQuery",
                "FirestoreMongoCore",
                "FirestoreAdmin",
                "FirestoreAdminCodable",
                "FirestoreAdminGRPCBootstrap"
            ]),
        .target(
            name: "FirestoreAdminServer",
            dependencies: [
                "FirestoreCore",
                "FirestoreAuthCore",
                "FirestoreAuth",
                "FirestorePipeline",
                "FirestoreRuntimeConfig",
                "FirestoreCodable",
                "FirestoreGeoQuery",
                "FirestoreAdmin",
                "FirestoreAdminCodable",
                "FirestoreAdminGRPCBootstrap"
            ]),
        .testTarget(
            name: "FirebaseAPITests",
            dependencies: [
                "FirestoreAdmin",
                "FirestoreAdminCodable",
                "FirestoreAdminGRPCBootstrap",
                "FirestoreAuthCore",
                "FirestoreAuth",
                "FirestoreCodable",
                "FirestoreGeoQuery",
                "FirestoreMongoCore",
                "FirestoreAdminServer",
                "FirestorePipeline",
                "FirestoreRuntimeConfig",
                "FirestoreRuntimeSupport",
                "FirestoreRPCSupport",
                "FirestoreRPC",
                "FirestorePipelineRPC",
                "FirestoreGRPCTransport",
                "FirestoreProtobuf",
                .product(name: "CryptoExtras", package: "swift-crypto"),
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                "FirestoreAPI"
            ]),
    ]
)
