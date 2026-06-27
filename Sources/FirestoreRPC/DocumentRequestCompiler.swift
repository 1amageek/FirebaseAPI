import Foundation
import FirestoreCore
import FirestoreProtobuf
import SwiftProtobuf

package struct DocumentRequestCompiler {
    package let database: Database

    package init(database: Database) {
        self.database = database
    }

    package func makeGetDocumentRequest(
        for reference: DocumentReference
    ) throws -> Google_Firestore_V1_GetDocumentRequest {
        try validateDatabase(reference.database)
        return Google_Firestore_V1_GetDocumentRequest.with {
            $0.name = reference.name
        }
    }

    package func makeBatchGetDocumentsRequest(
        for references: [DocumentReference],
        transactionID: Data? = nil
    ) throws -> Google_Firestore_V1_BatchGetDocumentsRequest {
        try references.forEach { try validateDatabase($0.database) }
        return Google_Firestore_V1_BatchGetDocumentsRequest.with {
            $0.database = database.database
            $0.documents = references.map(\.name)
            if let transactionID {
                $0.transaction = transactionID
            }
        }
    }

    package func makeListCollectionIdsRequest(
        parent reference: DocumentReference,
        pageToken: String = ""
    ) throws -> Google_Firestore_V1_ListCollectionIdsRequest {
        try validateDatabase(reference.database)
        return Google_Firestore_V1_ListCollectionIdsRequest.with {
            $0.parent = reference.name
            $0.pageToken = pageToken
        }
    }

    package func makeListDocumentsRequest(
        in collection: CollectionReference,
        pageSize: Int = 0,
        pageToken: String = "",
        readTime: Timestamp? = nil
    ) throws -> Google_Firestore_V1_ListDocumentsRequest {
        try validateDatabase(collection.database)
        guard pageSize >= 0 else {
            throw FirestoreError.invalidQuery("ListDocuments pageSize must be greater than or equal to zero.")
        }
        guard pageSize <= Int(Int32.max) else {
            throw FirestoreError.invalidQuery("ListDocuments pageSize exceeds Int32 range.")
        }

        return Google_Firestore_V1_ListDocumentsRequest.with {
            $0.parent = collection.name
            $0.collectionID = collection.collectionID
            $0.pageSize = Int32(pageSize)
            $0.pageToken = pageToken
            $0.showMissing = true
            if let readTime {
                $0.readTime = Google_Protobuf_Timestamp.with {
                    $0.seconds = readTime.seconds
                    $0.nanos = readTime.nanos
                }
            }
        }
    }

    private func validateDatabase(_ other: Database) throws {
        guard other == database else {
            throw FirestoreError.databaseMismatch(
                expected: database.database,
                actual: other.database
            )
        }
    }
}
