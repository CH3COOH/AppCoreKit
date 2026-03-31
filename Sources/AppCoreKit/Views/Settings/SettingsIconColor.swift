//
//  SettingsIconColor.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import SwiftUI

/// 設定画面アイコンのセマンティックカラー定数
///
/// iOS 標準設定アプリの配色規則に基づき、機能カテゴリごとに色を定義する。
public enum SettingsIconColor {
    /// 有料機能: オレンジ系 #FF9500
    public static let premium = Color(red: 1.0, green: 0.58, blue: 0.0)

    /// フォーム送信（お問い合わせ・不具合報告）: パープル系 #AF52DE
    public static let form = Color(red: 0.69, green: 0.32, blue: 0.87)

    /// システム・更新・リードオンリーコンテンツ: ブルー系 #007AFF
    public static let system = Color(red: 0.0, green: 0.48, blue: 1.0)

    /// 編集・作成機能: グリーン系 #34C759
    public static let edit = Color(red: 0.2, green: 0.78, blue: 0.35)

    /// 情報・その他: グレー系 #8E8E93
    public static let info = Color(red: 0.56, green: 0.56, blue: 0.58)
}
