// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ProtoGeneration",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "ClassNotesProtos",
            targets: ["ClassNotesProtos"]
        ),
        .plugin(
            name: "GenerateProtos",
            targets: ["GenerateProtos"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.30.0"),
        .package(url: "https://github.com/grpc/grpc-swift-2.git", from: "2.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift-protobuf.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "ClassNotesProtos",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "GRPCProtobuf", package: "grpc-swift-protobuf"),
            ],
            path: "Sources/ClassNotesProtos"
        ),
        .plugin(
            name: "GenerateProtos",
            capability: .buildTool(),
            dependencies: [
                .product(name: "GRPCProtobufPlugin", package: "grpc-swift-protobuf")
            ]
        ),
    ]
)
