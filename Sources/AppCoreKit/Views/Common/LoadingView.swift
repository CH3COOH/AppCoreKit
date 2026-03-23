//
//  LoadingView.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import SwiftUI

public struct LoadingView: View {
    public init() {}

    public var body: some View {
        ZStack {
            ProgressView()
                .tint(Color.accentColor)
                .progressViewStyle(.circular)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
