//
//  PurchaseStateStoreTests.swift
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
struct PurchaseStateStoreTests {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "AppCoreKitTests.PurchaseStateStore.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    /// `verifiedAt` が指定した時間だけ過去になっている状態を作る
    private func makeDefaults(verifiedAgo: TimeInterval, isPremium: Bool, expireDate: Date? = nil) -> UserDefaults {
        let defaults = makeDefaults()
        defaults.set(isPremium, forKey: "purchase_state_is_premium")
        defaults.set(Date.now.addingTimeInterval(-verifiedAgo), forKey: "purchase_state_verified_at")
        if let expireDate {
            defaults.set(expireDate, forKey: "purchase_state_expire_date")
        }
        return defaults
    }

    // MARK: - isPurchased

    @Test func 初期状態_未課金を返す() {
        let store = PurchaseStateStore(userDefaults: makeDefaults())

        #expect(store.isPurchased == false)
        #expect(store.lastKnownState == nil)
        #expect(store.verifiedAt == nil)
    }

    @Test func サブスク有効期限が未来の場合_課金中を返す() {
        let store = PurchaseStateStore(userDefaults: makeDefaults())

        store.setSubscriptionExpireDate(date: Date.now.addingTimeInterval(3600))

        #expect(store.isPurchased == true)
    }

    @Test func サブスク有効期限が過去の場合_未課金を返す() {
        let store = PurchaseStateStore(userDefaults: makeDefaults())

        store.setSubscriptionExpireDate(date: Date.now.addingTimeInterval(-3600))

        #expect(store.isPurchased == false)
    }

    @Test func 買い切り購入済みの場合_課金中を返す() {
        let store = PurchaseStateStore(userDefaults: makeDefaults())

        store.setLifetimePurchased()

        #expect(store.isPurchased == true)
        #expect(store.isLifetimePurchased == true)
        #expect(store.subscriptionExpireDate == nil)
    }

    @Test func オーバーライドが設定されている場合_その値を返す() {
        let store = PurchaseStateStore(userDefaults: makeDefaults())
        store.setLifetimePurchased()

        store.isPurchasedOverride = { false }
        #expect(store.isPurchased == false)

        store.isPurchasedOverride = { nil }
        #expect(store.isPurchased == true)
    }

    // MARK: - 永続化と復元

    @Test func 買い切り購入が永続化され_再起動しても課金中のまま() {
        let defaults = makeDefaults()
        PurchaseStateStore(userDefaults: defaults).setLifetimePurchased()

        let relaunched = PurchaseStateStore(userDefaults: defaults)

        #expect(relaunched.isPurchased == true)
        #expect(relaunched.isLifetimePurchased == true)
    }

    @Test func サブスクの有効期限が永続化され_再起動しても課金中のまま() {
        let defaults = makeDefaults()
        let expireDate = Date.now.addingTimeInterval(86400)
        PurchaseStateStore(userDefaults: defaults).setSubscriptionExpireDate(date: expireDate)

        let relaunched = PurchaseStateStore(userDefaults: defaults)

        #expect(relaunched.isPurchased == true)
        #expect(relaunched.subscriptionExpireDate == expireDate)
        #expect(relaunched.isLifetimePurchased == false)
    }

    @Test func 非課金が永続化され_再起動しても未課金のまま() {
        let defaults = makeDefaults()
        let store = PurchaseStateStore(userDefaults: defaults)
        store.setLifetimePurchased()

        store.apply(.free)

        #expect(PurchaseStateStore(userDefaults: defaults).isPurchased == false)
    }

    @Test func 確認日時が永続化されていない場合_復元されない() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: "purchase_state_is_premium")

        let store = PurchaseStateStore(userDefaults: defaults)

        #expect(store.lastKnownState == nil)
        #expect(store.isPurchased == false)
    }

    // MARK: - 信頼期間

    @Test func 信頼期間内であれば_確認できなくても買い切りの課金状態を維持する() {
        let defaults = makeDefaults(verifiedAgo: 29 * 24 * 60 * 60, isPremium: true)

        let store = PurchaseStateStore(userDefaults: defaults)

        #expect(store.isTrusted == true)
        #expect(store.isPurchased == true)
    }

    @Test func 信頼期間を過ぎた買い切りは_未課金として扱われる() {
        let defaults = makeDefaults(verifiedAgo: 31 * 24 * 60 * 60, isPremium: true)

        let store = PurchaseStateStore(userDefaults: defaults)

        #expect(store.isTrusted == false)
        #expect(store.isPurchased == false)
        // 購入の記録自体は残る（再確認できれば復帰する）
        #expect(store.isLifetimePurchased == true)
    }

    @Test func 信頼期間内であれば_確認できなくてもサブスクの課金状態を維持する() {
        let defaults = makeDefaults(
            verifiedAgo: 10 * 24 * 60 * 60,
            isPremium: true,
            expireDate: Date.now.addingTimeInterval(86400),
        )

        let store = PurchaseStateStore(userDefaults: defaults)

        #expect(store.isPurchased == true)
    }

    @Test func 信頼期間を過ぎたサブスクは_有効期限内でも未課金として扱われる() {
        let defaults = makeDefaults(
            verifiedAgo: 31 * 24 * 60 * 60,
            isPremium: true,
            expireDate: Date.now.addingTimeInterval(86400),
        )

        let store = PurchaseStateStore(userDefaults: defaults)

        #expect(store.isPurchased == false)
    }

    @Test func 信頼期間内でも_サブスクの有効期限を過ぎていれば未課金() {
        let defaults = makeDefaults(
            verifiedAgo: 60,
            isPremium: true,
            expireDate: Date.now.addingTimeInterval(-60),
        )

        let store = PurchaseStateStore(userDefaults: defaults)

        #expect(store.isTrusted == true)
        #expect(store.isPurchased == false)
    }

    @Test func 再確認できれば信頼期間がリセットされる() {
        let defaults = makeDefaults(verifiedAgo: 31 * 24 * 60 * 60, isPremium: true)
        let store = PurchaseStateStore(userDefaults: defaults)
        #expect(store.isPurchased == false)

        store.apply(.premium(expireDate: nil))

        #expect(store.isTrusted == true)
        #expect(store.isPurchased == true)
    }

    @Test func 確認日時が未来の場合_信頼しない() {
        // 端末時刻を進めて確認日時を書かせてから戻した状況を想定する
        let defaults = makeDefaults(verifiedAgo: -3600, isPremium: true)

        let store = PurchaseStateStore(userDefaults: defaults)

        #expect(store.isTrusted == false)
        #expect(store.isPurchased == false)
    }

    @Test func 確認日時が未来でも_再確認できれば復帰する() {
        let defaults = makeDefaults(verifiedAgo: -3600, isPremium: true)
        let store = PurchaseStateStore(userDefaults: defaults)

        store.apply(.premium(expireDate: nil))

        #expect(store.isTrusted == true)
        #expect(store.isPurchased == true)
    }

    @Test func 信頼期間を変更できる() {
        let defaults = makeDefaults(verifiedAgo: 3600, isPremium: true)

        let store = PurchaseStateStore(userDefaults: defaults, trustDuration: 60)

        #expect(store.isTrusted == false)
        #expect(store.isPurchased == false)
    }

    // MARK: - 旧バージョンからの移行

    @Test func 買い切りキャッシュ日時のみを持つ旧バージョンから移行できる() {
        let defaults = makeDefaults()
        let cachedAt = Date.now.addingTimeInterval(-3600)
        defaults.set(cachedAt, forKey: "lifetime_cached_at")

        let store = PurchaseStateStore(userDefaults: defaults)

        #expect(store.isLifetimePurchased == true)
        #expect(store.isPurchased == true)
        #expect(store.verifiedAt == cachedAt)
        // 移行後は旧キーを削除し、新しい形式で永続化する
        #expect(defaults.object(forKey: "lifetime_cached_at") == nil)
        #expect(PurchaseStateStore(userDefaults: defaults).isPurchased == true)
    }

    @Test func 旧バージョンのキャッシュ日時が古くても_信頼期間内なら移行後も課金中() {
        let defaults = makeDefaults()
        // 旧実装の TTL（2日）は超えているが、新しい信頼期間（30日）には収まる
        defaults.set(Date.now.addingTimeInterval(-3 * 24 * 60 * 60), forKey: "lifetime_cached_at")

        let store = PurchaseStateStore(userDefaults: defaults)

        #expect(store.isPurchased == true)
    }

    @Test func 新しい形式が保存されている場合_旧キーは参照されない() {
        let defaults = makeDefaults(verifiedAgo: 60, isPremium: false)
        defaults.set(Date.now, forKey: "lifetime_cached_at")

        let store = PurchaseStateStore(userDefaults: defaults)

        #expect(store.isPurchased == false)
    }

    @Test func 旧キーも新しい形式もない場合_未課金のまま() {
        let defaults = makeDefaults()

        let store = PurchaseStateStore(userDefaults: defaults)

        #expect(store.isPurchased == false)
        #expect(defaults.object(forKey: "purchase_state_is_premium") == nil)
    }

    @Test func キー接頭辞を変更できる() {
        let defaults = makeDefaults()
        let store = PurchaseStateStore(userDefaults: defaults, keyPrefix: "my_purchase")

        store.setLifetimePurchased()

        #expect(defaults.bool(forKey: "my_purchase_is_premium") == true)
        #expect(defaults.object(forKey: "purchase_state_is_premium") == nil)
    }

    // MARK: - apply

    @Test func 有効期限付きプレミアムの適用_サブスクとして反映される() {
        let store = PurchaseStateStore(userDefaults: makeDefaults())
        let expireDate = Date.now.addingTimeInterval(3600)

        store.apply(.premium(expireDate: expireDate))

        #expect(store.subscriptionExpireDate == expireDate)
        #expect(store.isLifetimePurchased == false)
        #expect(store.isPurchased == true)
    }

    @Test func 有効期限なしプレミアムの適用_買い切りとして反映される() {
        let store = PurchaseStateStore(userDefaults: makeDefaults())

        store.apply(.premium(expireDate: nil))

        #expect(store.isLifetimePurchased == true)
        #expect(store.isPurchased == true)
    }

    @Test func 非課金の適用_未課金状態に戻る() {
        let defaults = makeDefaults()
        let store = PurchaseStateStore(userDefaults: defaults)
        store.setLifetimePurchased()

        store.apply(.free)

        #expect(store.isLifetimePurchased == false)
        #expect(store.subscriptionExpireDate == nil)
        #expect(store.isPurchased == false)
        #expect(defaults.object(forKey: "purchase_state_expire_date") == nil)
    }

    @Test func サブスクから買い切りへの切り替えで有効期限が消える() {
        let defaults = makeDefaults()
        let store = PurchaseStateStore(userDefaults: defaults)
        store.setSubscriptionExpireDate(date: Date.now.addingTimeInterval(3600))

        store.setLifetimePurchased()

        #expect(store.subscriptionExpireDate == nil)
        #expect(store.isLifetimePurchased == true)
        #expect(PurchaseStateStore(userDefaults: defaults).subscriptionExpireDate == nil)
    }
}
