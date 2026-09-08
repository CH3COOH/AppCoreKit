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
            bundleShortVersion: nil,
        )
        let output = try await useCase.execute(()).get()
        #expect(output == .notUpdate)
    }

    @Test func 初回起動の場合_notUpdateを返す() async throws {
        let useCase = CheckVersionUseCase(
            userDefaults: makeDefaults(),
            bundleShortVersion: "1.0.0",
        )
        let output = try await useCase.execute(()).get()
        #expect(output == .notUpdate)
    }

    @Test func 初回起動の場合_UserDefaultsにバージョンが記録される() async {
        let defaults = makeDefaults()
        let useCase = CheckVersionUseCase(
            userDefaults: defaults,
            bundleShortVersion: "1.0.0",
        )
        _ = await useCase.execute(())
        #expect(defaults.string(forKey: "current_version") == "1.0.0")
    }

    @Test func bundleVersionが取得できない場合_UserDefaultsを書き換えない() async {
        let defaults = makeDefaults()
        defaults.set("1.0.0", forKey: "current_version")
        let useCase = CheckVersionUseCase(
            userDefaults: defaults,
            bundleShortVersion: nil,
        )
        _ = await useCase.execute(())
        #expect(defaults.string(forKey: "current_version") == "1.0.0")
    }

    @Test func 同一バージョンの場合_notUpdateを返す() async throws {
        let defaults = makeDefaults()
        defaults.set("1.0.0", forKey: "current_version")
        let useCase = CheckVersionUseCase(
            userDefaults: defaults,
            bundleShortVersion: "1.0.0",
        )
        let output = try await useCase.execute(()).get()
        #expect(output == .notUpdate)
    }

    @Test func バージョンアップ後の初回起動_showVersionInformationを返す() async throws {
        let defaults = makeDefaults()
        defaults.set("1.0.0", forKey: "current_version")
        let useCase = CheckVersionUseCase(
            userDefaults: defaults,
            bundleShortVersion: "2.0.0",
        )
        let output = try await useCase.execute(()).get()
        #expect(output == .showVersionInformation)
    }

    @Test func ダウングレードの場合_notUpdateを返す() async throws {
        let defaults = makeDefaults()
        defaults.set("2.0.0", forKey: "current_version")
        let useCase = CheckVersionUseCase(
            userDefaults: defaults,
            bundleShortVersion: "1.0.0",
        )
        let output = try await useCase.execute(()).get()
        #expect(output == .notUpdate)
    }

    @Test func ダウングレードの場合_UserDefaultsのバージョンが更新される() async {
        // 記録を進めないと、比較に失敗した端末が古い値のまま固定されてしまうため
        let defaults = makeDefaults()
        defaults.set("2.0.0", forKey: "current_version")
        let useCase = CheckVersionUseCase(
            userDefaults: defaults,
            bundleShortVersion: "1.0.0",
        )
        _ = await useCase.execute(())
        #expect(defaults.string(forKey: "current_version") == "1.0.0")
    }

    // MARK: - 桁数が繰り上がるバージョン

    @Test(
        "パッチ番号が2桁に繰り上がる場合もアップデートとして扱う",
        arguments: [
            ("2.9.9", "2.9.10"),
            ("2.9.9", "2.9.17"),
            ("2.4.9", "2.4.11"),
            ("3.9.9", "3.10.0"),
            ("2.9.17", "3.0.0"),
        ],
    )
    func 桁上がりを含むバージョンアップ(before: String, after: String) async throws {
        let defaults = makeDefaults()
        defaults.set(before, forKey: "current_version")
        let useCase = CheckVersionUseCase(
            userDefaults: defaults,
            bundleShortVersion: after,
        )
        let output = try await useCase.execute(()).get()
        #expect(output == .showVersionInformation)
        #expect(defaults.string(forKey: "current_version") == after)
    }

    @Test func 桁上がりを含むダウングレードはnotUpdateを返す() async throws {
        let defaults = makeDefaults()
        defaults.set("2.9.10", forKey: "current_version")
        let useCase = CheckVersionUseCase(
            userDefaults: defaults,
            bundleShortVersion: "2.9.9",
        )
        let output = try await useCase.execute(()).get()
        #expect(output == .notUpdate)
        #expect(defaults.string(forKey: "current_version") == "2.9.9")
    }

    @Test func 記録が古いまま固定されない() async throws {
        // 比較に失敗して記録が進まないと、以降どのバージョンに上げても
        // showVersionInformation を返せなくなる（#14）
        let defaults = makeDefaults()
        defaults.set("2.9.9", forKey: "current_version")

        for version in ["2.9.10", "2.9.11", "2.9.17", "3.0.0"] {
            let useCase = CheckVersionUseCase(
                userDefaults: defaults,
                bundleShortVersion: version,
            )
            let output = try await useCase.execute(()).get()
            #expect(output == .showVersionInformation, "\(version) がアップデートとして扱われていない")
            #expect(defaults.string(forKey: "current_version") == version)
        }
    }

    @Test func バージョンアップ後_UserDefaultsのバージョンが更新される() async {
        let defaults = makeDefaults()
        defaults.set("1.0.0", forKey: "current_version")
        let useCase = CheckVersionUseCase(
            userDefaults: defaults,
            bundleShortVersion: "2.0.0",
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
            bundleShortVersion: "2.0.0",
        )
        let output = try await useCase.execute(()).get()
        #expect(output == .showVersionInformation)
    }
}
