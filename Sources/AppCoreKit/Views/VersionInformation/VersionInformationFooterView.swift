//
//  VersionInformationFooterView.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import SwiftUI

public struct VersionInformationFooterView: View {
    private let isPremium: Bool
    private let subscribeButtonTitle: Text
    private let closeButtonTitle: Text
    private let onSubscribeTapped: () -> Void
    private let onCloseTapped: () -> Void

    public init(
        isPremium: Bool,
        subscribeButtonTitle: Text,
        closeButtonTitle: Text,
        onSubscribeTapped: @escaping () -> Void,
        onCloseTapped: @escaping () -> Void
    ) {
        self.isPremium = isPremium
        self.subscribeButtonTitle = subscribeButtonTitle
        self.closeButtonTitle = closeButtonTitle
        self.onSubscribeTapped = onSubscribeTapped
        self.onCloseTapped = onCloseTapped
    }

    public var body: some View {
        VStack(spacing: 16) {
            if !isPremium {
                AccentCapsuleButton(title: subscribeButtonTitle) {
                    onSubscribeTapped()
                }

                TextAccentButton(title: closeButtonTitle) {
                    onCloseTapped()
                }
            } else {
                AccentCapsuleButton(title: closeButtonTitle) {
                    onCloseTapped()
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }
}
