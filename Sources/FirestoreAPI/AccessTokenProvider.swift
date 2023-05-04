//
//  AccessTokenProvider.swift
//  
//
//  Created by Norikazu Muramoto on 2023/05/04.
//

import Foundation

public protocol AccessScope {
    var value: String { get }
}

public protocol AccessTokenProvider {
    func getAccessToken(scope: AccessScope, expirationDuration: TimeInterval) async throws -> String
}
