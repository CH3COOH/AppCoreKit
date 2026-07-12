//
//  UIViewController+SwiftUI.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

#if os(iOS)
    import SwiftUI
    import UIKit

    /// SwiftUI ビューから提示元の UIViewController を参照するためのホルダー
    public struct ViewControllerHolder {
        public weak var value: UIViewController?

        public init(_ value: UIViewController?) {
            self.value = value
        }
    }

    public extension EnvironmentValues {
        @Entry var viewController: ViewControllerHolder = .init(nil)
    }

    public extension UIViewController {
        /// SwiftUI ビューをホストする UIViewController を生成する
        ///
        /// 生成した hosting controller を environment の `viewController` として注入するため、
        /// SwiftUI 側から画面遷移やモーダル表示を行える。
        /// アプリ固有の environmentObject（AppState 等）は builder 内で注入すること。
        static func hostingController(@ViewBuilder builder: () -> some View) -> UIViewController {
            // Must instantiate HostingController with some sort of view...
            let toPresent = UIHostingController(rootView: AnyView(EmptyView()))
            // ... but then we can reset rootView to include the environment
            toPresent.rootView = AnyView(
                builder()
                    .environment(\.viewController, ViewControllerHolder(toPresent)),
            )

            return toPresent
        }
    }
#endif
