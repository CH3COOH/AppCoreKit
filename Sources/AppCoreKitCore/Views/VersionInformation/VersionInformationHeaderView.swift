//
//  VersionInformationHeaderView.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import SwiftUI

public struct VersionInformationHeaderView: View {
    private let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(text)
                    .font(.system(size: 17, weight: .regular))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(1.2)

                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}
