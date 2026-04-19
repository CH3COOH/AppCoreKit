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
    private let iconSystemName: String?
    private let iconColor: Color?
    private let title: Text
    private let description: Text?
    private let action: () -> Void

    init(
        iconSystemName: String? = nil,
        iconColor: Color? = nil,
        title: Text,
        description: Text? = nil,
        action: @escaping () -> Void,
    ) {
        self.iconSystemName = iconSystemName
        self.iconColor = iconColor
        self.title = title
        self.description = description
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                if let iconSystemName, let iconColor {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6.5)
                            .fill(iconColor)
                            .frame(width: 29, height: 29)
                        Image(systemName: iconSystemName)
                            .font(.system(size: 17))
                            .foregroundStyle(.white)
                    }
                }
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
            .padding(.vertical, 4)
        }
    }
}
