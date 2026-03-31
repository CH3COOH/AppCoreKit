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
    dependencies: [
        .package(url: "https://github.com/RevenueCat/purchases-ios-spm.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "AppCoreKit",
            dependencies: [
                .product(name: "RevenueCat", package: "purchases-ios-spm"),
            ]
        ),
        .testTarget(
            name: "AppCoreKitTests",
            dependencies: ["AppCoreKit"]
        ),
    ]
)
