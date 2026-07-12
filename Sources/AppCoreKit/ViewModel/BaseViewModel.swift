//
//  BaseViewModel.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import SwiftUI

/// 画面 ViewModel の基底クラス
///
/// アラート表示と UseCase の実行計測を提供する。
/// Firebase Performance 等との連携はアプリ側で静的フックを設定する。
///
/// ## 使用例（アプリ起動時のフック設定）
/// ```swift
/// BaseViewModel.executionLogHandler = { logger.debug($0) }
/// BaseViewModel.executionTraceHandler = { name in
///     let trace = Performance.startTrace(name: name)
///     return { trace?.stop() }
/// }
/// ```
@MainActor
open class BaseViewModel: ObservableObject {
    /// safeExecute の計測フック
    ///
    /// UseCase 名を受け取り、実行終了時に呼ばれるクロージャを返す
    /// （Firebase Performance のトレースや操作イベントの抑止などに使用する）。
    public static var executionTraceHandler: ((_ useCaseName: String) -> (() -> Void)?)?

    /// safeExecute のログ出力フック（"start: UseCase名" / "end: UseCase名" を受け取る）
    public static var executionLogHandler: ((String) -> Void)?

    @Published public var alertItem: AlertDialogItem?

    @Published public var isLoaded = false

    public init() {}

    /// エラーをアラートで表示する
    ///
    /// LocalizedError の場合は errorDescription を優先して表示する。
    open func show(error: any Error, dismissAction: (() -> Void)? = nil) {
        let message = if let e = error as? (any LocalizedError) {
            e.errorDescription ?? e.localizedDescription
        } else {
            (error as NSError).localizedDescription
        }
        show(title: LocalizedString.error, message: message, dismissAction: dismissAction)
    }

    /// タイトルとメッセージをアラートで表示する
    public func show(title: String, message: String?, dismissAction: (() -> Void)? = nil) {
        let actions: [DialogAction] = if let action = dismissAction {
            [DialogAction(title: LocalizedString.ok, action: action)]
        } else {
            []
        }

        alertItem = AlertDialogItem(title: title, message: message, actions: actions)
    }

    /// UseCase を実行し、開始・終了をフックに通知する
    public func safeExecute<T: UseCaseProtocol>(_ useCase: T, input: T.Input) async -> Result<T.Output, any Error> {
        Self.executionLogHandler?("start: \(useCase.className)")
        let onEnd = Self.executionTraceHandler?(useCase.className)
        defer {
            onEnd?()
            Self.executionLogHandler?("end: \(useCase.className)")
        }

        return await useCase.execute(input)
    }
}

private enum LocalizedString {
    static let ok = String(localized: "common.ok", bundle: .module)
    static let error = String(localized: "common.error", bundle: .module)
}
