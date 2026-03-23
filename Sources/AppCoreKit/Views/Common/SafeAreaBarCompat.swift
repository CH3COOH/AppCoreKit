//
//  SafeAreaBarCompat.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import SwiftUI

public extension View {
    @ViewBuilder
    func safeAreaBarCompat(
        edge: VerticalEdge,
        showsDivider: Bool = true,
        @ViewBuilder content: () -> some View
    ) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            safeAreaBar(edge: edge, content: content)
        } else {
            if showsDivider {
                safeAreaInset(edge: .bottom) {
                    VStack(spacing: 16) {
                        Divider()
                        content()
                    }
                    .background(.regularMaterial)
                }
            } else {
                safeAreaInset(edge: .bottom) {
                    content()
                }
            }
        }
    }
}
