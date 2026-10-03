//
//  ConfigResponse.swift
//  AppCoreKit
//
//  Copyright © 2026 KENJIWADA. All rights reserved.
//  Released under the MIT License.
//  https://opensource.org/licenses/mit-license.php
//

import Foundation

public struct ConfigResponse: Sendable, Decodable {
    public let url: String
    public let minimumVersion: String
    public let specificVersions: [String]?

    public init(url: String, minimumVersion: String, specificVersions: [String]?) {
        self.url = url
        self.minimumVersion = minimumVersion
        self.specificVersions = specificVersions
    }

    enum CodingKeys: String, CodingKey {
        case url
        case minimumVersion = "minimum_version"
        case specificVersions = "specific_versions"
    }
}
