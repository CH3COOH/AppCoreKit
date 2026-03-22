//
//  CheckNetworkAccessUseCase.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import Foundation

public final class CheckNetworkAccessUseCase: UseCaseProtocol, @unchecked Sendable {
    public struct UseCaseInput: Sendable {
        public let connectivityURL: URL

        public init(connectivityURL: URL) {
            self.connectivityURL = connectivityURL
        }
    }

    public enum UseCaseError: Error, Sendable {
        case unexpectedResponseContent
    }

    private let urlSession: URLSession

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    public func execute(_ input: UseCaseInput) async -> Result<Void, any Error> {
        await checkNetworkAccess(url: input.connectivityURL)
    }

    /// 指定された URL へアクセスして、正しい文言が得られるか調べる
    private func checkNetworkAccess(url: URL) async -> Result<Void, any Error> {
        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            request.timeoutInterval = 10
            let (data, response) = try await urlSession.data(for: request)
            if
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200,
                let dataString = String(data: data, encoding: .utf8),
                dataString == "Success"
            {
                return .success(())
            } else {
                throw UseCaseError.unexpectedResponseContent
            }
        } catch {
            return .failure(error)
        }
    }
}
