//
//  CheckPurchaseUseCaseTests.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

@testable import AppCoreKit
import Foundation
import RevenueCat
import Testing

/// `NSUnderlyingErrorKey` が自分自身を指し続けるエラー（連鎖の循環を再現する）
private final class SelfReferencingError: NSError, @unchecked Sendable {
    convenience init() {
        self.init(domain: "SelfReferencingError", code: 0, userInfo: nil)
    }

    override var userInfo: [String: Any] {
        [NSUnderlyingErrorKey: self]
    }
}

struct CheckPurchaseUseCaseTests {
    private struct DummyError: Error {}

    private func revenueCatError(_ code: ErrorCode, underlyingError: (any Error)? = nil) -> NSError {
        var userInfo: [String: Any] = [:]
        if let underlyingError {
            userInfo[NSUnderlyingErrorKey] = underlyingError as NSError
        }
        return NSError(domain: ErrorCode.errorDomain, code: code.rawValue, userInfo: userInfo)
    }

    // MARK: - execute

    @Test func 課金情報の取得に失敗した場合_エラーを返す() async {
        let useCase = CheckPurchaseUseCase(fetchCustomerInfo: {
            throw URLError(.notConnectedToInternet)
        })

        let result = await useCase.execute(.init())

        switch result {
        case let .success(state):
            Issue.record("失敗時は .failure を返すべきだが \(state) が返された")
        case let .failure(error):
            guard case let .networkUnreachable(underlyingError) = error as? CheckPurchaseUseCase.UseCaseError else {
                Issue.record("networkUnreachable を期待したが \(error) が返された")
                return
            }
            #expect((underlyingError as? URLError)?.code == .notConnectedToInternet)
        }
    }

    // MARK: - classify

    @Test func オフライン時のRevenueCatエラー_サーバー未到達に分類される() {
        let error = CheckPurchaseUseCase.classify(revenueCatError(.offlineConnectionError))

        guard case .networkUnreachable = error else {
            Issue.record("networkUnreachable を期待したが \(error) が返された")
            return
        }
    }

    @Test func 通信エラーのRevenueCatエラー_サーバー未到達に分類される() {
        let error = CheckPurchaseUseCase.classify(revenueCatError(.networkError))

        guard case .networkUnreachable = error else {
            Issue.record("networkUnreachable を期待したが \(error) が返された")
            return
        }
    }

    @Test func 認証エラーのRevenueCatエラー_サーバーエラーに分類される() {
        let error = CheckPurchaseUseCase.classify(revenueCatError(.invalidCredentialsError))

        guard case .serverError = error else {
            Issue.record("serverError を期待したが \(error) が返された")
            return
        }
    }

    @Test func レスポンス不正のRevenueCatエラー_サーバーエラーに分類される() {
        let error = CheckPurchaseUseCase.classify(revenueCatError(.unexpectedBackendResponseError))

        guard case .serverError = error else {
            Issue.record("serverError を期待したが \(error) が返された")
            return
        }
    }

    @Test func 設定不備のRevenueCatエラー_分類できないエラーになる() {
        let error = CheckPurchaseUseCase.classify(revenueCatError(.configurationError))

        guard case .unexpected = error else {
            Issue.record("unexpected を期待したが \(error) が返された")
            return
        }
    }

    @Test func URLErrorのタイムアウト_サーバー未到達に分類される() {
        let error = CheckPurchaseUseCase.classify(URLError(.timedOut))

        guard case .networkUnreachable = error else {
            Issue.record("networkUnreachable を期待したが \(error) が返された")
            return
        }
    }

    @Test func 内包するURLErrorが通信エラーの場合_サーバー未到達に分類される() {
        // RevenueCat のエラーコードでは判断できないが、内包する URLError で判断できるケース
        let error = CheckPurchaseUseCase.classify(
            revenueCatError(.unknownError, underlyingError: URLError(.cannotConnectToHost)),
        )

        guard case .networkUnreachable = error else {
            Issue.record("networkUnreachable を期待したが \(error) が返された")
            return
        }
    }

    @Test func サーバーが応答したURLError_分類できないエラーになる() {
        // 通信自体は成立しているため、サーバー未到達とは扱わない
        let error = CheckPurchaseUseCase.classify(URLError(.badServerResponse))

        guard case .unexpected = error else {
            Issue.record("unexpected を期待したが \(error) が返された")
            return
        }
    }

    @Test func 判別できないエラー_分類できないエラーになる() {
        let error = CheckPurchaseUseCase.classify(DummyError())

        guard case let .unexpected(underlyingError) = error else {
            Issue.record("unexpected を期待したが \(error) が返された")
            return
        }
        #expect(underlyingError is DummyError)
    }

    @Test func 深い連鎖のURLError_サーバー未到達に分類される() {
        // NSUnderlyingErrorKey を数段辿った先に URLError があるケース
        var error: any Error = URLError(.notConnectedToInternet)
        for _ in 0 ..< 3 {
            error = revenueCatError(.unknownError, underlyingError: error)
        }

        guard case .networkUnreachable = CheckPurchaseUseCase.classify(error) else {
            Issue.record("networkUnreachable を期待したが分類されなかった")
            return
        }
    }

    @Test func 連鎖が循環していても分類が終了する() {
        // 自分自身を underlying error として返し続けるエラー
        guard case .unexpected = CheckPurchaseUseCase.classify(SelfReferencingError()) else {
            Issue.record("unexpected を期待したが別の種別に分類された")
            return
        }
    }

    // MARK: - underlyingError

    @Test func underlyingErrorで分類元のエラーを取得できる() {
        let error = CheckPurchaseUseCase.classify(DummyError())

        #expect(error.underlyingError is DummyError)
    }

    @Test func errorDescriptionは分類元のエラーの説明を返す() {
        let underlyingError = URLError(.notConnectedToInternet)
        let error = CheckPurchaseUseCase.classify(underlyingError)

        #expect(error.errorDescription == underlyingError.localizedDescription)
        #expect(error.localizedDescription == underlyingError.localizedDescription)
    }
}
