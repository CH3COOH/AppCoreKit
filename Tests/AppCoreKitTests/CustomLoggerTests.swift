//
//  CustomLoggerTests.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

@testable import AppCoreKit
import Foundation
import Testing

/// テスト用のスレッドセーフな記録箱
private final class RecordBox: @unchecked Sendable {
    private let lock = NSLock()
    private var _messages: [String] = []
    private var _errors: [any Error] = []

    var messages: [String] {
        lock.withLock { _messages }
    }

    var errors: [any Error] {
        lock.withLock { _errors }
    }

    func append(message: String) {
        lock.withLock { _messages.append(message) }
    }

    func append(error: any Error) {
        lock.withLock { _errors.append(error) }
    }
}

struct CustomLoggerTests {
    private func makeLogger(box: RecordBox) -> CustomLogger {
        CustomLogger(
            subsystem: "jp.ch3cooh.AppCoreKitTests",
            category: "test",
            remoteLog: { box.append(message: $0) },
            errorReport: { box.append(error: $0) },
        )
    }

    @Test func debugログにDプレフィックスが付いてリモートログに渡される() {
        let box = RecordBox()
        let logger = makeLogger(box: box)

        logger.debug("hello")

        #expect(box.messages == ["D: hello"])
    }

    @Test func infoログにIプレフィックスが付いてリモートログに渡される() {
        let box = RecordBox()
        let logger = makeLogger(box: box)

        logger.info("hello")

        #expect(box.messages == ["I: hello"])
    }

    @Test func errorログにEプレフィックスが付いてリモートログに渡される() {
        let box = RecordBox()
        let logger = makeLogger(box: box)

        logger.error("hello")

        #expect(box.messages == ["E: hello"])
    }

    @Test func エラーオブジェクトはエラーレポートに転送される() {
        let box = RecordBox()
        let logger = makeLogger(box: box)
        let error = NSError(domain: "Test", code: 1)

        logger.error(error)

        #expect(box.errors.count == 1)
        #expect((box.errors.first as? NSError)?.domain == "Test")
    }

    @Test func 送信抑止キーを含むエラーはエラーレポートに転送されない() {
        let box = RecordBox()
        let logger = makeLogger(box: box)
        let error = NSError(
            domain: "Test",
            code: 1,
            userInfo: [CustomLogger.keyNoSendErrorReport: true],
        )

        logger.error(error)

        #expect(box.errors.isEmpty)
    }

    @Test func 送信抑止キーがfalseのエラーはエラーレポートに転送される() {
        let box = RecordBox()
        let logger = makeLogger(box: box)
        let error = NSError(
            domain: "Test",
            code: 1,
            userInfo: [CustomLogger.keyNoSendErrorReport: false],
        )

        logger.error(error)

        #expect(box.errors.count == 1)
    }

    @Test func ハンドラー未設定でもクラッシュしない() {
        let logger = CustomLogger(subsystem: "jp.ch3cooh.AppCoreKitTests", category: "test")

        logger.debug("hello")
        logger.info("hello")
        logger.error("hello")
        logger.error(NSError(domain: "Test", code: 1))
    }
}
