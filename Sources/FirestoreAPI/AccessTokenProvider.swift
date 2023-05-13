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

    var scope: any AccessScope { get }

    func getAccessToken(expirationDuration: TimeInterval) async throws -> String
}
