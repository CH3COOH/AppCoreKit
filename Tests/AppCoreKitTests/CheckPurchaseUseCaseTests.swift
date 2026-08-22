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

    /// 指定したエラーで課金情報の取得が失敗したときに、どの種別へ分類されるかを取得する
    private func classifiedError(from error: any Error & Sendable) async throws -> CheckPurchaseUseCase.UseCaseError {
        let useCase = CheckPurchaseUseCase(fetchCustomerInfo: { throw error })
        let result = await useCase.execute(.init())
        let failure: (any Error)? = if case let .failure(error) = result {
            error
        } else {
            nil
        }
        return try #require(failure as? CheckPurchaseUseCase.UseCaseError)
    }

    // MARK: - execute

    @Test func 課金情報の取得に失敗した場合_エラーを返す() async throws {
        let error = try await classifiedError(from: URLError(.notConnectedToInternet))

        guard case let .networkUnreachable(underlyingError) = error else {
            Issue.record("networkUnreachable を期待したが \(error) が返された")
            return
        }
        #expect((underlyingError as? URLError)?.code == .notConnectedToInternet)
    }

    // MARK: - エラーの分類

    @Test func オフライン時のRevenueCatエラー_サーバー未到達に分類される() async throws {
        let error = try await classifiedError(from: revenueCatError(.offlineConnectionError))

        guard case .networkUnreachable = error else {
            Issue.record("networkUnreachable を期待したが \(error) が返された")
            return
        }
    }

    @Test func 通信エラーのRevenueCatエラー_サーバー未到達に分類される() async throws {
        let error = try await classifiedError(from: revenueCatError(.networkError))

        guard case .networkUnreachable = error else {
            Issue.record("networkUnreachable を期待したが \(error) が返された")
            return
        }
    }

    @Test func 認証エラーのRevenueCatエラー_サーバーエラーに分類される() async throws {
        let error = try await classifiedError(from: revenueCatError(.invalidCredentialsError))

        guard case .serverError = error else {
            Issue.record("serverError を期待したが \(error) が返された")
            return
        }
    }

    @Test func レスポンス不正のRevenueCatエラー_サーバーエラーに分類される() async throws {
        let error = try await classifiedError(from: revenueCatError(.unexpectedBackendResponseError))

        guard case .serverError = error else {
            Issue.record("serverError を期待したが \(error) が返された")
            return
        }
    }

    @Test func 設定不備のRevenueCatエラー_分類できないエラーになる() async throws {
        let error = try await classifiedError(from: revenueCatError(.configurationError))

        guard case .unexpected = error else {
            Issue.record("unexpected を期待したが \(error) が返された")
            return
        }
    }

    @Test func URLErrorのタイムアウト_サーバー未到達に分類される() async throws {
        let error = try await classifiedError(from: URLError(.timedOut))

        guard case .networkUnreachable = error else {
            Issue.record("networkUnreachable を期待したが \(error) が返された")
            return
        }
    }

    @Test func 内包するURLErrorが通信エラーの場合_サーバー未到達に分類される() async throws {
        // RevenueCat のエラーコードでは判断できないが、内包する URLError で判断できるケース
        let error = try await classifiedError(
            from: revenueCatError(.unknownError, underlyingError: URLError(.cannotConnectToHost)),
        )

        guard case .networkUnreachable = error else {
            Issue.record("networkUnreachable を期待したが \(error) が返された")
            return
        }
    }

    @Test func サーバーが応答したURLError_分類できないエラーになる() async throws {
        // 通信自体は成立しているため、サーバー未到達とは扱わない
        let error = try await classifiedError(from: URLError(.badServerResponse))

        guard case .unexpected = error else {
            Issue.record("unexpected を期待したが \(error) が返された")
            return
        }
    }

    @Test func 判別できないエラー_分類できないエラーになる() async throws {
        let error = try await classifiedError(from: DummyError())

        guard case let .unexpected(underlyingError) = error else {
            Issue.record("unexpected を期待したが \(error) が返された")
            return
        }
        #expect(underlyingError is DummyError)
    }

    @Test func 深い連鎖のURLError_サーバー未到達に分類される() async throws {
        // NSUnderlyingErrorKey を数段辿った先に URLError があるケース
        var underlyingError: any Error = URLError(.notConnectedToInternet)
        for _ in 0 ..< 3 {
            underlyingError = revenueCatError(.unknownError, underlyingError: underlyingError)
        }

        let error = try await classifiedError(from: underlyingError as NSError)

        guard case .networkUnreachable = error else {
            Issue.record("networkUnreachable を期待したが \(error) が返された")
            return
        }
    }

    @Test func 連鎖が循環していても分類が終了する() async throws {
        // 自分自身を underlying error として返し続けるエラー
        let error = try await classifiedError(from: SelfReferencingError())

        guard case .unexpected = error else {
            Issue.record("unexpected を期待したが \(error) が返された")
            return
        }
    }

    // MARK: - underlyingError

    @Test func underlyingErrorで分類元のエラーを取得できる() async throws {
        let error = try await classifiedError(from: DummyError())

        #expect(error.underlyingError is DummyError)
    }

    @Test func errorDescriptionは分類元のエラーの説明を返す() async throws {
        let underlyingError = URLError(.notConnectedToInternet)
        let error = try await classifiedError(from: underlyingError)

        #expect(error.errorDescription == underlyingError.localizedDescription)
        #expect(error.localizedDescription == underlyingError.localizedDescription)
    }
}
