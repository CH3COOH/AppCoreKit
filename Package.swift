// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AppCoreKit",
    defaultLocalization: "en",
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
    dependencies: [
        .package(url: "https://github.com/RevenueCat/purchases-ios-spm.git", from: "5.0.0"),
        .package(url: "https://github.com/devicekit/DeviceKit.git", from: "5.8.0"),
    ],
    targets: [
        .target(
            name: "AppCoreKit",
            dependencies: [
                .product(name: "RevenueCat", package: "purchases-ios-spm"),
                .product(name: "DeviceKit", package: "DeviceKit", condition: .when(platforms: [.iOS])),
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "AppCoreKitTests",
            dependencies: ["AppCoreKit"]
        ),
    ]
)
