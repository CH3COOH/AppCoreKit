//
//  CheckVersionUseCase.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import Foundation

public final class CheckVersionUseCase: UseCaseProtocol, @unchecked Sendable {
    public typealias Output = CheckVersionUseCase.UseCaseResult

    public enum UseCaseResult: Sendable {
        /// 初回起動・またはアップデートしていない
        case notUpdate

        /// アップデート後の初回起動である
        case showVersionInformation
    }

    private let userDefaults: UserDefaults
    private let userDefaultsKey: String
    private let bundleShortVersion: String?

    public init(
        userDefaults: UserDefaults = .standard,
        userDefaultsKey: String = "current_version",
        bundleShortVersion: String? = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    ) {
        self.userDefaults = userDefaults
        self.userDefaultsKey = userDefaultsKey
        self.bundleShortVersion = bundleShortVersion
    }

    public func execute(_: Void) async -> Result<Output, any Error> {
        await checkVersion()
    }

    private func checkVersion() async -> Result<Output, any Error> {
        guard let version = bundleShortVersion else {
            return .success(.notUpdate)
        }
        guard let beforeVersion = userDefaults.string(forKey: userDefaultsKey) else {
            // 初めての起動だった場合はバージョンを記録して終わり
            userDefaults.set(version, forKey: userDefaultsKey)
            return .success(.notUpdate)
        }

        let compared = version.compare(beforeVersion)
        switch compared {
        case .orderedSame:
            return .success(.notUpdate)
        case .orderedAscending:
            return .success(.notUpdate)
        case .orderedDescending:
            userDefaults.set(version, forKey: userDefaultsKey)
            return .success(.showVersionInformation)
        }
    }
}
