import FirestoreCore
import Foundation

public struct FirestoreMongoGeoIndex: Equatable, Sendable {
    public let fieldPath: String

    public init(fieldPath: String) throws {
        if fieldPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw FirestoreError.invalidFieldPath("Mongo-compatible geo index field path must not be empty.")
        }

        self.fieldPath = fieldPath
    }

    public var document: FirestoreMongoDocument {
        [
            fieldPath: .string("2dsphere")
        ]
    }
}
