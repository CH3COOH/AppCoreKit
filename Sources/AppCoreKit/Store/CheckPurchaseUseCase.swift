//
//  CheckPurchaseUseCase.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import Foundation
import RevenueCat

/// 課金状態のチェック
///
/// RevenueCat の entitlement を確認し、課金状態を返す。
/// 状態管理（AppState / PremiumManager への反映）は呼び出し元が `UseCaseResult` を見て行う。
///
/// ## 使用例
/// ```swift
/// let result = await CheckPurchaseUseCase().execute(.init(entitlementKey: "premium"))
/// if case .success(.premium(let date)) = result {
///     await AppState.shared.setSubscriptionExpireDate(date: date)
/// }
/// ```
public final class CheckPurchaseUseCase: UseCaseProtocol {
    public typealias Input = CheckPurchaseUseCase.UseCaseInput
    public typealias Output = CheckPurchaseUseCase.UseCaseResult

    public struct UseCaseInput {
        /// RevenueCat の entitlement 識別子
        public let entitlementKey: String

        public init(entitlementKey: String = "premium") {
            self.entitlementKey = entitlementKey
        }
    }

    public enum UseCaseResult: Sendable {
        /// 課金中（買い切りの場合は expireDate == nil）
        case premium(expireDate: Date?)
        /// 非課金
        case free
    }

    public init() {}

    public func execute(_ input: Input) async -> Result<Output, any Error> {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            return .success(resolveResult(from: customerInfo, entitlementKey: input.entitlementKey))
        } catch {
            return .success(.free)
        }
    }

    private func resolveResult(from customerInfo: CustomerInfo, entitlementKey: String) -> UseCaseResult {
        guard let entitlement = customerInfo.entitlements.all[entitlementKey],
              entitlement.isActive
        else {
            return .free
        }
        return .premium(expireDate: entitlement.expirationDate)
    }
}
