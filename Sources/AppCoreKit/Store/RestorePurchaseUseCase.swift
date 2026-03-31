//
//  RestorePurchaseUseCase.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import Foundation
import RevenueCat

/// 購入の復元
///
/// RevenueCat の `restorePurchases()` を呼び出し、entitlement の有無で結果を返す。
/// 状態管理（AppState / PremiumManager への反映）は呼び出し元が `UseCaseResult` を見て行う。
///
/// `CheckPurchaseUseCase` との違い: ネットワークエラーなどの失敗は `.failure` で返す。
/// ユーザー操作を起点にしているため、エラーを UI に伝える必要があるため。
///
/// ## 使用例
/// ```swift
/// let result = await RestorePurchaseUseCase().execute(.init(entitlementKey: "premium"))
/// switch result {
/// case .success(.restored(let date)):
///     await AppState.shared.setSubscriptionExpireDate(date: date)
/// case .success(.notFound):
///     // 復元できる購入なし
/// case .failure(let error):
///     // ネットワークエラーなど → UI に通知
/// }
/// ```
public final class RestorePurchaseUseCase: UseCaseProtocol {
    public typealias Input = RestorePurchaseUseCase.UseCaseInput
    public typealias Output = RestorePurchaseUseCase.UseCaseResult

    public struct UseCaseInput {
        /// RevenueCat の entitlement 識別子
        public let entitlementKey: String

        public init(entitlementKey: String = "premium") {
            self.entitlementKey = entitlementKey
        }
    }

    public enum UseCaseResult: Sendable {
        /// 課金が確認できた（expireDate == nil は買い切り）
        case restored(expireDate: Date?)
        /// 復元できる購入が見つからなかった
        case notFound
    }

    public init() {}

    public func execute(_ input: Input) async -> Result<Output, any Error> {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            guard let entitlement = customerInfo.entitlements.all[input.entitlementKey],
                  entitlement.isActive
            else {
                return .success(.notFound)
            }
            return .success(.restored(expireDate: entitlement.expirationDate))
        } catch {
            return .failure(error)
        }
    }
}
