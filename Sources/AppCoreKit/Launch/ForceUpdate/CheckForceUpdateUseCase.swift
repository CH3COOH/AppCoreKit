//
//  CheckForceUpdateUseCase.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import Foundation

public final class CheckForceUpdateUseCase: UseCaseProtocol, @unchecked Sendable {
    public typealias Input = CheckForceUpdateUseCase.UseCaseInput
    public typealias Output = CheckForceUpdateUseCase.UseCaseResult

    public struct UseCaseInput: Sendable {
        public let configUrl: URL

        public init(configUrl: URL) {
            self.configUrl = configUrl
        }
    }

    public enum UseCaseResult: Sendable {
        /// アップデートの必要はない
        case noUpdateNeeded

        /// 強制アップデートをおこなう
        case updateRequirement(ConfigResponse)
    }

    public enum UseCaseError: Error, Sendable {
        case invalidContent
    }

    private let urlSession: URLSession
    private let bundleShortVersion: String?

    public init(
        urlSession: URLSession = .shared,
        bundleShortVersion: String? = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    ) {
        self.urlSession = urlSession
        self.bundleShortVersion = bundleShortVersion
    }

    public func execute(_ input: Input) async -> Result<Output, any Error> {
        await loadConfig(input: input)
    }

    private func loadConfig(input: Input) async -> Result<Output, any Error> {
        do {
            var request = URLRequest(url: input.configUrl)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            request.timeoutInterval = 10
            let (data, response) = try await urlSession.data(for: request)

            guard
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200
            else {
                throw UseCaseError.invalidContent
            }

            let config = try JSONDecoder().decode(ConfigResponse.self, from: data)
            return await checkVersion(config: config)
        } catch {
            return .failure(error)
        }
    }

    func checkVersion(config: ConfigResponse) async -> Result<Output, any Error> {
        guard let version = bundleShortVersion else {
            return .success(.noUpdateNeeded)
        }

        if version.compare(config.minimumVersion, options: .numeric) == .orderedAscending {
            return .success(.updateRequirement(config))
        }

        if let specificVersions = config.specificVersions, specificVersions.contains(version) {
            return .success(.updateRequirement(config))
        }

        return .success(.noUpdateNeeded)
    }
}
