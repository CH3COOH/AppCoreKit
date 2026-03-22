# AGENTS.md

このファイルは AI エージェント（Claude Code など）が AppCoreKit で作業する際のガイドラインです。

## プロジェクト概要

- **パッケージ名:** AppCoreKit
- **目的:** HealthTakeout / FourCropper / NSEasyConnect の共通コードを集約する SPM ライブラリ
- **言語:** Swift
- **最小iOS:** 16.0
- **アーキテクチャ:** SPM ライブラリ（.library product）

## ディレクトリ構成

```
AppCoreKit/
├── Package.swift
├── Sources/
│   └── AppCoreKit/
│       ├── UseCase/          # UseCaseProtocol など共通プロトコル
│       ├── Launch/           # アプリ起動時の共通 UseCase
│       └── Views/            # 共通 SwiftUI View（将来追加予定）
└── Tests/
    └── AppCoreKitTests/      # 各モジュールのユニットテスト
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

## 命名規則

| 種類 | 規則 | 例 |
|------|------|-----|
| 型 | UpperCamelCase | `CheckVersionUseCase` |
| 変数/関数 | lowerCamelCase | `bundleShortVersion` |
| テスト関数名 | 日本語で条件と期待値を記述 | `バージョンアップ後の初回起動_showVersionInformationを返す` |

## 新しい UseCase を追加する際のルール

1. `Sources/AppCoreKit/` の適切なサブディレクトリに配置する
2. `UseCaseProtocol` に準拠する
3. テスタブルにするため、外部依存（UserDefaults 等）はイニシャライザで注入する
4. `Tests/AppCoreKitTests/` に対応するテストファイルを作成する
5. `swift test` で全テストが PASS することを確認する
