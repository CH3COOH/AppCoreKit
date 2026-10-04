//
//  SettingsAboutItem.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import SwiftUI

/// `SettingsAboutScreen` にアプリ側から追加する行(アイコン・タイトル・説明・リンク)。
/// 今は `credits` として開発者セクションに並べ、アプリアイコンの制作者・イラストレーター・協力者などの表示に使う。
/// 他のセクションに行を足せるようにするときも、この型を使う。
public struct SettingsAboutItem {
    let iconSystemName: String
    let iconColor: Color
    let title: Text
    let description: Text?
    let url: URL?

    /// - Parameters:
    ///   - iconSystemName: 行の左に出す SF Symbols の名前
    ///   - iconColor: アイコン背景の色
    ///   - title: 行のタイトル(例:「アプリアイコン制作」)
    ///   - description: 名前など、タイトルの下に小さく出す文字列
    ///   - url: タップしたときに開くページ。nil ならタップできない行になる
    public init(
        iconSystemName: String = "person.fill",
        iconColor: Color = SettingsIconColor.info,
        title: Text,
        description: Text? = nil,
        url: URL? = nil,
    ) {
        self.iconSystemName = iconSystemName
        self.iconColor = iconColor
        self.title = title
        self.description = description
        self.url = url
    }
}
