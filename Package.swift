// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

let manifestDirectoryURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent()

func localOrForkDependency(_ repository: String, localPath: String) -> Package.Dependency {
    let resolvedLocalPath = URL(fileURLWithPath: localPath, relativeTo: manifestDirectoryURL)
        .standardizedFileURL
        .path
    if FileManager.default.fileExists(atPath: resolvedLocalPath) {
        return .package(path: resolvedLocalPath)
    }

    return .package(url: "https://github.com/1amageek/\(repository).git", branch: "main")
}

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
        localOrForkDependency("swift-protobuf", localPath: "../networking/swift-protobuf"),
        localOrForkDependency("swift-crypto", localPath: "../networking/swift-crypto"),
        localOrForkDependency("grpc-swift-2", localPath: "../networking/grpc-swift-2"),
        localOrForkDependency("grpc-swift-nio-transport", localPath: "../networking/grpc-swift-nio-transport"),
        localOrForkDependency("grpc-swift-protobuf", localPath: "../networking/grpc-swift-protobuf"),
        localOrForkDependency("swift-log", localPath: "../networking/swift-log")
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
