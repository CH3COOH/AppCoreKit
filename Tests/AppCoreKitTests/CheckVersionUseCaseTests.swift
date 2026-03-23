//
//  CheckVersionUseCaseTests.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

@testable import AppCoreKit
import Foundation
import Testing

struct CheckVersionUseCaseTests {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "AppCoreKitTests.CheckVersionUseCase.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test func bundleVersionが取得できない場合_notUpdateを返す() async throws {
        let useCase = CheckVersionUseCase(
            userDefaults: makeDefaults(),
            bundleShortVersion: nil
        )
        let output = try await useCase.execute(()).get()
        #expect(output == .notUpdate)
    }

    @Test func 初回起動の場合_notUpdateを返す() async throws {
        let useCase = CheckVersionUseCase(
            userDefaults: makeDefaults(),
            bundleShortVersion: "1.0.0"
        )
        let output = try await useCase.execute(()).get()
        #expect(output == .notUpdate)
    }

    @Test func 同一バージョンの場合_notUpdateを返す() async throws {
        let defaults = makeDefaults()
        defaults.set("1.0.0", forKey: "current_version")
        let useCase = CheckVersionUseCase(
            userDefaults: defaults,
            bundleShortVersion: "1.0.0"
        )
        let output = try await useCase.execute(()).get()
        #expect(output == .notUpdate)
    }

    @Test func バージョンアップ後の初回起動_showVersionInformationを返す() async throws {
        let defaults = makeDefaults()
        defaults.set("1.0.0", forKey: "current_version")
        let useCase = CheckVersionUseCase(
            userDefaults: defaults,
            bundleShortVersion: "2.0.0"
        )
        let output = try await useCase.execute(()).get()
        #expect(output == .showVersionInformation)
    }

    @Test func ダウングレードの場合_notUpdateを返す() async throws {
        let defaults = makeDefaults()
        defaults.set("2.0.0", forKey: "current_version")
        let useCase = CheckVersionUseCase(
            userDefaults: defaults,
            bundleShortVersion: "1.0.0"
        )
        let output = try await useCase.execute(()).get()
        #expect(output == .notUpdate)
    }

    @Test func バージョンアップ後_UserDefaultsのバージョンが更新される() async throws {
        let defaults = makeDefaults()
        defaults.set("1.0.0", forKey: "current_version")
        let useCase = CheckVersionUseCase(
            userDefaults: defaults,
            bundleShortVersion: "2.0.0"
        )
        _ = await useCase.execute(())
        #expect(defaults.string(forKey: "current_version") == "2.0.0")
    }

    @Test func カスタムキーを使用できる() async throws {
        let defaults = makeDefaults()
        defaults.set("1.0.0", forKey: "my_version_key")
        let useCase = CheckVersionUseCase(
            userDefaults: defaults,
            userDefaultsKey: "my_version_key",
            bundleShortVersion: "2.0.0"
        )
        let output = try await useCase.execute(()).get()
        #expect(output == .showVersionInformation)
    }
}
