import FirestoreCore
import FirestoreProtobuf

extension QueryCompiler {
    func makeCursor(
        _ cursor: QueryCursor,
        orders: [QuerySortOrder],
        label: String
    ) throws -> Google_Firestore_V1_Cursor {
        guard !cursor.values.isEmpty else {
            throw FirestoreError.invalidQuery("Query \(label) requires at least one value.")
        }
        guard cursor.values.count <= orders.count else {
            throw FirestoreError.invalidQuery("Query \(label) has more values than orderBy clauses.")
        }

        let values = try cursor.values.enumerated().map { index, value in
            try makeCursorValue(value, order: orders[index], path: "cursor[\(index)]")
        }
        return Google_Firestore_V1_Cursor.with {
            $0.values = values
            $0.before = cursor.before
        }
    }

    private func makeCursorValue(
        _ value: Any,
        order: QuerySortOrder,
        path: String
    ) throws -> Google_Firestore_V1_Value {
        guard order.fieldPath == "__name__" else {
            return try FirestoreValueEncoder.encodeValue(value, path: path)
        }

        if let documentReference = value as? DocumentReference {
            guard documentReference.database == query.database else {
                throw FirestoreError.databaseMismatch(
                    expected: query.database.database,
                    actual: documentReference.database.database
                )
            }
            return Google_Firestore_V1_Value.with {
                $0.referenceValue = documentReference.name
            }
        }

        guard let documentID = value as? String else {
            throw FirestoreError.invalidQuery("Document ID cursor values must be String or DocumentReference.")
        }

        return try makeDocumentIDCursorValue(documentID)
    }

    private func makeDocumentIDCursorValue(
        _ documentID: String
    ) throws -> Google_Firestore_V1_Value {
        let referencePath = try makeDocumentIDCursorReferencePath(documentID)
        return Google_Firestore_V1_Value.with {
            $0.referenceValue = referencePath
        }
    }

    private func makeDocumentIDCursorReferencePath(
        _ documentID: String
    ) throws -> String {
        let normalizedDocumentID = documentID.normalized

        if query.allDescendants {
            let relativeDocumentPath: String
            if normalizedDocumentID.hasPrefix("\(query.database.path)/") {
                relativeDocumentPath = String(normalizedDocumentID.dropFirst(query.database.path.count + 1))
            } else {
                relativeDocumentPath = normalizedDocumentID
            }

            do {
                _ = try FirestorePathValidator.documentPath(relativeDocumentPath)
            } catch {
                throw FirestoreError.invalidQuery("Collection group document ID cursor value must be a valid document path.")
            }
            return "\(query.database.path)/\(relativeDocumentPath)".normalized
        }

        guard !normalizedDocumentID.isEmpty else {
            throw FirestoreError.invalidQuery("Collection document ID cursor value must not be empty.")
        }
        guard !normalizedDocumentID.contains("/") else {
            throw FirestoreError.invalidQuery("Collection document ID cursor value must be a plain document ID.")
        }

        return [query.database.path, query.parentPath, query.collectionID, normalizedDocumentID]
            .compactMap { $0 }
            .joined(separator: "/")
            .normalized
    }
}
