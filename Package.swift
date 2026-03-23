// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AppCoreKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "AppCoreKit",
            targets: ["AppCoreKit"]
        ),
    ],
    targets: [
        .target(
            name: "AppCoreKit"
        ),
        .testTarget(
            name: "AppCoreKitTests",
            dependencies: ["AppCoreKit"]
        ),
    ]
)
