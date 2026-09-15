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
        @ViewBuilder content: () -> some View,
    ) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            // iOS 27 では safeAreaBar の scroll edge effect の既定が hard 相当になり、
            // 境界線がくっきり出るため、iOS 26 と同じなだらかな見た目に揃える
            scrollEdgeEffectStyle(.soft, for: edge == .top ? .top : .bottom)
                .safeAreaBar(edge: edge, content: content)
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
