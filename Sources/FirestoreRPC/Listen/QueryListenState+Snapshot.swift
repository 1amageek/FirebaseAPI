import Foundation
import FirestoreCore

extension QueryListenState {
    mutating func appendPendingChange(_ change: DocumentChange?) {
        guard let change else {
            return
        }
        pendingChanges.append(change)
    }

    mutating func flushPendingChangesAfterInitialSnapshot() -> QuerySnapshot? {
        guard hasEmittedInitialSnapshot, !pendingChanges.isEmpty else {
            return nil
        }

        let changes = pendingChanges
        pendingChanges.removeAll()
        return makeSnapshot(documentChanges: changes)
    }

    func initialDocumentChanges() -> [DocumentChange] {
        documents.enumerated().map { index, document in
            DocumentChange(
                type: .added,
                document: document,
                oldIndex: DocumentChange.notFoundIndex,
                newIndex: index
            )
        }
    }

    func makeSnapshot(documentChanges: [DocumentChange]) -> QuerySnapshot {
        QuerySnapshot(
            documents: documents,
            metadata: .serverSynchronized,
            documentChanges: documentChanges
        )
    }

    func makeDocumentReference(name: String) throws -> DocumentReference {
        let reference = try DocumentReference(
            name: name,
            runtime: runtime as? any FirestoreReferenceRuntime
        )
        try validateDatabase(reference.database)
        return reference
    }
}
