//
//  CheckNetworkAccessUseCaseTests.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

@testable import AppCoreKit
import Foundation
import Testing

// MARK: - Tests

@Suite(.serialized)
struct CheckNetworkAccessUseCaseTests {
    private func makeURL() -> URL {
        URL(string: "https://example.com/check")!
    }

    private func successResponse() -> (HTTPURLResponse, Data) {
        let response = HTTPURLResponse(
            url: makeURL(),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (response, Data("Success".utf8))
    }

    private func failureResponse(statusCode: Int = 500) -> (HTTPURLResponse, Data) {
        let response = HTTPURLResponse(
            url: makeURL(),
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (response, Data())
    }

    @Test func Successが返る場合_successを返す() async throws {
        MockURLProtocol.requestHandler = { _ in self.successResponse() }
        let useCase = CheckNetworkAccessUseCase(urlSession: .mockSession())
        let result = await useCase.execute(.init(connectivityURL: makeURL()))
        #expect(result.isSuccess)
    }

    @Test func Success以外が返る場合_unexpectedResponseContentエラーを返す() async throws {
        MockURLProtocol.requestHandler = { _ in self.failureResponse() }
        let useCase = CheckNetworkAccessUseCase(urlSession: .mockSession())
        let result = await useCase.execute(.init(connectivityURL: makeURL()))
        guard case let .failure(error) = result else {
            Issue.record("Expected failure but got success")
            return
        }
        #expect((error as? CheckNetworkAccessUseCase.UseCaseError) == .unexpectedResponseContent)
    }
}

// MARK: - Result helper

private extension Result {
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}
