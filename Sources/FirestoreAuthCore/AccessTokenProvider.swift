import Foundation

public protocol AccessScope: Sendable {
    var value: String { get }
}

public protocol AccessTokenProvider: Sendable {
    var scope: any AccessScope { get }

    func getAccessToken(expirationDuration: TimeInterval) async throws -> String
}
