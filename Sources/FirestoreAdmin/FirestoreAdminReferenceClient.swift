import Foundation
import FirestoreCore

public protocol FirestoreAdminReferenceClient: Sendable {
    func collectionGroup(_ groupID: String) throws -> CollectionGroup
    func collection(_ collectionPath: String) throws -> CollectionReference
    func document(_ documentPath: String) throws -> DocumentReference
}
