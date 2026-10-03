//
//  SettingsAboutScreen.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import SwiftUI

public struct SettingsAboutScreen: View {
    private let navigationTitle: String
    private let appIconImage: Image
    private let appName: String
    private let appVersion: String
    private let privacyPolicyTitle: Text
    private let termsOfUseTitle: Text
    private let developerTitle: Text
    private let developerDescription: Text?
    private let privacyPolicyURL: URL?
    private let termsOfUseURL: URL?
    private let developerURL: URL?
    private let versionHistoryTitle: String?
    private let versionHistoryDestination: AnyView?
    private let onAppear: (() -> Void)?

    @State private var selectedURL: IdentifiableURL?

    private struct IdentifiableURL: Identifiable {
        let id = UUID()
        let url: URL
    }

    public init(
        navigationTitle: String,
        appIconImage: Image,
        appName: String,
        appVersion: String,
        privacyPolicyTitle: Text,
        termsOfUseTitle: Text,
        developerTitle: Text,
        developerDescription: Text? = nil,
        privacyPolicyURL: URL? = nil,
        termsOfUseURL: URL? = nil,
        developerURL: URL? = nil,
        versionHistoryTitle: String? = nil,
        versionHistoryDestination: AnyView? = nil,
        onAppear: (() -> Void)? = nil,
    ) {
        self.navigationTitle = navigationTitle
        self.appIconImage = appIconImage
        self.appName = appName
        self.appVersion = appVersion
        self.privacyPolicyTitle = privacyPolicyTitle
        self.termsOfUseTitle = termsOfUseTitle
        self.developerTitle = developerTitle
        self.developerDescription = developerDescription
        self.privacyPolicyURL = privacyPolicyURL
        self.termsOfUseURL = termsOfUseURL
        self.developerURL = developerURL
        self.versionHistoryTitle = versionHistoryTitle
        self.versionHistoryDestination = versionHistoryDestination
        self.onAppear = onAppear
    }

    public var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .center, spacing: 8) {
                        appIconImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        Text(appName)
                            .foregroundStyle(Color.accentColor)
                            .font(.system(size: 30, weight: .bold))

                        Text(appVersion)
                            .foregroundStyle(Color.secondary)
                            .font(.system(size: 15, weight: .regular))
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                }
            }

            if let title = versionHistoryTitle, let destination = versionHistoryDestination {
                Section {
                    NavigationLink {
                        destination
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6.5)
                                    .fill(SettingsIconColor.system)
                                    .frame(width: 29, height: 29)
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 17))
                                    .foregroundStyle(.white)
                            }
                            Text(title)
                                .foregroundStyle(Color.primary)
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section {
                if let url = privacyPolicyURL {
                    SettingsLinkRowView(
                        iconSystemName: "hand.raised.fill",
                        iconColor: SettingsIconColor.info,
                        title: privacyPolicyTitle,
                    ) {
                        selectedURL = IdentifiableURL(url: url)
                    }
                }
                if let url = termsOfUseURL {
                    SettingsLinkRowView(
                        iconSystemName: "doc.text.fill",
                        iconColor: SettingsIconColor.info,
                        title: termsOfUseTitle,
                    ) {
                        selectedURL = IdentifiableURL(url: url)
                    }
                }
            }

            Section {
                if let url = developerURL {
                    SettingsLinkRowView(
                        iconSystemName: "globe",
                        iconColor: SettingsIconColor.info,
                        title: developerTitle,
                        description: developerDescription,
                    ) {
                        selectedURL = IdentifiableURL(url: url)
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(item: $selectedURL) { item in
            SafariView(url: item.url)
                .ignoresSafeArea()
        }
        #endif
        .navigationTitle(navigationTitle)
        .onAppear {
            onAppear?()
        }
    }
}

public extension SettingsAboutScreen {
    init(
        navigationTitle: String,
        appIconImage: Image,
        appName: String,
        appVersion: String,
        privacyPolicyTitle: Text,
        termsOfUseTitle: Text,
        developerTitle: Text,
        developerDescription: Text? = nil,
        privacyPolicyURL: URL? = nil,
        termsOfUseURL: URL? = nil,
        developerURL: URL? = nil,
        versionHistoryTitle: String,
        @ViewBuilder versionHistoryDestination: () -> some View,
        onAppear: (() -> Void)? = nil,
    ) {
        self.init(
            navigationTitle: navigationTitle,
            appIconImage: appIconImage,
            appName: appName,
            appVersion: appVersion,
            privacyPolicyTitle: privacyPolicyTitle,
            termsOfUseTitle: termsOfUseTitle,
            developerTitle: developerTitle,
            developerDescription: developerDescription,
            privacyPolicyURL: privacyPolicyURL,
            termsOfUseURL: termsOfUseURL,
            developerURL: developerURL,
            versionHistoryTitle: versionHistoryTitle,
            versionHistoryDestination: AnyView(versionHistoryDestination()),
            onAppear: onAppear,
        )
    }
}
