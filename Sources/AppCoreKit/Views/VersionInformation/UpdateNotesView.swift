//
//  UpdateNotesView.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import SwiftUI

/// 更新内容テキストを、見出し・小見出し・箇条書きに分けて表示する。
/// 各行の中の Markdown(太字・リンクなど)も解釈する
public struct UpdateNotesView: View {
    private let blocks: [UpdateNoteBlock]

    public init(text: String) {
        blocks = UpdateNotesParser.parse(text)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(blocks.indices, id: \.self) { index in
                blockView(blocks[index])
                    .padding(.top, topPadding(of: blocks[index], isFirst: index == 0))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func blockView(_ block: UpdateNoteBlock) -> some View {
        switch block {
        case let .heading(level, text):
            Text(inlineMarkdown(text))
                .font(.system(size: level == 1 ? 20 : 17, weight: .bold))
        case let .section(text):
            Text(inlineMarkdown(text))
                .font(.system(size: 15, weight: .semibold))
        case let .bullet(text):
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(verbatim: "・")
                Text(inlineMarkdown(text))
                    .lineSpacing(1.2)
            }
            .font(.system(size: 13, weight: .regular))
        case let .paragraph(text):
            Text(inlineMarkdown(text))
                .font(.system(size: 13, weight: .regular))
                .lineSpacing(1.2)
        }
    }

    private func topPadding(of block: UpdateNoteBlock, isFirst: Bool) -> CGFloat {
        guard !isFirst else {
            return 0
        }
        switch block {
        case .heading:
            return 20
        case .section:
            return 8
        case .bullet, .paragraph:
            return 0
        }
    }

    private func inlineMarkdown(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
    }
}

#Preview {
    ScrollView {
        UpdateNotesView(text: """
        # v1.1.0
        ■ 新機能
        ・**ショートカット**から記録を更新できるようにしました
        ・とても長い説明文が続く箇条書きは、2行目以降も記号の位置から下げて揃えて表示します

        ■ 改善
        - 表示を改善しました

        # v1.0.0
        初回リリースです。
        """)
        .padding(24)
    }
}
