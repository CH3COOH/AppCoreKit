//
//  FeedbackScreen.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

#if os(iOS)
import MessageUI
import SwiftUI

public struct FeedbackScreen: View {
    private let navigationTitle: String
    private let topicsSectionTitle: Text
    private let topicsRowTitle: Text
    private let descriptionPlaceholder: String
    private let basicInfoSectionTitle: Text
    private let deviceLabel: Text
    private let osVersionLabel: Text
    private let appNameLabel: Text
    private let appVersionLabel: Text
    private let sendMailButtonTitle: Text
    private let cancelButtonTitle: Text
    private let cannotSendMailTitle: Text
    private let cannotSendMailMessage: Text
    private let mailSendFailedMessage: Text
    private let discardChangesTitle: Text
    private let discardChangesMessage: Text
    private let discardButtonTitle: Text
    private let keepEditingButtonTitle: Text
    private let topics: [String]
    private let toRecipients: [String]
    private let ccRecipients: [String]
    private let deviceInfo: String
    private let osVersion: String
    private let appName: String
    private let appVersion: String
    private let footerText: String?
    private let onCancel: () -> Void
    private let onSent: (() -> Void)?

    @State private var selectedTopicIndex: Int
    @State private var descriptionText: String = ""
    @State private var showMailCompose: Bool = false
    @State private var showCannotSendMailAlert: Bool = false
    @State private var showMailSendFailedAlert: Bool = false
    @State private var showDiscardConfirmation: Bool = false

    public init(
        navigationTitle: String? = nil,
        topicsSectionTitle: Text? = nil,
        topicsRowTitle: Text? = nil,
        descriptionPlaceholder: String? = nil,
        basicInfoSectionTitle: Text? = nil,
        deviceLabel: Text? = nil,
        osVersionLabel: Text? = nil,
        appNameLabel: Text? = nil,
        appVersionLabel: Text? = nil,
        sendMailButtonTitle: Text? = nil,
        cancelButtonTitle: Text? = nil,
        cannotSendMailTitle: Text? = nil,
        cannotSendMailMessage: Text? = nil,
        mailSendFailedMessage: Text? = nil,
        discardChangesTitle: Text? = nil,
        discardChangesMessage: Text? = nil,
        discardButtonTitle: Text? = nil,
        keepEditingButtonTitle: Text? = nil,
        topics: [String]? = nil,
        initialTopic: String? = nil,
        toRecipients: [String],
        ccRecipients: [String] = [],
        deviceInfo: String? = nil,
        osVersion: String? = nil,
        appName: String,
        appVersion: String,
        footerText: String? = nil,
        onCancel: @escaping () -> Void,
        onSent: (() -> Void)? = nil,
    ) {
        let resolvedTopics = topics ?? FeedbackTopic.allCases.map(\.localizedName)
        let initialIndex = initialTopic.flatMap { resolvedTopics.firstIndex(of: $0) } ?? 0
        _selectedTopicIndex = State(initialValue: initialIndex)
        self.navigationTitle = navigationTitle ?? LocalizedString.navigationTitle
        self.topicsSectionTitle = topicsSectionTitle ?? Text(verbatim: LocalizedString.topicsSectionTitle)
        self.topicsRowTitle = topicsRowTitle ?? Text(verbatim: LocalizedString.topicsRowTitle)
        self.descriptionPlaceholder = descriptionPlaceholder ?? LocalizedString.descriptionPlaceholder
        self.basicInfoSectionTitle = basicInfoSectionTitle ?? Text(verbatim: LocalizedString.basicInfoSectionTitle)
        self.deviceLabel = deviceLabel ?? Text(verbatim: LocalizedString.deviceLabel)
        self.osVersionLabel = osVersionLabel ?? Text(verbatim: LocalizedString.osVersionLabel)
        self.appNameLabel = appNameLabel ?? Text(verbatim: LocalizedString.appNameLabel)
        self.appVersionLabel = appVersionLabel ?? Text(verbatim: LocalizedString.appVersionLabel)
        self.sendMailButtonTitle = sendMailButtonTitle ?? Text(verbatim: LocalizedString.sendMailButtonTitle)
        self.cancelButtonTitle = cancelButtonTitle ?? Text(verbatim: LocalizedString.cancelButtonTitle)
        self.cannotSendMailTitle = cannotSendMailTitle ?? Text(verbatim: LocalizedString.cannotSendMailTitle)
        self.cannotSendMailMessage = cannotSendMailMessage ?? Text(verbatim: LocalizedString.cannotSendMailMessage)
        self.mailSendFailedMessage = mailSendFailedMessage ?? Text(verbatim: LocalizedString.mailSendFailedMessage)
        self.discardChangesTitle = discardChangesTitle ?? Text(verbatim: LocalizedString.discardChangesTitle)
        self.discardChangesMessage = discardChangesMessage ?? Text(verbatim: LocalizedString.discardChangesMessage)
        self.discardButtonTitle = discardButtonTitle ?? Text(verbatim: LocalizedString.discardButtonTitle)
        self.keepEditingButtonTitle = keepEditingButtonTitle ?? Text(verbatim: LocalizedString.keepEditingButtonTitle)
        self.topics = resolvedTopics
        self.toRecipients = toRecipients
        self.ccRecipients = ccRecipients
        self.deviceInfo = deviceInfo ?? DeviceInfoProvider.deviceModel
        self.osVersion = osVersion ?? DeviceInfoProvider.osVersion
        self.appName = appName
        self.appVersion = appVersion
        self.footerText = footerText ?? LocalizedString.footerText
        self.onCancel = onCancel
        self.onSent = onSent
    }

    public var body: some View {
        List {
            Section(header: topicsSectionTitle) {
                Picker(selection: $selectedTopicIndex) {
                    ForEach(topics.indices, id: \.self) { index in
                        Text(topics[index]).tag(index)
                    }
                } label: {
                    topicsRowTitle
                }

                ZStack(alignment: .topLeading) {
                    if descriptionText.isEmpty {
                        Text(descriptionPlaceholder)
                            .foregroundStyle(Color.secondary)
                            .font(.system(size: 16))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $descriptionText)
                        .font(.system(size: 16))
                        .frame(minHeight: 88)
                }
            }

            Section(header: basicInfoSectionTitle) {
                InfoRow(label: deviceLabel, value: deviceInfo)
                InfoRow(label: osVersionLabel, value: osVersion)
                InfoRow(label: appNameLabel, value: appName)
                InfoRow(label: appVersionLabel, value: appVersion)
            }

            if let footerText {
                Section {
                    Text(footerText)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.large)
        .interactiveDismissDisabled(!descriptionText.isEmpty)
        .sheet(isPresented: $showMailCompose) {
            MailComposeView(
                subject: mailSubject,
                body: mailBody,
                toRecipients: toRecipients,
                ccRecipients: ccRecipients,
            ) { result in
                showMailCompose = false
                switch result {
                case .sent:
                    onSent?()
                case .failed:
                    showMailSendFailedAlert = true
                default:
                    break
                }
            }
            .ignoresSafeArea()
        }
        .navigationTitle(navigationTitle)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Group {
                    if #available(iOS 26.0, *) {
                        Button(role: .cancel, action: onCancelTapped)
                    } else {
                        Button(action: onCancelTapped) {
                            cancelButtonTitle
                        }
                    }
                }
                .confirmationDialog(discardChangesTitle, isPresented: $showDiscardConfirmation, titleVisibility: .visible) {
                    Button(role: .destructive, action: onCancel) {
                        discardButtonTitle
                    }
                    Button(role: .cancel, action: {}) {
                        keepEditingButtonTitle
                    }
                } message: {
                    discardChangesMessage
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(action: onSendTapped) {
                    sendMailButtonTitle.fontWeight(.semibold)
                }
            }
        }
        .alert(cannotSendMailTitle, isPresented: $showCannotSendMailAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            cannotSendMailMessage
        }
        .alert(Text(verbatim: ""), isPresented: $showMailSendFailedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            mailSendFailedMessage
        }
    }

    private struct InfoRow: View {
        let label: Text
        let value: String

        var body: some View {
            HStack {
                label
                Spacer()
                Text(value)
                    .foregroundStyle(Color.secondary)
            }
        }
    }

    private var mailSubject: String {
        "\(appName): \(topics[selectedTopicIndex])"
    }

    private var mailBody: String {
        "\(descriptionText)\n\n\nDevice: \(deviceInfo)\niOS: \(osVersion)\nApp: \(appName)\nVersion: \(appVersion)"
    }

    private func onCancelTapped() {
        if descriptionText.isEmpty {
            onCancel()
        } else {
            showDiscardConfirmation = true
        }
    }

    private func onSendTapped() {
        guard MFMailComposeViewController.canSendMail() else {
            showCannotSendMailAlert = true
            return
        }
        showMailCompose = true
    }
}

private enum LocalizedString {
    static let navigationTitle = String(localized: "feedback.navigation_title", bundle: .module)
    static let topicsSectionTitle = String(localized: "feedback.topics_section_title", bundle: .module)
    static let topicsRowTitle = String(localized: "feedback.topics_row_title", bundle: .module)
    static let descriptionPlaceholder = String(localized: "feedback.description_placeholder", bundle: .module)
    static let basicInfoSectionTitle = String(localized: "feedback.basic_info_section_title", bundle: .module)
    static let deviceLabel = String(localized: "feedback.device_label", bundle: .module)
    static let osVersionLabel = String(localized: "feedback.os_version_label", bundle: .module)
    static let appNameLabel = String(localized: "feedback.app_name_label", bundle: .module)
    static let appVersionLabel = String(localized: "feedback.app_version_label", bundle: .module)
    static let sendMailButtonTitle = String(localized: "feedback.send_mail_button", bundle: .module)
    static let cancelButtonTitle = String(localized: "feedback.cancel_button", bundle: .module)
    static let cannotSendMailTitle = String(localized: "feedback.cannot_send_mail_title", bundle: .module)
    static let cannotSendMailMessage = String(localized: "feedback.cannot_send_mail_message", bundle: .module)
    static let mailSendFailedMessage = String(localized: "feedback.mail_send_failed_message", bundle: .module)
    static let discardChangesTitle = String(localized: "feedback.discard_changes_title", bundle: .module)
    static let discardChangesMessage = String(localized: "feedback.discard_changes_message", bundle: .module)
    static let discardButtonTitle = String(localized: "feedback.discard_button", bundle: .module)
    static let keepEditingButtonTitle = String(localized: "feedback.keep_editing_button", bundle: .module)
    static let footerText = String(localized: "feedback.footer_text", bundle: .module)
}
#endif
