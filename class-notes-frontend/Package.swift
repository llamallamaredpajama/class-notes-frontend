// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ClassNotes",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ClassNotes",
            targets: ["ClassNotes"]
        ),
    ],
    dependencies: [
        // Google Sign-In
        .package(
            url: "https://github.com/google/GoogleSignIn-iOS",
            from: "7.0.0"
        ),
        // gRPC for backend communication
        .package(
            url: "https://github.com/grpc/grpc-swift.git",
            from: "1.19.0"
        ),
        // Async algorithms for data processing
        .package(
            url: "https://github.com/apple/swift-async-algorithms",
            from: "0.1.0"
        ),
        // SwiftLint for code quality
        .package(
            url: "https://github.com/realm/SwiftLint",
            from: "0.53.0"
        ),
        // KeychainAccess for simpler keychain operations
        .package(
            url: "https://github.com/kishikawakatsumi/KeychainAccess.git",
            from: "4.2.2"
        ),
        // WhisperKit for on-device speech recognition
        .package(
            url: "https://github.com/argmaxinc/WhisperKit.git",
            from: "0.12.0"
        )
    ],
    targets: [
        .target(
            name: "ClassNotes",
            dependencies: [
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "GRPC", package: "grpc-swift"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "WhisperKit", package: "WhisperKit")
            ],
            path: "ClassNotes"
        ),
        .testTarget(
            name: "ClassNotesTests",
            dependencies: ["ClassNotes"],
            path: "Tests"
        ),
    ]
) 
