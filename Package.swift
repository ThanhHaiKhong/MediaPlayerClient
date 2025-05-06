// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MediaPlayerClient",
    platforms: [
		.iOS(.v15), .macOS(.v13), .tvOS(.v15), .watchOS(.v8)
    ],
    products: [
        .singleTargetLibrary("MediaPlayerClient"),
        .singleTargetLibrary("MediaPlayerClientLive"),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "MediaPlayerClient",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .target(
            name: "MediaPlayerClientLive",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "MediaPlayerClient",
                "ZFPlayerObjC",
            ]
        ),
        .target(
            name: "ZFPlayerObjC",
            dependencies: [
                "IJKMediaFramework"
            ],
            path: "Sources/ZFPlayerObjC",
            publicHeadersPath: "."
        ),
		.binaryTarget(
			name: "IJKMediaFramework",
			url: "https://github.com/ThanhHaiKhong/IJKMediaFramework/releases/download/v1.0.0/IJKMediaFramework.xcframework.zip",
			checksum: "8c5d56b56fbc8041d5a4cc36d6fd08b52b0c742f7da6da8d13182d25876b00b4"
		)
    ]
)

extension Product {
    static func singleTargetLibrary(_ name: String) -> Product {
        .library(name: name, targets: [name])
    }
}
