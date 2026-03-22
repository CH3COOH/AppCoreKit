//
//  UseCaseProtocol.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

public protocol UseCaseProtocol<Input, Output>: Sendable where Input: Sendable, Output: Sendable {
    associatedtype Input
    associatedtype Output

    func execute(_ input: Input) async -> Result<Output, any Error>
}

public extension UseCaseProtocol {
    var className: String {
        String(describing: type(of: self))
    }
}
