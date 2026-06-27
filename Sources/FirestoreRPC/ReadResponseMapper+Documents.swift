import FirestoreCore
import FirestoreProtobuf

extension ReadResponseMapper {
    package func makeDocumentSnapshot(
        from document: Google_Firestore_V1_Document,
        requestedReference: DocumentReference
    ) throws -> DocumentSnapshot {
        try validateDatabase(requestedReference.database)
        let responseReference = try makeDocumentReference(name: document.name)
        guard responseReference.path == requestedReference.path else {
            throw FirestoreError.invalidPath(
                "Document response name must match the requested document reference."
            )
        }

        return DocumentSnapshot(
            fields: try decoder.decode(fields: document.fields),
            documentReference: requestedReference
        )
    }

    package func makeMissingDocumentSnapshot(for reference: DocumentReference) -> DocumentSnapshot {
        DocumentSnapshot(documentReference: reference)
    }

    package func makeDocumentSnapshots(
        from responses: [Google_Firestore_V1_BatchGetDocumentsResponse]
    ) throws -> [DocumentSnapshot] {
        var snapshots: [DocumentSnapshot] = []
        for response in responses {
            switch response.result {
            case .found(let document):
                let documentReference = try makeDocumentReference(name: document.name)
                snapshots.append(
                    DocumentSnapshot(
                        fields: try decoder.decode(fields: document.fields),
                        documentReference: documentReference
                    )
                )
            case .missing(let name):
                let documentReference = try makeDocumentReference(name: name)
                snapshots.append(
                    DocumentSnapshot(
                        fields: nil,
                        documentReference: documentReference
                    )
                )
            case .none:
                continue
            }
        }
        return snapshots
    }

    package func makeQuerySnapshot(
        from responses: [Google_Firestore_V1_RunQueryResponse],
        requiresResultOrderReversal: Bool
    ) throws -> QuerySnapshot {
        var documents: [QueryDocumentSnapshot] = []
        for response in responses {
            guard response.hasDocument else { continue }
            let document = response.document
            let documentReference = try makeDocumentReference(name: document.name)
            documents.append(
                QueryDocumentSnapshot(
                    fields: try decoder.decode(fields: document.fields),
                    documentReference: documentReference
                )
            )
        }

        let orderedDocuments = requiresResultOrderReversal ? Array(documents.reversed()) : documents
        return QuerySnapshot(documents: orderedDocuments)
    }

    package func makeCollectionReferences(
        from collectionIDs: [String],
        parentDocument: DocumentReference
    ) -> [CollectionReference] {
        collectionIDs.map { collectionID in
            CollectionReference(
                parentDocument.database,
                parentPath: parentDocument.path,
                collectionID: collectionID,
                runtime: runtime
            )
        }
    }

    package func makeDocumentReferences(
        from documents: [Google_Firestore_V1_Document]
    ) throws -> [DocumentReference] {
        try documents.map { document in
            try makeDocumentReference(name: document.name)
        }
    }

    func makeDocumentReference(name: String) throws -> DocumentReference {
        let reference = try DocumentReference(name: name, runtime: runtime)
        try validateDatabase(reference.database)
        return reference
    }

    func validateDatabase(_ database: Database) throws {
        guard database == runtime.runtimeDatabase else {
            throw FirestoreError.databaseMismatch(
                expected: runtime.runtimeDatabase.database,
                actual: database.database
            )
        }
    }
}
