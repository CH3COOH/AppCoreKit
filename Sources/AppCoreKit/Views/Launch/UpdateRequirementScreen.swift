//
//  UpdateRequirementScreen.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import SwiftUI

public struct UpdateRequirementScreen: View {
    private let title: Text
    private let message: Text
    private let buttonTitle: Text
    private let iconName: String
    private let onOpenAppStore: () -> Void
    private let onAppear: (() -> Void)?

    public init(
        title: Text,
        message: Text,
        buttonTitle: Text,
        iconName: String = "arrow.up.circle.fill",
        onOpenAppStore: @escaping () -> Void,
        onAppear: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.iconName = iconName
        self.onOpenAppStore = onOpenAppStore
        self.onAppear = onAppear
    }

    public var body: some View {
        ContentUnavailableViewCompat {
            Label { title } icon: { Image(systemName: iconName) }
        } description: {
            message
        } actions: {
            Button(action: onOpenAppStore) {
                buttonTitle
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
        }
        .onAppear {
            onAppear?()
        }
    }
}

#Preview {
    UpdateRequirementScreen(
        title: Text("アップデートが必要です"),
        message: Text("最新バージョンのアプリをご利用ください。\nApp Storeからアップデートできます。"),
        buttonTitle: Text("App Storeを開く"),
        iconName: "arrow.down.app.dashed.trianglebadge.exclamationmark",
        onOpenAppStore: {}
    )
}
