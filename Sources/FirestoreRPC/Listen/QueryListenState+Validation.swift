import Foundation
import FirestoreCore
import FirestoreProtobuf

extension QueryListenState {
    func validateDocumentName(_ name: String) throws {
        let reference = try DocumentReference(
            name: name,
            runtime: runtime as? any FirestoreReferenceRuntime
        )
        try validateDatabase(reference.database)
    }

    func validateDatabase(_ database: Database) throws {
        guard let runtime else {
            return
        }
        guard database == runtime.runtimeDatabase else {
            throw FirestoreError.databaseMismatch(
                expected: runtime.runtimeDatabase.database,
                actual: database.database
            )
        }
    }

    func validateExistenceFilter(_ filter: Google_Firestore_V1_ExistenceFilter) throws {
        guard filter.targetID == targetID else {
            return
        }

        if Int(filter.count) != documents.count {
            throw ListenResyncRequired(
                targetID: targetID,
                expectedCount: documents.count,
                actualCount: Int(filter.count)
            )
        }
    }
}
