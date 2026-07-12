//
//  ReviewRequestManagerTests.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

@testable import AppCoreKit
import Foundation
import Testing

@MainActor
struct ReviewRequestManagerTests {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "AppCoreKitTests.ReviewRequestManager.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test func アクションを実行した回数がカウントされる() {
        let defaults = makeDefaults()
        let manager = ReviewRequestManager(userDefaults: defaults)

        manager.handleAction()
        manager.handleAction()
        manager.handleAction()

        #expect(defaults.integer(forKey: "ReviewRequest.ShareCount") == 3)
    }

    @Test func しきい値到達でレビューダイアログが表示される() {
        let defaults = makeDefaults()
        var shownEvents: [ReviewRequestEvent] = []
        let manager = ReviewRequestManager(
            threshold: 3,
            userDefaults: defaults,
            onEvent: { shownEvents.append($0) },
        )

        var reviewDialogShown = false
        manager.reviewDialogShowHandler = {
            reviewDialogShown = true
        }

        manager.handleAction()
        #expect(reviewDialogShown == false)

        manager.handleAction()
        #expect(reviewDialogShown == false)

        manager.handleAction()
        #expect(reviewDialogShown == true)
        #expect(shownEvents.count == 1)
        #expect(defaults.bool(forKey: "ReviewRequest.HasShownReview") == true)
        #expect(defaults.integer(forKey: "ReviewRequest.ShareCount") == 3)
    }

    @Test func 表示済みの場合は重複表示しない() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: "ReviewRequest.HasShownReview")
        let manager = ReviewRequestManager(threshold: 1, userDefaults: defaults)

        var reviewDialogCallCount = 0
        manager.reviewDialogShowHandler = {
            reviewDialogCallCount += 1
        }

        manager.handleAction()
        manager.handleAction()

        #expect(reviewDialogCallCount == 0)
        #expect(defaults.bool(forKey: "ReviewRequest.HasShownReview") == true)
    }

    @Test func デバッグモードでは条件無視で毎回表示される() {
        let defaults = makeDefaults()
        let manager = ReviewRequestManager(debugMode: true, userDefaults: defaults)

        var reviewDialogCallCount = 0
        manager.reviewDialogShowHandler = {
            reviewDialogCallCount += 1
        }

        manager.handleAction()
        manager.handleAction()

        #expect(reviewDialogCallCount == 2)
    }

    @Test func レビュー未表示の場合_周期しきい値はfalseを返す() {
        let defaults = makeDefaults()
        defaults.set(10, forKey: "ReviewRequest.ShareCount")
        let manager = ReviewRequestManager(threshold: 5, userDefaults: defaults)

        #expect(manager.isPeriodicThresholdReached() == false)
    }

    @Test func 初回レビュー表示と同回の場合_周期しきい値はfalseを返す() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: "ReviewRequest.HasShownReview")
        defaults.set(5, forKey: "ReviewRequest.ShareCount")
        let manager = ReviewRequestManager(threshold: 5, userDefaults: defaults)

        #expect(manager.isPeriodicThresholdReached() == false)
    }

    @Test func レビュー表示済みでしきい値の倍数の場合_周期しきい値はtrueを返す() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: "ReviewRequest.HasShownReview")
        defaults.set(10, forKey: "ReviewRequest.ShareCount")
        let manager = ReviewRequestManager(threshold: 5, userDefaults: defaults)

        #expect(manager.isPeriodicThresholdReached() == true)
    }

    @Test func しきい値の倍数でない場合_周期しきい値はfalseを返す() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: "ReviewRequest.HasShownReview")
        defaults.set(11, forKey: "ReviewRequest.ShareCount")
        let manager = ReviewRequestManager(threshold: 5, userDefaults: defaults)

        #expect(manager.isPeriodicThresholdReached() == false)
    }

    @Test func リセットで全データがクリアされる() {
        let defaults = makeDefaults()
        defaults.set(5, forKey: "ReviewRequest.ShareCount")
        defaults.set(true, forKey: "ReviewRequest.HasShownReview")
        let manager = ReviewRequestManager(userDefaults: defaults)
        manager.reviewDialogShowHandler = {}

        manager.reset()

        #expect(defaults.integer(forKey: "ReviewRequest.ShareCount") == 0)
        #expect(defaults.bool(forKey: "ReviewRequest.HasShownReview") == false)
        #expect(manager.reviewDialogShowHandler == nil)
    }

    @Test func キー接頭辞を変更できる() {
        let defaults = makeDefaults()
        let manager = ReviewRequestManager(userDefaults: defaults, keyPrefix: "MyApp.Review")

        manager.handleAction()

        #expect(defaults.integer(forKey: "MyApp.Review.ShareCount") == 1)
        #expect(defaults.integer(forKey: "ReviewRequest.ShareCount") == 0)
    }
}
