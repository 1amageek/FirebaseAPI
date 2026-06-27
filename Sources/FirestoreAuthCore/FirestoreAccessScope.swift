import Foundation

public struct FirestoreAccessScope: AccessScope, Equatable, Sendable {
    public let value: String

    public init(_ value: String) {
        self.value = value
    }

    public static let datastore = FirestoreAccessScope("https://www.googleapis.com/auth/datastore")
    public static let cloudPlatform = FirestoreAccessScope("https://www.googleapis.com/auth/cloud-platform")
}
