//
//  ReviewRequestManager.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import Foundation
#if os(iOS)
    import StoreKit
    import UIKit
#endif

/// レビュー依頼に関するイベント
///
/// Analytics への転送はアプリ側の責務のため、コールバックで通知する。
public enum ReviewRequestEvent: Sendable {
    /// レビューダイアログを表示した
    case dialogShown
    /// ユーザーがレビューを受諾した（App Store レビュー画面を表示した）
    case dialogAccepted
}

/// アプリ評価依頼の条件判定と StoreKit 呼び出し
///
/// 対象アクション（共有・保存・エクスポート等）の回数をカウントし、
/// しきい値到達時に一度だけレビューダイアログの表示を依頼する。
///
/// ## 使用例
/// ```swift
/// let manager = ReviewRequestManager(onEvent: { event in
///     switch event {
///     case .dialogShown: firebaseProvider.track(event: .reviewDialogShown)
///     case .dialogAccepted: firebaseProvider.track(event: .reviewDialogAccepted)
///     }
/// })
/// manager.reviewDialogShowHandler = { [weak windowScene] in
///     guard let scene = windowScene else { return }
///     manager.requestAppStoreReview(in: scene)
/// }
/// manager.handleAction()
/// ```
@MainActor
public final class ReviewRequestManager: ObservableObject {
    // MARK: - Configuration

    /// レビュー依頼のしきい値
    private let threshold: Int

    /// デバッグモード（true なら条件無視で毎回ダイアログ表示）
    private let debugMode: Bool

    private let userDefaults: UserDefaults
    private let keyPrefix: String
    private let onEvent: ((ReviewRequestEvent) -> Void)?

    /// レビューダイアログ表示時のカスタムハンドラー（アプリ側の表示制御・テスト用）
    public var reviewDialogShowHandler: (() -> Void)?

    /// - Parameters:
    ///   - threshold: レビュー依頼のしきい値（デフォルト: 5）
    ///   - debugMode: true なら条件無視で毎回ダイアログ表示（デフォルト: false）
    ///   - userDefaults: 永続化先（テスト時は suiteName 付きを注入）
    ///   - keyPrefix: UserDefaults キーの接頭辞（デフォルト: "ReviewRequest"）
    ///   - onEvent: イベント発生時のコールバック（Analytics への転送用）
    public init(
        threshold: Int = 5,
        debugMode: Bool = false,
        userDefaults: UserDefaults = .standard,
        keyPrefix: String = "ReviewRequest",
        onEvent: ((ReviewRequestEvent) -> Void)? = nil,
    ) {
        self.threshold = threshold
        self.debugMode = debugMode
        self.userDefaults = userDefaults
        self.keyPrefix = keyPrefix
        self.onEvent = onEvent
    }

    // MARK: - UserDefaults

    private var actionCountKey: String {
        "\(keyPrefix).ShareCount"
    }

    private var hasShownReviewKey: String {
        "\(keyPrefix).HasShownReview"
    }

    /// 対象アクションの実行回数
    private var actionCount: Int {
        get { userDefaults.integer(forKey: actionCountKey) }
        set { userDefaults.set(newValue, forKey: actionCountKey) }
    }

    /// レビューダイアログ表示済みフラグ
    private var hasShownReview: Bool {
        get { userDefaults.bool(forKey: hasShownReviewKey) }
        set { userDefaults.set(newValue, forKey: hasShownReviewKey) }
    }

    // MARK: - Public Methods

    /// 対象アクション（共有・保存・エクスポート等）発生時の処理
    ///
    /// カウントアップし、条件を満たせば `reviewDialogShowHandler` を実行する。
    public func handleAction() {
        // デバッグモードの場合は条件無視で毎回表示
        if debugMode {
            showReviewDialog()
            return
        }

        actionCount += 1

        if shouldShowReviewDialog() {
            showReviewDialog()
        }
    }

    /// 周期しきい値に到達したか判定
    ///
    /// - レビューダイアログが未表示の場合は false
    /// - アクション回数が threshold の倍数ごとに true（初回レビュー表示と同回は除外）
    ///
    /// インタースティシャル広告の表示タイミング判定などに使用する。
    public func isPeriodicThresholdReached() -> Bool {
        guard hasShownReview else { return false }
        return actionCount % threshold == 0
            && actionCount > threshold
    }

    /// カウント・表示済みフラグ・ハンドラーをリセット（デバッグ用）
    public func reset() {
        actionCount = 0
        hasShownReview = false
        reviewDialogShowHandler = nil
    }

    #if os(iOS)
        /// App Store レビューをリクエストする
        public func requestAppStoreReview(in scene: UIWindowScene) {
            onEvent?(.dialogAccepted)

            AppStore.requestReview(in: scene)
            hasShownReview = true
        }
    #endif

    // MARK: - Private Methods

    /// レビューダイアログ表示条件の判定
    private func shouldShowReviewDialog() -> Bool {
        // 条件1: 規定回数以上のアクションを行っている
        guard actionCount >= threshold else {
            return false
        }

        // 条件2: 過去にレビューダイアログを表示していない
        guard !hasShownReview else {
            return false
        }

        return true
    }

    /// レビューダイアログを表示
    private func showReviewDialog() {
        onEvent?(.dialogShown)

        reviewDialogShowHandler?()
        hasShownReview = true
    }
}
