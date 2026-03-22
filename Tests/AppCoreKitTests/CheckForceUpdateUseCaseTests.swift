//
//  CheckForceUpdateUseCaseTests.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

@testable import AppCoreKit
import Testing

struct CheckForceUpdateUseCaseTests {
    struct Param: Sendable {
        let minVersion: String
        let bundleVersion: String
    }

    private func makeConfig(minVersion: String, specificVersions: [String]? = nil) -> ConfigResponse {
        ConfigResponse(url: "https://example.com/update", minimumVersion: minVersion, specificVersions: specificVersions)
    }

    @Test(arguments: [
        Param(minVersion: "2.111.0", bundleVersion: "2.11.0"),
        Param(minVersion: "2.0.0", bundleVersion: "1.0.0"),
        Param(minVersion: "1.11.0", bundleVersion: "1.9.0"),
    ])
    func アプリバージョンが最低バージョン未満の場合(param: Param) async throws {
        let useCase = CheckForceUpdateUseCase(bundleShortVersion: param.bundleVersion)
        let result = try await useCase.checkVersion(config: makeConfig(minVersion: param.minVersion)).get()
        if case .noUpdateNeeded = result {
            Issue.record("強制アップデートは必要: min:\(param.minVersion), bundle:\(param.bundleVersion)")
        }
    }

    @Test(arguments: [
        Param(minVersion: "2.11.0", bundleVersion: "2.111.0"),
        Param(minVersion: "1.0.0", bundleVersion: "2.0.0"),
        Param(minVersion: "1.9.0", bundleVersion: "1.11.0"),
        Param(minVersion: "1.11.0", bundleVersion: "1.11.0"),
        Param(minVersion: "1.9.0", bundleVersion: "1.9.0"),
    ])
    func アプリバージョンが最低バージョン以上の場合(param: Param) async throws {
        let useCase = CheckForceUpdateUseCase(bundleShortVersion: param.bundleVersion)
        let result = try await useCase.checkVersion(config: makeConfig(minVersion: param.minVersion)).get()
        if case .updateRequirement = result {
            Issue.record("強制アップデートは不要: min:\(param.minVersion), bundle:\(param.bundleVersion)")
        }
    }

    @Test
    func アプリバージョンが指定バージョンリストに含まれる場合() async throws {
        let useCase = CheckForceUpdateUseCase(bundleShortVersion: "2.0.0")
        let result = try await useCase.checkVersion(config: makeConfig(minVersion: "1.0.0", specificVersions: ["2.0.0"])).get()
        if case .noUpdateNeeded = result {
            Issue.record("強制アップデートは必要")
        }
    }

    @Test
    func bundleVersionが取得できない場合_noUpdateNeededを返す() async throws {
        let useCase = CheckForceUpdateUseCase(bundleShortVersion: nil)
        let result = try await useCase.checkVersion(config: makeConfig(minVersion: "1.0.0")).get()
        #expect(result == .noUpdateNeeded)
    }
}

extension CheckForceUpdateUseCase.UseCaseResult: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.noUpdateNeeded, .noUpdateNeeded): true
        case (.updateRequirement, .updateRequirement): true
        default: false
        }
    }
}
