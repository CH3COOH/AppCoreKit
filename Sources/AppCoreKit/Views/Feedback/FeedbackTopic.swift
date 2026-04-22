//
//  FeedbackTopic.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

public enum FeedbackTopic: CaseIterable {
    case featureRequest
    case bugReport
    case question
    case businessInquiry
    case mediaPress
    case other
}

extension FeedbackTopic {
    public var localizedName: String {
        switch self {
        case .featureRequest: LocalizedString.topicFeatureRequest
        case .bugReport: LocalizedString.topicBugReport
        case .question: LocalizedString.topicQuestion
        case .businessInquiry: LocalizedString.topicBusinessInquiry
        case .mediaPress: LocalizedString.topicMediaPress
        case .other: LocalizedString.topicOther
        }
    }
}

private enum LocalizedString {
    static let topicBugReport = String(localized: "feedback.topic.bug_report", bundle: .module)
    static let topicFeatureRequest = String(localized: "feedback.topic.feature_request", bundle: .module)
    static let topicQuestion = String(localized: "feedback.topic.question", bundle: .module)
    static let topicBusinessInquiry = String(localized: "feedback.topic.business_inquiry", bundle: .module)
    static let topicMediaPress = String(localized: "feedback.topic.media_press", bundle: .module)
    static let topicOther = String(localized: "feedback.topic.other", bundle: .module)
}
