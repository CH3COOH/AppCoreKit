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

    // MARK: - isPurchased

    @Test func 初期状態_未課金を返す() {
        let store = PurchaseStateStore(userDefaults: makeDefaults())

        #expect(store.isPurchased == false)
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
    }

    @Test func オーバーライドが設定されている場合_その値を返す() {
        let store = PurchaseStateStore(userDefaults: makeDefaults())
        store.setLifetimePurchased()

        store.isPurchasedOverride = { false }
        #expect(store.isPurchased == false)

        store.isPurchasedOverride = { nil }
        #expect(store.isPurchased == true)
    }

    // MARK: - 買い切りキャッシュ

    @Test func TTL以内のキャッシュがある場合_初期化時に買い切り状態が復元される() {
        let defaults = makeDefaults()
        defaults.set(Date.now.addingTimeInterval(-3600), forKey: "lifetime_cached_at")

        let store = PurchaseStateStore(userDefaults: defaults)

        #expect(store.isLifetimePurchased == true)
        #expect(store.isLifetimeCacheValid == true)
    }

    @Test func TTLを超えたキャッシュがある場合_初期化時に復元されない() {
        let defaults = makeDefaults()
        defaults.set(Date.now.addingTimeInterval(-3 * 24 * 60 * 60), forKey: "lifetime_cached_at")

        let store = PurchaseStateStore(userDefaults: defaults)

        #expect(store.isLifetimePurchased == false)
        #expect(store.isLifetimeCacheValid == false)
    }

    @Test func 買い切り購入確定でキャッシュ日時が保存される() {
        let defaults = makeDefaults()
        let store = PurchaseStateStore(userDefaults: defaults)

        store.setLifetimePurchased()

        #expect(defaults.object(forKey: "lifetime_cached_at") is Date)
        #expect(store.isLifetimeCacheValid == true)
    }

    @Test func キャッシュ復元ではキャッシュ日時が更新されない() {
        let defaults = makeDefaults()
        let store = PurchaseStateStore(userDefaults: defaults)

        store.restoreLifetimePurchased()

        #expect(store.isLifetimePurchased == true)
        #expect(defaults.object(forKey: "lifetime_cached_at") == nil)
    }

    @Test func サブスク設定で買い切りフラグとキャッシュがリセットされる() {
        let defaults = makeDefaults()
        let store = PurchaseStateStore(userDefaults: defaults)
        store.setLifetimePurchased()

        store.setSubscriptionExpireDate(date: Date.now.addingTimeInterval(3600))

        #expect(store.isLifetimePurchased == false)
        #expect(defaults.object(forKey: "lifetime_cached_at") == nil)
        #expect(store.isPurchased == true)
    }

    @Test func キー名を変更できる() {
        let defaults = makeDefaults()
        let store = PurchaseStateStore(userDefaults: defaults, lifetimeCachedAtKey: "my_cached_at")

        store.setLifetimePurchased()

        #expect(defaults.object(forKey: "my_cached_at") is Date)
        #expect(defaults.object(forKey: "lifetime_cached_at") == nil)
    }

    @Test func TTLを変更できる() {
        let defaults = makeDefaults()
        defaults.set(Date.now.addingTimeInterval(-3600), forKey: "lifetime_cached_at")

        let store = PurchaseStateStore(userDefaults: defaults, lifetimeCacheTTL: 60)

        #expect(store.isLifetimePurchased == false)
        #expect(store.isLifetimeCacheValid == false)
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
        let store = PurchaseStateStore(userDefaults: makeDefaults())
        store.setLifetimePurchased()

        store.apply(.free)

        #expect(store.isLifetimePurchased == false)
        #expect(store.subscriptionExpireDate == nil)
        #expect(store.isPurchased == false)
    }
}
