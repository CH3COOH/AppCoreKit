//
//  SafariView.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

#if os(iOS)
    import SafariServices
    import SwiftUI
    import UIKit

    /// SFSafariViewController を UIKit の present で表示する
    ///
    /// SwiftUI の sheet / fullScreenCover に載せると下から出るモーダルになってしまうため、
    /// 最前面の UIViewController から present して SFSafariViewController 本来の
    /// 右からスライドインする遷移で表示する。
    /// iOS 26 以降は `OpenURLAction.callAsFunction(_:prefersInApp:)` を使うこと。
    enum SafariViewPresenter {
        @MainActor
        static func present(url: URL) {
            guard let presenter = topViewController() else { return }
            let vc = SFSafariViewController(url: url)
            vc.preferredControlTintColor = UIColor(Color.accentColor)
            presenter.present(vc, animated: true)
        }

        @MainActor
        private static func topViewController() -> UIViewController? {
            let windowScenes = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
            let scene = windowScenes.first { $0.activationState == .foregroundActive } ?? windowScenes.first
            var top = scene?.keyWindow?.rootViewController
            while let presented = top?.presentedViewController {
                top = presented
            }
            return top
        }
    }
#endif
