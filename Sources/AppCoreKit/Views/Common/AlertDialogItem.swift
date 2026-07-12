//
//  AlertDialogItem.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import SwiftUI

/// ダイアログのボタン1つ分
public struct DialogAction: Identifiable {
    public let id = UUID()
    public var title: String
    public var role: ButtonRole?
    public var action: () -> Void

    public init(title: String, role: ButtonRole? = nil, action: @escaping () -> Void = {}) {
        self.title = title
        self.role = role
        self.action = action
    }
}

/// alert(item:) モディファイア用の表示アイテム
public struct AlertDialogItem: Identifiable {
    public let id = UUID()
    public var title: String
    public var message: String?
    /// 空の場合はシステム標準のOKボタンが表示される
    public var actions: [DialogAction]

    public init(title: String, message: String? = nil, actions: [DialogAction] = []) {
        self.title = title
        self.message = message
        self.actions = actions
    }
}

/// confirmationDialog(item:) モディファイア用の表示アイテム
/// キャンセルボタンはシステムが自動で追加するため actions に含めない
public struct ConfirmationDialogItem: Identifiable {
    public let id = UUID()
    public var title: String
    public var actions: [DialogAction]

    public init(title: String, actions: [DialogAction]) {
        self.title = title
        self.actions = actions
    }
}

public extension View {
    /// AlertDialogItem がセットされている間アラートを表示する
    func alert(item: Binding<AlertDialogItem?>) -> some View {
        alert(
            item.wrappedValue?.title ?? "",
            isPresented: Binding(
                get: { item.wrappedValue != nil },
                set: { if !$0 { item.wrappedValue = nil } },
            ),
            presenting: item.wrappedValue,
        ) { item in
            ForEach(item.actions) { action in
                Button(action.title, role: action.role, action: action.action)
            }
        } message: { item in
            if let message = item.message {
                Text(message)
            }
        }
    }

    /// ConfirmationDialogItem がセットされている間ダイアログを表示する
    /// title が空文字の場合はヘッダーを表示しない
    func confirmationDialog(item: Binding<ConfirmationDialogItem?>) -> some View {
        confirmationDialog(
            item.wrappedValue?.title ?? "",
            isPresented: Binding(
                get: { item.wrappedValue != nil },
                set: { if !$0 { item.wrappedValue = nil } },
            ),
            titleVisibility: (item.wrappedValue?.title.isEmpty ?? true) ? .hidden : .visible,
            presenting: item.wrappedValue,
        ) { item in
            ForEach(item.actions) { action in
                Button(action.title, role: action.role, action: action.action)
            }
        }
    }
}
