//
//  UpdateNotesParserTests.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

@testable import AppCoreKitCore
import Testing

struct UpdateNotesParserTests {
    @Test func シャープで始まる行_見出しとして階層つきで返す() {
        let blocks = UpdateNotesParser.parse("# v1.1.0\n## 詳細\n### 補足")
        #expect(blocks == [
            .heading(level: 1, text: "v1.1.0"),
            .heading(level: 2, text: "詳細"),
            .heading(level: 3, text: "補足"),
        ])
    }

    @Test func シャープの後に空白がない行_見出しにしない() {
        let blocks = UpdateNotesParser.parse("#1 位になりました")
        #expect(blocks == [.paragraph("#1 位になりました")])
    }

    @Test func 黒い四角で始まる行_小見出しとして記号を除いて返す() {
        let blocks = UpdateNotesParser.parse("■ 新機能\n■改善")
        #expect(blocks == [.section("新機能"), .section("改善")])
    }

    @Test func 中黒やハイフンで始まる行_箇条書きとして記号を除いて返す() {
        let blocks = UpdateNotesParser.parse("・不具合を修正しました\n- 表示を改善しました\n* 速度を改善しました")
        #expect(blocks == [
            .bullet("不具合を修正しました"),
            .bullet("表示を改善しました"),
            .bullet("速度を改善しました"),
        ])
    }

    @Test func 空行_読み飛ばす() {
        let blocks = UpdateNotesParser.parse("# v1.0.1\n\n・修正\n\n\n# v1.0.0\n")
        #expect(blocks == [
            .heading(level: 1, text: "v1.0.1"),
            .bullet("修正"),
            .heading(level: 1, text: "v1.0.0"),
        ])
    }

    @Test func 記号のない行_段落として前後の空白を除いて返す() {
        let blocks = UpdateNotesParser.parse("  初回リリースです。 \r\n")
        #expect(blocks == [.paragraph("初回リリースです。")])
    }
}
