import Foundation

public enum FirestoreSource: Sendable, Equatable {
    case `default`
    case server
    case cache

    package func validateServerSideRead() throws {
        guard self != .cache else {
            throw FirestoreError.invalidOperation("Cache-only reads are not available in server-side Admin.")
        }
    }
}
