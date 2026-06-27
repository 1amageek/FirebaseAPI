import Foundation
import FirestoreCore
import FirestoreProtobuf
import FirestoreRPCSupport

extension QueryListenState {
    mutating func upsert(_ document: Google_Firestore_V1_Document) throws -> DocumentChange {
        let documentReference = try makeDocumentReference(name: document.name)
        let snapshot = QueryDocumentSnapshot(
            fields: try FirestoreDocumentDataDecoder(
                runtime: runtime as? any FirestoreReferenceRuntime
            ).decode(fields: document.fields),
            documentReference: documentReference
        )

        if let currentIndex = indexesByName[document.name] {
            let oldIndex = currentIndex
            removeDocumentStorage(at: currentIndex)
            let newIndex = insertionIndex(for: document)
            insertDocumentStorage(document, snapshot: snapshot, at: newIndex)
            return DocumentChange(
                type: .modified,
                document: snapshot,
                oldIndex: oldIndex,
                newIndex: newIndex
            )
        }

        let newIndex = insertionIndex(for: document)
        insertDocumentStorage(document, snapshot: snapshot, at: newIndex)
        return DocumentChange(
            type: .added,
            document: snapshot,
            oldIndex: DocumentChange.notFoundIndex,
            newIndex: newIndex
        )
    }

    mutating func removeDocument(named documentName: String) -> DocumentChange? {
        guard let oldIndex = indexesByName.removeValue(forKey: documentName) else {
            return nil
        }

        let removedDocument = removeDocumentStorage(at: oldIndex)

        return DocumentChange(
            type: .removed,
            document: removedDocument,
            oldIndex: oldIndex,
            newIndex: DocumentChange.notFoundIndex
        )
    }

    @discardableResult
    mutating func removeDocumentStorage(at index: Int) -> QueryDocumentSnapshot {
        let removedDocument = documents.remove(at: index)
        rpcDocuments.remove(at: index)
        documentNames.remove(at: index)
        rebuildIndexes(startingAt: index)
        return removedDocument
    }

    mutating func insertDocumentStorage(
        _ document: Google_Firestore_V1_Document,
        snapshot: QueryDocumentSnapshot,
        at index: Int
    ) {
        documents.insert(snapshot, at: index)
        rpcDocuments.insert(document, at: index)
        documentNames.insert(document.name, at: index)
        rebuildIndexes(startingAt: index)
    }

    mutating func rebuildIndexes(startingAt startIndex: Int) {
        guard startIndex < documents.count else {
            return
        }

        for index in startIndex..<documents.count {
            indexesByName[documentNames[index]] = index
        }
    }

    mutating func reset() {
        documents.removeAll()
        rpcDocuments.removeAll()
        documentNames.removeAll()
        indexesByName.removeAll()
        pendingChanges.removeAll()
        hasEmittedInitialSnapshot = false
    }
}
