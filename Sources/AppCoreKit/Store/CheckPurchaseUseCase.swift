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
/// 課金情報の取得に失敗した場合は `UseCaseError` を `.failure` で返す。
/// `.free` は「本当に非課金である」ことだけを表すため、
/// 呼び出し元は `.failure` のときに課金状態をダウングレードしてはならない。
///
/// ## 使用例
/// ```swift
/// let result = await CheckPurchaseUseCase().execute(.init(entitlementKey: "premium"))
/// switch result {
/// case let .success(state):
///     purchaseState.apply(state)
/// case let .failure(error):
///     // 取得に失敗しただけなので、現在の課金状態を維持する
///     if case .networkUnreachable = error as? CheckPurchaseUseCase.UseCaseError {
///         // 通信環境が回復してから再試行する、など
///     }
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

    /// 課金情報を取得できなかった理由
    ///
    /// 「サーバーへ到達できなかった」のか「サーバーがエラーを返した」のかで
    /// 呼び出し元のリトライ判断が変わるため分類している。
    /// いずれの場合も課金状態は不明であり、非課金と判断してはならない。
    public enum UseCaseError: LocalizedError {
        /// サーバーへ到達できなかった（オフライン・タイムアウト・名前解決の失敗など）
        ///
        /// 通信環境の問題であり、時間をおいて再試行すれば成功する可能性が高い。
        case networkUnreachable(any Error)

        /// サーバーへ到達したうえでエラーが返却された（認証エラー・バックエンドの障害・レスポンス不正など）
        case serverError(any Error)

        /// 上記のいずれにも分類できないエラー
        case unexpected(any Error)

        /// 分類元になったエラー
        public var underlyingError: any Error {
            switch self {
            case let .networkUnreachable(error),
                 let .serverError(error),
                 let .unexpected(error):
                error
            }
        }

        /// 分類元のエラーの説明をそのまま返す
        ///
        /// 分類はリトライ判断のためのものであり、ユーザーに伝えるべき内容は
        /// 分類元のエラー（RevenueCat や URLSession のエラー）が持っているため。
        public var errorDescription: String? {
            underlyingError.localizedDescription
        }
    }

    /// サーバーへ到達できなかったと判断する RevenueCat のエラーコード
    private static let networkUnreachableErrorCodes: Set<ErrorCode> = [
        .networkError, // 通信そのものの失敗（タイムアウト・名前解決の失敗など）
        .offlineConnectionError, // 端末がオフライン
        .apiEndpointBlockedError, // 通信がブロックされている
    ]

    /// サーバーへ到達したうえでエラーが返却されたと判断する RevenueCat のエラーコード
    private static let serverErrorCodes: Set<ErrorCode> = [
        .unexpectedBackendResponseError, // レスポンスを解釈できなかった
        .unknownBackendError, // バックエンドが想定外のエラーを返した
        .invalidCredentialsError, // APIキーが不正
        .invalidAppUserIdError,
        .invalidSubscriberAttributesError,
        .invalidReceiptError,
        .receiptInUseByOtherSubscriberError,
        .signatureVerificationFailed,
    ]

    /// サーバーへ到達できなかったと判断する `URLError` のコード
    private static let networkUnreachableURLErrorCodes: Set<URLError.Code> = [
        .notConnectedToInternet,
        .networkConnectionLost,
        .cannotConnectToHost,
        .cannotFindHost,
        .dnsLookupFailed,
        .timedOut,
        .internationalRoamingOff,
        .dataNotAllowed,
        .callIsActive,
    ]

    private let customerInfoProvider: @Sendable () async throws -> CustomerInfo

    /// - Parameter fetchCustomerInfo: 課金情報の取得処理（テスト時に差し替える）
    public init(
        fetchCustomerInfo: @escaping @Sendable () async throws -> CustomerInfo = {
            try await Purchases.shared.customerInfo()
        },
    ) {
        customerInfoProvider = fetchCustomerInfo
    }

    public func execute(_ input: Input) async -> Result<Output, any Error> {
        await fetchCustomerInfo(input: input)
    }

    /// 1. 課金情報を取得する
    private func fetchCustomerInfo(input: Input) async -> Result<Output, any Error> {
        do {
            let customerInfo = try await customerInfoProvider()
            return resolveEntitlement(input: input, customerInfo: customerInfo)
        } catch {
            // 取得できなかっただけで非課金とは限らないため、種別を判定して返す
            return .failure(Self.classify(error))
        }
    }

    /// 2. entitlement の有効・無効から課金状態を判定する
    private func resolveEntitlement(input: Input, customerInfo: CustomerInfo) -> Result<Output, any Error> {
        guard let entitlement = customerInfo.entitlements.all[input.entitlementKey],
              entitlement.isActive
        else {
            return .success(.free)
        }
        // 買い切りプランには有効期限がないため expireDate は nil になる
        return .success(.premium(expireDate: entitlement.expirationDate))
    }

    // MARK: - Private

    /// エラーを種別ごとに分類する
    private static func classify(_ error: any Error) -> UseCaseError {
        let nsError = error as NSError
        if nsError.domain == ErrorCode.errorDomain,
           let errorCode = ErrorCode(rawValue: nsError.code)
        {
            if networkUnreachableErrorCodes.contains(errorCode) {
                return .networkUnreachable(error)
            }
            if serverErrorCodes.contains(errorCode) {
                return .serverError(error)
            }
        }

        // RevenueCat のエラーコードで判断できない場合は、
        // 内包している URLError まで辿って通信エラーかどうかを判定する
        if let urlErrorCode = firstURLErrorCode(in: error),
           networkUnreachableURLErrorCodes.contains(urlErrorCode)
        {
            return .networkUnreachable(error)
        }

        return .unexpected(error)
    }

    /// 辿るエラーの連鎖の上限
    ///
    /// 連鎖が循環していた場合に無限ループへ陥らないためのもの。
    private static let maxUnderlyingErrorDepth = 10

    /// `NSUnderlyingErrorKey` を辿って最初に見つかった `URLError` のコードを返す
    private static func firstURLErrorCode(in error: any Error) -> URLError.Code? {
        var current: NSError? = error as NSError
        for _ in 0 ..< maxUnderlyingErrorDepth {
            guard let nsError = current else {
                return nil
            }
            if nsError.domain == NSURLErrorDomain {
                return URLError.Code(rawValue: nsError.code)
            }
            current = nsError.userInfo[NSUnderlyingErrorKey] as? NSError
        }
        return nil
    }
}
