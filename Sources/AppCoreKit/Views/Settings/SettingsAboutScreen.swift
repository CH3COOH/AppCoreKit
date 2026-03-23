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
        onAppear: (() -> Void)? = nil
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

            Section {
                if let url = privacyPolicyURL {
                    SettingsLinkRowView(title: privacyPolicyTitle, description: nil) {
                        selectedURL = IdentifiableURL(url: url)
                    }
                }
                if let url = termsOfUseURL {
                    SettingsLinkRowView(title: termsOfUseTitle, description: nil) {
                        selectedURL = IdentifiableURL(url: url)
                    }
                }
            }

            Section {
                if let url = developerURL {
                    SettingsLinkRowView(title: developerTitle, description: developerDescription) {
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
