//
//  ContentUnavailableViewCompat.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import SwiftUI

/// iOS 16 / macOS 13 互換の ContentUnavailableView コンポーネント
/// iOS 17 / macOS 14 で導入された ContentUnavailableView の機能を旧 OS でも使用可能にする
public struct ContentUnavailableViewCompat<LabelContent: View, DescriptionContent: View, ActionsContent: View>: View {
    private let labelContent: LabelContent
    private let descriptionContent: DescriptionContent?
    private let actionsContent: ActionsContent?

    public var body: some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            ContentUnavailableView {
                labelContent
            } description: {
                descriptionContent
            } actions: {
                actionsContent
            }
        } else {
            VStack(spacing: 16) {
                labelContent
                    .font(.headline)
                    .foregroundColor(.primary)

                if let descriptionContent {
                    descriptionContent
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                if let actionsContent {
                    actionsContent
                }
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Initializers

public extension ContentUnavailableViewCompat where DescriptionContent == EmptyView, ActionsContent == EmptyView {
    init(@ViewBuilder label: () -> LabelContent) {
        labelContent = label()
        descriptionContent = nil
        actionsContent = nil
    }
}

public extension ContentUnavailableViewCompat where ActionsContent == EmptyView {
    init(
        @ViewBuilder label: () -> LabelContent,
        @ViewBuilder description: () -> DescriptionContent,
    ) {
        labelContent = label()
        descriptionContent = description()
        actionsContent = nil
    }
}

public extension ContentUnavailableViewCompat where DescriptionContent == EmptyView {
    init(
        @ViewBuilder label: () -> LabelContent,
        @ViewBuilder actions: () -> ActionsContent,
    ) {
        labelContent = label()
        descriptionContent = nil
        actionsContent = actions()
    }
}

public extension ContentUnavailableViewCompat {
    init(
        @ViewBuilder label: () -> LabelContent,
        @ViewBuilder description: () -> DescriptionContent,
        @ViewBuilder actions: () -> ActionsContent,
    ) {
        labelContent = label()
        descriptionContent = description()
        actionsContent = actions()
    }
}

// MARK: - Preset Initializers

public extension ContentUnavailableViewCompat where LabelContent == Label<Text, Image>, DescriptionContent == Text, ActionsContent == EmptyView {
    init(title: String, systemImage: String, description: String) {
        labelContent = Label(title, systemImage: systemImage)
        descriptionContent = Text(description)
        actionsContent = nil
    }
}

public extension ContentUnavailableViewCompat where LabelContent == Label<Text, Image>, DescriptionContent == Text {
    init(
        title: String,
        systemImage: String,
        description: String,
        @ViewBuilder actions: () -> ActionsContent,
    ) {
        labelContent = Label(title, systemImage: systemImage)
        descriptionContent = Text(description)
        actionsContent = actions()
    }
}
