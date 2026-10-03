//
//  PurchaseStateStore.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import Foundation

/// 課金状態（サブスクリプション・買い切り）の管理
///
/// 最後にサーバーから取得できた課金状態と、その取得日時（`verifiedAt`）を
/// UserDefaults に永続化する。サブスクリプションと買い切りプランを区別せず、
/// どちらも「最後に確認できた結果」として同じ仕組みで扱う。
///
/// 課金状態の確認は毎回おこなうこと。確認に失敗したときだけ、
/// 永続化された結果をそのまま使う。
///
/// ## 信頼期間
///
/// 返金や解約はサーバー側で反映されるため、オフラインのままでは検知できない。
/// そこで、確認できない状態が続いた場合にいつまで前回の結果を信じるかを
/// `trustDuration` で決める。`verifiedAt` から `trustDuration` を過ぎると
/// `isPurchased` は false になる。
///
/// サブスクリプションは有効期限（`expireDate`）も併せて判定するため、
/// 「有効期限内」かつ「信頼期間内」の場合にのみ課金中となる。
///
/// ## 使用例
/// ```swift
/// // 起動時・機能利用前に毎回確認する
/// let result = await CheckPurchaseUseCase().execute(.init())
/// switch result {
/// case let .success(state):
///     purchaseState.apply(state)
/// case .failure:
///     // 取得できなかっただけなので、永続化された結果をそのまま使う
///     break
/// }
///
/// if purchaseState.isPurchased {
///     // プレミアム機能を解放
/// }
/// ```
@MainActor
public final class PurchaseStateStore: ObservableObject {
    /// 最後にサーバーから取得できた課金状態（永続化される）
    ///
    /// 一度も確認できていない場合は nil。
    @Published public private(set) var lastKnownState: CheckPurchaseUseCase.UseCaseResult?

    /// `lastKnownState` を取得できた日時（永続化される）
    @Published public private(set) var verifiedAt: Date?

    /// 課金判定を上書きするフック（デバッグ用）
    ///
    /// non-nil を返すとその値を `isPurchased` の結果として採用する。
    /// アプリ側で `#if DEBUG` ガード付きで設定すること。
    public var isPurchasedOverride: (() -> Bool?)?

    private let userDefaults: UserDefaults
    private let isPremiumKey: String
    private let expireDateKey: String
    private let verifiedAtKey: String
    private let trustDuration: TimeInterval

    /// - Parameters:
    ///   - userDefaults: 永続化先（テスト時は suiteName 付きを注入）
    ///   - keyPrefix: 永続化に使う UserDefaults キーの接頭辞
    ///   - legacyLifetimeCachedAtKey: 買い切りキャッシュ日時のみを保存していた
    ///     旧バージョンのキー。移行に成功したら削除する
    ///   - trustDuration: 課金状態を確認できないときに前回の結果を信じる期間（デフォルト: 30日）
    public init(
        userDefaults: UserDefaults = .standard,
        keyPrefix: String = "purchase_state",
        legacyLifetimeCachedAtKey: String = "lifetime_cached_at",
        trustDuration: TimeInterval = 30 * 24 * 60 * 60,
    ) {
        self.userDefaults = userDefaults
        isPremiumKey = "\(keyPrefix)_is_premium"
        expireDateKey = "\(keyPrefix)_expire_date"
        verifiedAtKey = "\(keyPrefix)_verified_at"
        self.trustDuration = trustDuration

        if userDefaults.object(forKey: isPremiumKey) != nil,
           let storedVerifiedAt = userDefaults.object(forKey: verifiedAtKey) as? Date
        {
            let expireDate = userDefaults.object(forKey: expireDateKey) as? Date
            lastKnownState = userDefaults.bool(forKey: isPremiumKey) ? .premium(expireDate: expireDate) : .free
            verifiedAt = storedVerifiedAt
        } else if let cachedAt = userDefaults.object(forKey: legacyLifetimeCachedAtKey) as? Date {
            // 買い切りキャッシュ日時しか保存していなかったバージョンからの移行。
            // このキーは買い切り購入者にのみ書き込まれていたため、
            // 有効期限なしのプレミアムを最後に確認できた結果として扱う
            lastKnownState = .premium(expireDate: nil)
            verifiedAt = cachedAt
            persist()
            userDefaults.removeObject(forKey: legacyLifetimeCachedAtKey)
        }
    }

    /// 課金ユーザーか？
    ///
    /// 最後に確認できた結果がプレミアムであり、かつ信頼期間内である場合に true を返す。
    /// サブスクリプションの場合は有効期限内であることも条件になる。
    public var isPurchased: Bool {
        if let override = isPurchasedOverride?() {
            return override
        }

        guard case let .premium(expireDate) = lastKnownState, isTrusted else {
            return false
        }

        guard let expireDate else {
            // 買い切りプランには有効期限がないため、信頼期間内であれば課金中
            return true
        }

        return expireDate > Date.now
    }

    /// 最後に確認できた課金状態を信頼できるか（信頼期間内に確認できていれば true）
    ///
    /// false は「非課金」ではなく「課金状態を確認できない状態が続きすぎた」を意味する。
    public var isTrusted: Bool {
        guard let verifiedAt else {
            return false
        }

        let elapsed = Date.now.timeIntervalSince(verifiedAt)
        guard elapsed >= 0 else {
            // 端末時刻を進めた状態で確認日時を書かせてから戻すと、経過時間が負になり
            // 信頼期間が実質無期限になってしまう。未来の確認日時は信頼しない。
            // 再確認に成功すれば verifiedAt が正しい値に戻る
            return false
        }

        return elapsed < trustDuration
    }

    /// 買い切りプラン購入済みとして記録されているか
    ///
    /// 信頼期間は考慮しない。課金中かどうかの判定には `isPurchased` を使うこと。
    public var isLifetimePurchased: Bool {
        if case .premium(expireDate: nil) = lastKnownState {
            return true
        }
        return false
    }

    /// 最後に確認できたサブスクリプションの有効期限
    ///
    /// 買い切りプラン・非課金の場合は nil。
    public var subscriptionExpireDate: Date? {
        guard case let .premium(expireDate) = lastKnownState else {
            return nil
        }
        return expireDate
    }

    /// 課金状態の確認結果を反映する。`verifiedAt` を現在時刻で更新する
    public func apply(_ result: CheckPurchaseUseCase.UseCaseResult) {
        lastKnownState = result
        verifiedAt = .now
        persist()
    }

    /// 買い切りプランの購入確定時に呼び出す
    public func setLifetimePurchased() {
        apply(.premium(expireDate: nil))
    }

    /// サブスクリプションの有効期限を設定する
    ///
    /// nil を渡すと非課金として記録する。
    public func setSubscriptionExpireDate(date: Date?) {
        apply(date.map { .premium(expireDate: $0) } ?? .free)
    }

    // MARK: - Private

    private func persist() {
        guard let lastKnownState, let verifiedAt else {
            userDefaults.removeObject(forKey: isPremiumKey)
            userDefaults.removeObject(forKey: expireDateKey)
            userDefaults.removeObject(forKey: verifiedAtKey)
            return
        }

        switch lastKnownState {
        case let .premium(expireDate):
            userDefaults.set(true, forKey: isPremiumKey)
            if let expireDate {
                userDefaults.set(expireDate, forKey: expireDateKey)
            } else {
                // 買い切りプランには有効期限がない
                userDefaults.removeObject(forKey: expireDateKey)
            }
        case .free:
            userDefaults.set(false, forKey: isPremiumKey)
            userDefaults.removeObject(forKey: expireDateKey)
        }
        userDefaults.set(verifiedAt, forKey: verifiedAtKey)
    }
}
