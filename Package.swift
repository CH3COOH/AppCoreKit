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
        // 全部入り(Core + Store + Feedback)
        .library(
            name: "AppCoreKit",
            targets: ["AppCoreKit"]
        ),
        // 外部依存なしの共通部品(UseCase / View / Logger など)
        .library(
            name: "AppCoreKitCore",
            targets: ["AppCoreKitCore"]
        ),
        // 課金(RevenueCat)
        .library(
            name: "AppCoreKitStore",
            targets: ["AppCoreKitStore"]
        ),
        // フィードバック画面(DeviceKit、iOS のみ)
        .library(
            name: "AppCoreKitFeedback",
            targets: ["AppCoreKitFeedback"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/RevenueCat/purchases-ios-spm.git", from: "5.0.0"),
        .package(url: "https://github.com/devicekit/DeviceKit.git", from: "5.8.0"),
    ],
    targets: [
        .target(
            name: "AppCoreKit",
            dependencies: ["AppCoreKitCore", "AppCoreKitStore", "AppCoreKitFeedback"]
        ),
        .target(
            name: "AppCoreKitCore",
            resources: [.process("Resources")]
        ),
        .target(
            name: "AppCoreKitStore",
            dependencies: [
                "AppCoreKitCore",
                .product(name: "RevenueCat", package: "purchases-ios-spm"),
            ]
        ),
        .target(
            name: "AppCoreKitFeedback",
            dependencies: [
                .product(name: "DeviceKit", package: "DeviceKit", condition: .when(platforms: [.iOS])),
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "AppCoreKitTests",
            dependencies: ["AppCoreKitCore", "AppCoreKitStore"]
        ),
    ]
)
