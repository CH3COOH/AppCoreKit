//
//  UpdateNotesParser.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import Foundation

/// 更新内容テキスト(Markdown 風)の1行分の表示単位
enum UpdateNoteBlock: Equatable {
    /// `# v1.0.0` のような見出し。level は # の数
    case heading(level: Int, text: String)
    /// `■ 新機能` のような小見出し
    case section(String)
    /// `・` / `- ` / `* ` で始まる箇条書き
    case bullet(String)
    /// それ以外の行
    case paragraph(String)
}

/// 更新内容テキストを行ごとに表示単位へ分ける。
/// SwiftUI の Text は行内の Markdown(太字・リンクなど)しか解釈しないため、見出しと箇条書きはここで判定する
enum UpdateNotesParser {
    private static let bulletMarkers = ["・", "- ", "* "]

    static func parse(_ text: String) -> [UpdateNoteBlock] {
        text.components(separatedBy: .newlines).compactMap { rawLine in
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else {
                return nil
            }

            if let heading = parseHeading(line) {
                return heading
            }
            if line.hasPrefix("■") {
                return .section(content(of: line, droppingPrefix: "■"))
            }
            if let marker = bulletMarkers.first(where: { line.hasPrefix($0) }) {
                return .bullet(content(of: line, droppingPrefix: marker))
            }
            return .paragraph(line)
        }
    }

    private static func parseHeading(_ line: String) -> UpdateNoteBlock? {
        let level = line.prefix(while: { $0 == "#" }).count
        // "#1 位" のように # の直後に空白がないものは見出しとして扱わない
        guard (1 ... 6).contains(level), line.dropFirst(level).first == " " else {
            return nil
        }
        return .heading(level: level, text: content(of: line, droppingPrefix: String(repeating: "#", count: level)))
    }

    private static func content(of line: String, droppingPrefix prefix: String) -> String {
        String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
    }
}
