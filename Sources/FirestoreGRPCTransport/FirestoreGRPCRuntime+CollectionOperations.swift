import Foundation
import FirestoreCore
import FirestoreRPC
import FirestoreGRPCStubs
import FirestoreProtobuf
import GRPCCore

extension FirestoreGRPCRuntime {
    func executeListCollections(in reference: DocumentReference) async throws -> [CollectionReference] {
        let client = Google_Firestore_V1_Firestore.Client(wrapping: grpcClient)
        let responseMapper = ReadResponseMapper(runtime: self)

        var collectionIDs: [String] = []
        var pageToken = ""

        repeat {
            let requestMessage = try DocumentRequestCompiler(database: database).makeListCollectionIdsRequest(
                parent: reference,
                pageToken: pageToken
            )

            let response = try await executeFiniteRPC(message: requestMessage) { request in
                try await client.listCollectionIds(request: request, options: self.callOptions) { response in
                    try response.message
                }
            }
            collectionIDs.append(contentsOf: response.collectionIds)
            pageToken = response.nextPageToken
        } while !pageToken.isEmpty

        return responseMapper.makeCollectionReferences(
            from: collectionIDs,
            parentDocument: reference
        )
    }

    func executeListDocuments(
        in collection: CollectionReference,
        pageSize: Int,
        readTime: Timestamp?
    ) async throws -> [DocumentReference] {
        let client = Google_Firestore_V1_Firestore.Client(wrapping: grpcClient)
        let responseMapper = ReadResponseMapper(runtime: self)

        var documents: [Google_Firestore_V1_Document] = []
        var pageToken = ""

        repeat {
            let requestMessage = try DocumentRequestCompiler(database: database).makeListDocumentsRequest(
                in: collection,
                pageSize: pageSize,
                pageToken: pageToken,
                readTime: readTime
            )

            let response = try await executeFiniteRPC(message: requestMessage) { request in
                try await client.listDocuments(request: request, options: self.callOptions) { response in
                    try response.message
                }
            }
            documents.append(contentsOf: response.documents)
            pageToken = response.nextPageToken
        } while !pageToken.isEmpty

        return try responseMapper.makeDocumentReferences(from: documents)
    }
}
