//
//  TextAccentButton.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import SwiftUI

public struct TextAccentButton: View {
    private let title: Text
    private let action: () -> Void

    public init(title: Text, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            title
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color.accentColor)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
        }
    }
}
