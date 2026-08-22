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
import Testing

struct CheckPurchaseUseCaseTests {
    private struct DummyError: Error {}

    @Test func 課金情報の取得に失敗した場合_エラーを返す() async {
        let useCase = CheckPurchaseUseCase(fetchCustomerInfo: {
            throw DummyError()
        })

        let result = await useCase.execute(.init())

        switch result {
        case let .success(state):
            Issue.record("失敗時は .failure を返すべきだが \(state) が返された")
        case let .failure(error):
            #expect(error is DummyError)
        }
    }
}
