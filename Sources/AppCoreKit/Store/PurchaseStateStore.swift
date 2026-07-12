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
/// サブスクリプションの有効期限はメモリ上でのみ保持し、
/// 買い切りプランは UserDefaults にキャッシュして TTL 以内であれば起動時に復元する。
///
/// ## 使用例
/// ```swift
/// let result = await CheckPurchaseUseCase().execute(.init())
/// if case let .success(output) = result {
///     purchaseState.apply(output)
/// }
/// if purchaseState.isPurchased {
///     // プレミアム機能を解放
/// }
/// ```
@MainActor
public final class PurchaseStateStore: ObservableObject {
    /// サブスクリプションの有効期限（永続化しない）
    @Published public private(set) var subscriptionExpireDate: Date?

    /// 買い切りプラン購入済みか（UserDefaults にキャッシュされ、TTL 以内であれば起動時に復元される）
    @Published public private(set) var isLifetimePurchased = false

    /// 課金判定を上書きするフック（デバッグ用）
    ///
    /// non-nil を返すとその値を `isPurchased` の結果として採用する。
    /// アプリ側で `#if DEBUG` ガード付きで設定すること。
    public var isPurchasedOverride: (() -> Bool?)?

    private let userDefaults: UserDefaults
    private let lifetimeCachedAtKey: String
    private let lifetimeCacheTTL: TimeInterval

    /// - Parameters:
    ///   - userDefaults: 永続化先（テスト時は suiteName 付きを注入）
    ///   - lifetimeCachedAtKey: 買い切りキャッシュ日時の UserDefaults キー
    ///     （既存アプリとの互換のためデフォルトは "lifetime_cached_at"）
    ///   - lifetimeCacheTTL: 買い切りキャッシュの有効期間（デフォルト: 2日）
    public init(
        userDefaults: UserDefaults = .standard,
        lifetimeCachedAtKey: String = "lifetime_cached_at",
        lifetimeCacheTTL: TimeInterval = 2 * 24 * 60 * 60,
    ) {
        self.userDefaults = userDefaults
        self.lifetimeCachedAtKey = lifetimeCachedAtKey
        self.lifetimeCacheTTL = lifetimeCacheTTL

        // 買い切りキャッシュが有効であれば起動時に即反映（cachedAt は更新しない）
        if let cachedAt = userDefaults.object(forKey: lifetimeCachedAtKey) as? Date,
           Date.now.timeIntervalSince(cachedAt) < lifetimeCacheTTL
        {
            isLifetimePurchased = true
        }
    }

    /// 課金ユーザーか？
    ///
    /// 買い切り購入済み、またはサブスクリプションが有効期限内の場合に true を返す。
    public var isPurchased: Bool {
        if let override = isPurchasedOverride?() {
            return override
        }

        if isLifetimePurchased {
            return true
        }

        guard let expireDate = subscriptionExpireDate else {
            return false
        }

        return expireDate > Date.now
    }

    /// 買い切りキャッシュが有効か（TTL 以内に確認済みであれば true）
    public var isLifetimeCacheValid: Bool {
        guard let cachedAt = userDefaults.object(forKey: lifetimeCachedAtKey) as? Date else {
            return false
        }
        return Date.now.timeIntervalSince(cachedAt) < lifetimeCacheTTL
    }

    /// サブスクリプションの有効期限を設定する
    ///
    /// 買い切りフラグとキャッシュはリセットされる。
    /// nil を渡すと未課金状態に戻る。
    public func setSubscriptionExpireDate(date: Date?) {
        isLifetimePurchased = false
        userDefaults.removeObject(forKey: lifetimeCachedAtKey)
        subscriptionExpireDate = date
    }

    /// 買い切りプランの購入確定時に呼び出す。cachedAt を現在時刻で更新する
    public func setLifetimePurchased() {
        isLifetimePurchased = true
        userDefaults.set(Date.now, forKey: lifetimeCachedAtKey)
    }

    /// キャッシュ復元時に呼び出す。cachedAt は更新しない
    public func restoreLifetimePurchased() {
        isLifetimePurchased = true
    }

    /// CheckPurchaseUseCase の結果を反映する
    ///
    /// expireDate の有無でサブスクリプションと買い切りプランを判別する。
    public func apply(_ result: CheckPurchaseUseCase.UseCaseResult) {
        switch result {
        case let .premium(expireDate):
            if let expireDate {
                // サブスクリプション
                setSubscriptionExpireDate(date: expireDate)
            } else {
                // 買い切りプラン（expireDate == nil）
                setLifetimePurchased()
            }
        case .free:
            // 非課金
            setSubscriptionExpireDate(date: nil)
        }
    }
}
