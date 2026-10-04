# AGENTS.md

このファイルは AI エージェント（Claude Code など）が AppCoreKit で作業する際のガイドラインです。

## プロジェクト概要

- **パッケージ名:** AppCoreKit
- **目的:** HealthTakeout / FourCropper / NSEasyConnect の共通コードを集約する SPM ライブラリ
- **言語:** Swift
- **最小iOS:** 16.0
- **アーキテクチャ:** SPM ライブラリ（.library product）

## ターゲット構成

| ターゲット / product | 中身 | 外部依存 |
|---|---|---|
| `AppCoreKitCore` | UseCase / View / Logger など、外部依存のない共通部品 | なし |
| `AppCoreKitStore` | 課金関連 UseCase | Core、RevenueCat |
| `AppCoreKitFeedback` | フィードバック画面（iOS のみ） | DeviceKit（iOS のみ） |
| `AppCoreKit` | 上の3つを `@_exported import` する全部入りの窓口 | 上の3つ |

- 外部依存を Core に持ち込まない。RevenueCat を使うコードは Store、DeviceKit を使うコードは Feedback に置く
- Feedback は Core に依存していない。Core の型を使う必要が出たら `Package.swift` の依存に `AppCoreKitCore` を追加する
- ローカライズ文字列は、使うターゲットの `Resources/Localizable.xcstrings` に置く（`bundle: .module` はターゲットごとに別の Bundle になる）

## ディレクトリ構成

```
AppCoreKit/
├── Package.swift
├── Sources/
│   ├── AppCoreKit/
│   │   └── AppCoreKit.swift      # Core / Store / Feedback を @_exported import する窓口
│   ├── AppCoreKitCore/
│   │   ├── UseCase/          # UseCaseProtocol など共通プロトコル
│   │   ├── Launch/           # アプリ起動時の共通 UseCase
│   │   ├── Network/          # ネットワーク関連 UseCase
│   │   ├── Review/           # アプリ評価依頼（ReviewRequestManager）
│   │   ├── Logging/          # ログ出力（CustomLogger）
│   │   ├── ViewModel/        # BaseViewModel（画面 ViewModel の基底クラス）
│   │   ├── Resources/        # Localizable.xcstrings（common.*）
│   │   └── Views/            # 共通 SwiftUI View
│   │       ├── Browser/      # SafariViewPresenter(iOS 25 以前のアプリ内ブラウザ表示)
│   │       ├── Buttons/      # AccentCapsuleButton, TextAccentButton
│   │       ├── Common/       # LoadingView, ContentUnavailableViewCompat, SafeAreaBarCompat, AlertDialogItem, UIViewController+SwiftUI
│   │       ├── Launch/       # UpdateRequirementScreen
│   │       ├── Settings/     # SettingsAboutScreen, SettingsAboutItem, SettingsLinkRowView, SettingsListItemView
│   │       └── VersionInformation/ # VersionInformationScreen, UpdateNotesView(更新内容の Markdown 表示)
│   ├── AppCoreKitStore/
│   │   └── Store/            # 課金関連 UseCase（RevenueCat）
│   └── AppCoreKitFeedback/
│       ├── Device/           # デバイス情報ユーティリティ（iOS のみ）
│       ├── Resources/        # Localizable.xcstrings（feedback.*）
│       └── Views/
│           └── Feedback/     # FeedbackScreen（iOS のみ）
└── Tests/
    └── AppCoreKitTests/      # 各モジュールのユニットテスト（Core / Store を @testable import）
```

## 受け入れ条件

**実装完了の条件として、必ずユニットテストを実行し、全テストが PASS すること。**

```bash
# テスト実行コマンド（AppCoreKit ディレクトリで実行）
swift test
```

テストが失敗している状態で実装完了とみなしてはならない。

## コーディング規約

- すべての public API に `public` アクセス修飾子を付与する
- テストフレームワークは Swift Testing (`@Test`) を使用する
- UseCase のテストでは `UserDefaults(suiteName:)` + `removePersistentDomain` で状態を隔離する
- iOS 専用コードはファイル全体を `#if os(iOS)` ... `#endif` で囲む（インライン分岐は避ける）
- `public` init のデフォルト引数から `internal` な型は参照できないため、`nil` + init 内 `??` で解決する

## 命名規則

| 種類 | 規則 | 例 |
|------|------|-----|
| 型 | UpperCamelCase | `CheckVersionUseCase` |
| 変数/関数 | lowerCamelCase | `bundleShortVersion` |
| テスト関数名 | 日本語で条件と期待値を記述 | `バージョンアップ後の初回起動_showVersionInformationを返す` |

## 新しい UseCase を追加する際のルール

1. 外部依存に応じて `Sources/AppCoreKitCore/` / `Sources/AppCoreKitStore/` / `Sources/AppCoreKitFeedback/` の適切なサブディレクトリに配置する
2. `UseCaseProtocol` に準拠する
3. テスタブルにするため、外部依存（UserDefaults 等）はイニシャライザで注入する
4. `Tests/AppCoreKitTests/` に対応するテストファイルを作成する
5. `swift test` で全テストが PASS することを確認する

## 新しい SwiftUI View を追加する際のルール

1. View は Presentational Component として実装し、UseCase を直接持たない（すべてのデータは init で注入）
2. iOS 専用 View はファイル先頭で `#if os(iOS)` で囲み、ファイル末尾で `#endif` を閉じる
3. macOS 非対応の API（`navigationBarTitleDisplayMode` 等）は `#if os(iOS)` ガードを使用する
4. Toolbar の placement は `.cancellationAction` / `.confirmationAction` を使用する（クロスプラットフォーム対応）

## 依存ライブラリ

| ライブラリ | 用途 | プラットフォーム | 使うターゲット |
|---|---|---|---|
| [RevenueCat](https://github.com/RevenueCat/purchases-ios-spm) | 課金・サブスクリプション管理 | iOS / macOS | `AppCoreKitStore` |
| [DeviceKit](https://github.com/devicekit/DeviceKit) | デバイスモデル名の人間可読な取得 | iOS のみ | `AppCoreKitFeedback` |
