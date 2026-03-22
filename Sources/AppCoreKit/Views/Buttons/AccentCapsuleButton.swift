//
//  AccentCapsuleButton.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import SwiftUI

public struct AccentCapsuleButton: View {
    private let title: Text
    private let action: () -> Void
    private let isGreyColor: Bool

    public init(title: Text, isGreyColor: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isGreyColor = isGreyColor
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            contentView
        }
    }

    private var contentView: some View {
        HStack {
            title
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color.white)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            Capsule()
                .fill(isGreyColor ? Color.secondary.opacity(0.6) : Color.accentColor)
        )
    }
}
