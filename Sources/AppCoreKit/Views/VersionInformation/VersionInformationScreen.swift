//
//  VersionInformationScreen.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import SwiftUI

public struct VersionInformationScreen: View {
    private let navigationTitle: String
    private let appName: String
    private let appIconImage: Image
    private let descText: String
    private let updateText: String
    private let isLoaded: Bool
    private let isPremium: Bool
    private let subscribeButtonTitle: Text
    private let closeButtonTitle: Text
    private let onSubscribeTapped: (() -> Void)?
    private let onCloseTapped: (() -> Void)?

    public init(
        navigationTitle: String,
        appName: String,
        appIconImage: Image,
        descText: String,
        updateText: String,
        isLoaded: Bool,
        isPremium: Bool = false,
        subscribeButtonTitle: Text = Text(""),
        closeButtonTitle: Text = Text(""),
        onSubscribeTapped: (() -> Void)? = nil,
        onCloseTapped: (() -> Void)? = nil,
    ) {
        self.navigationTitle = navigationTitle
        self.appName = appName
        self.appIconImage = appIconImage
        self.descText = descText
        self.updateText = updateText
        self.isLoaded = isLoaded
        self.isPremium = isPremium
        self.subscribeButtonTitle = subscribeButtonTitle
        self.closeButtonTitle = closeButtonTitle
        self.onSubscribeTapped = onSubscribeTapped
        self.onCloseTapped = onCloseTapped
    }

    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            if isLoaded {
                VStack(spacing: 0) {
                    VersionInformationHeaderView(text: descText)

                    Divider()

                    ScrollView {
                        Text(updateText)
                            .font(.system(size: 13, weight: .regular))
                            .multilineTextAlignment(.leading)
                            .lineSpacing(1.2)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else {
                LoadingView()
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationTitle(navigationTitle)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    appIconImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Text(appName)
                        .foregroundStyle(Color.accentColor)
                        .font(.system(size: 24, weight: .bold))
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }

    public var body: some View {
        if let onCloseTapped {
            mainContent
                .safeAreaBarCompat(edge: .bottom, showsDivider: true) {
                    VersionInformationFooterView(
                        isPremium: isPremium,
                        subscribeButtonTitle: subscribeButtonTitle,
                        closeButtonTitle: closeButtonTitle,
                        onSubscribeTapped: onSubscribeTapped ?? {},
                        onCloseTapped: onCloseTapped,
                    )
                }
        } else {
            mainContent
        }
    }
}
