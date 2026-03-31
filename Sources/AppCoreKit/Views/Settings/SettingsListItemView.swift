//
//  SettingsListItemView.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import SwiftUI

/// 設定画面のリスト行ビュー
///
/// iOS 標準設定アプリ風の角丸カラー背景付きアイコンと、タイトル・説明テキストを表示する。
public struct SettingsListItemView: View {
    private let image: Image?
    private let backgroundColor: Color?
    private let title: Text
    private let description: Text?
    private let action: (() -> Void)?

    public init(
        image: Image? = nil,
        backgroundColor: Color? = nil,
        title: Text,
        description: Text? = nil,
        action: (() -> Void)? = nil
    ) {
        self.image = image
        self.backgroundColor = backgroundColor
        self.title = title
        self.description = description
        self.action = action
    }

    public var body: some View {
        ZStack {
            if let action {
                Button(action: action) {
                    EmptyView()
                }
            }

            HStack(spacing: 16) {
                if let image {
                    if let backgroundColor {
                        // iOS 標準風: 角丸カラー背景付きアイコン（29x29pt、コーナー半径 6.5）
                        ZStack {
                            RoundedRectangle(cornerRadius: 6.5)
                                .fill(backgroundColor)
                                .frame(width: 29, height: 29)
                            image
                                .font(.system(size: 17))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 29)
                    } else {
                        image
                            .font(.system(size: 28))
                            .foregroundStyle(Color.secondary)
                            .frame(width: 32)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    title
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Color.primary)

                    if let description {
                        description
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(Color.secondary)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.secondary)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.vertical, 4)
        }
    }
}
