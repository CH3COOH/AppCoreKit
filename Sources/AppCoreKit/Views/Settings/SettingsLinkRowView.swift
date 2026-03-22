//
//  SettingsLinkRowView.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import SwiftUI

struct SettingsLinkRowView: View {
    private let title: Text
    private let description: Text?
    private let action: () -> Void

    init(title: Text, description: Text? = nil, action: @escaping () -> Void) {
        self.title = title
        self.description = description
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    title
                        .foregroundStyle(Color.primary)
                    if let description {
                        description
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.secondary)
                    .font(.system(size: 13, weight: .semibold))
            }
        }
    }
}
