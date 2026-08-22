//
//  BaseViewModelTests.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

@testable import AppCoreKit
import Foundation
import Testing

private struct StubError: LocalizedError {
    var errorDescription: String? = "スタブエラーの説明"
}

private struct StubUseCase: UseCaseProtocol {
    typealias Input = Int
    typealias Output = String

    func execute(_ input: Int) async -> Result<String, any Error> {
        .success("value-\(input)")
    }
}

/// フックが static のため、並列実行すると他のテストの resetHooks() に差し替えられてしまう
@Suite(.serialized)
@MainActor
struct BaseViewModelTests {
    private func resetHooks() {
        BaseViewModel.executionTraceHandler = nil
        BaseViewModel.executionLogHandler = nil
    }

    // MARK: - show

    @Test func エラー表示_LocalizedErrorのerrorDescriptionが表示される() {
        resetHooks()
        let viewModel = BaseViewModel()

        viewModel.show(error: StubError())

        #expect(viewModel.alertItem?.message == "スタブエラーの説明")
    }

    @Test func タイトルとメッセージ表示_alertItemにセットされる() {
        resetHooks()
        let viewModel = BaseViewModel()

        viewModel.show(title: "タイトル", message: "メッセージ")

        #expect(viewModel.alertItem?.title == "タイトル")
        #expect(viewModel.alertItem?.message == "メッセージ")
        #expect(viewModel.alertItem?.actions.isEmpty == true)
    }

    @Test func dismissAction付き表示_OKボタンが1つ追加される() {
        resetHooks()
        let viewModel = BaseViewModel()

        viewModel.show(title: "タイトル", message: nil, dismissAction: {})

        #expect(viewModel.alertItem?.actions.count == 1)
    }

    // MARK: - safeExecute

    @Test func safeExecute_UseCaseの結果を返す() async throws {
        resetHooks()
        let viewModel = BaseViewModel()

        let result = await viewModel.safeExecute(StubUseCase(), input: 42)

        #expect(try result.get() == "value-42")
    }

    @Test func safeExecute_ログフックに開始と終了が通知される() async {
        resetHooks()
        defer { resetHooks() }

        var logs: [String] = []
        BaseViewModel.executionLogHandler = { logs.append($0) }
        let viewModel = BaseViewModel()

        _ = await viewModel.safeExecute(StubUseCase(), input: 1)

        #expect(logs == ["start: StubUseCase", "end: StubUseCase"])
    }

    @Test func safeExecute_トレースフックの終了クロージャが呼ばれる() async {
        resetHooks()
        defer { resetHooks() }

        var tracedNames: [String] = []
        var endCallCount = 0
        BaseViewModel.executionTraceHandler = { name in
            tracedNames.append(name)
            return { endCallCount += 1 }
        }
        let viewModel = BaseViewModel()

        _ = await viewModel.safeExecute(StubUseCase(), input: 1)

        #expect(tracedNames == ["StubUseCase"])
        #expect(endCallCount == 1)
    }
}
