//
//  CustomLogger.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import Foundation
import os

/// os.Logger のラッパー
///
/// リモートログ・エラーレポートの送信はアプリ側の責務のため、コールバックで注入する。
///
/// ## 使用例
/// ```swift
/// let logger = CustomLogger(
///     subsystem: "jp.ch3cooh.NSEasyConnect",
///     category: "general",
///     remoteLog: { Crashlytics.crashlytics().log($0) },
///     errorReport: { Crashlytics.crashlytics().record(error: $0) },
/// )
/// ```
public struct CustomLogger: Sendable {
    /// エラーレポートを送信したくない場合（例: UseCase 側で送信済み）に
    /// NSError の userInfo に指定するキー。
    /// 既存アプリとの互換のため値は "NO_SEND_CRASHLYTICS_KEY" を維持する
    public static let keyNoSendErrorReport = "NO_SEND_CRASHLYTICS_KEY"

    private let logger: Logger
    private let remoteLog: (@Sendable (String) -> Void)?
    private let errorReport: (@Sendable (any Error) -> Void)?

    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
            return true
        #else
            return false
        #endif
    }

    /// - Parameters:
    ///   - subsystem: os.Logger の subsystem
    ///   - category: os.Logger の category
    ///   - remoteLog: リモートログ送信ハンドラー。レベルプレフィックス付きメッセージ
    ///     （"D: xxx" 等）を受け取る。シミュレータでは呼ばれない
    ///   - errorReport: エラーレポート送信ハンドラー
    public init(
        subsystem: String,
        category: String,
        remoteLog: (@Sendable (String) -> Void)? = nil,
        errorReport: (@Sendable (any Error) -> Void)? = nil,
    ) {
        logger = Logger(subsystem: subsystem, category: category)
        self.remoteLog = remoteLog
        self.errorReport = errorReport
    }

    public func info(_ message: String) {
        log(.info, message)
    }

    public func debug(_ message: String) {
        log(.debug, message)
    }

    public func error(_ message: String) {
        log(.error, message)
    }

    /// エラーオブジェクトをログ出力し、errorReport ハンドラーに転送する
    ///
    /// NSError の userInfo に `keyNoSendErrorReport: true` が含まれる場合は転送しない。
    public func error(_ error: any Error) {
        logger.error("\(error.localizedDescription)")

        let nsError = error as NSError
        if let shouldNotSend = nsError.userInfo[Self.keyNoSendErrorReport] as? Bool, shouldNotSend == true {
            return
        }

        errorReport?(error)
    }

    private func log(_ level: OSLogType, _ message: String) {
        switch level {
        case .debug:
            logger.debug("\(message)")
            sendRemoteLog("D: \(message)")
        case .info:
            logger.info("\(message)")
            sendRemoteLog("I: \(message)")
        case .error:
            logger.error("\(message)")
            sendRemoteLog("E: \(message)")
        default:
            break
        }
    }

    private func sendRemoteLog(_ message: String) {
        guard !isSimulator else { return }
        remoteLog?(message)
    }
}
