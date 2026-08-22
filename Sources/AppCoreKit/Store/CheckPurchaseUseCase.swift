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
/// 課金情報の取得に失敗した場合は `.failure` を返す。
/// `.free` は「本当に非課金である」ことだけを表すため、
/// 呼び出し元は `.failure` のときに課金状態をダウングレードしてはならない。
///
/// ## 使用例
/// ```swift
/// let result = await CheckPurchaseUseCase().execute(.init(entitlementKey: "premium"))
/// switch result {
/// case let .success(state):
///     purchaseState.apply(state)
/// case .failure:
///     // 取得に失敗しただけなので、現在の課金状態を維持する
///     break
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

    private let fetchCustomerInfo: @Sendable () async throws -> CustomerInfo

    /// - Parameter fetchCustomerInfo: 課金情報の取得処理（テスト時に差し替える）
    public init(
        fetchCustomerInfo: @escaping @Sendable () async throws -> CustomerInfo = {
            try await Purchases.shared.customerInfo()
        },
    ) {
        self.fetchCustomerInfo = fetchCustomerInfo
    }

    public func execute(_ input: Input) async -> Result<Output, any Error> {
        do {
            let customerInfo = try await fetchCustomerInfo()
            return .success(resolveResult(from: customerInfo, entitlementKey: input.entitlementKey))
        } catch {
            // 取得できなかっただけで非課金とは限らないため、エラーをそのまま返す
            return .failure(error)
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
