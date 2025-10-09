//
//  Query+gRPC.swift
//
//
//  Created by Norikazu Muramoto on 2023/04/10.
//

import Foundation
import GRPCCore
import GRPCProtobuf
import SwiftProtobuf

extension Query {

    func makeQuery() -> Google_Firestore_V1_StructuredQuery {

        return Google_Firestore_V1_StructuredQuery.with { query in

            query.from = [Google_Firestore_V1_StructuredQuery.CollectionSelector.with {
                $0.collectionID = collectionID
                $0.allDescendants = allDescendants
            }]

            for predicate in self.predicates {

                switch predicate {
                case .or(_):
                    query.where = predicate.makeFilter(database: database, collectionID: collectionID)!
                case .and(_):
                    query.where = predicate.makeFilter(database: database, collectionID: collectionID)!
                case .isEqualTo(_, _):
                    query.where = predicate.makeFilter(database: database, collectionID: collectionID)!
                case .isNotEqualTo(_, _):
                    query.where = predicate.makeFilter(database: database, collectionID: collectionID)!
                case .isIn(_, _):
                    query.where = predicate.makeFilter(database: database, collectionID: collectionID)!
                case .isNotIn(_, _):
                    query.where = predicate.makeFilter(database: database, collectionID: collectionID)!
                case .arrayContains(_, _):
                    query.where = predicate.makeFilter(database: database, collectionID: collectionID)!
                case .arrayContainsAny(_, _):
                    query.where = predicate.makeFilter(database: database, collectionID: collectionID)!
                case .isLessThan(_, _):
                    query.where = predicate.makeFilter(database: database, collectionID: collectionID)!
                case .isGreaterThan(_, _):
                    query.where = predicate.makeFilter(database: database, collectionID: collectionID)!
                case .isLessThanOrEqualTo(_, _):
                    query.where = predicate.makeFilter(database: database, collectionID: collectionID)!
                case .isGreaterThanOrEqualTo(_, _):
                    query.where = predicate.makeFilter(database: database, collectionID: collectionID)!
                case .orderBy(let field, let descending):
                    query.orderBy.append(Google_Firestore_V1_StructuredQuery.Order.with {
                        $0.field = Google_Firestore_V1_StructuredQuery.FieldReference.with {
                            $0.fieldPath = field
                        }
                        $0.direction = descending ? .descending : .ascending
                    })
                case .limitTo(let count):
                    query.limit = Google_Protobuf_Int32Value.with {
                        $0.value = Int32(count)
                    }
                case .limitToLast(let count):
                    query.limit = Google_Protobuf_Int32Value.with {
                        $0.value = Int32(count)
                    }
                    query.orderBy.append(Google_Firestore_V1_StructuredQuery.Order.with {
                        $0.field = Google_Firestore_V1_StructuredQuery.FieldReference.with {
                            $0.fieldPath = "__name__"
                        }
                        $0.direction = .descending
                    })
                case .isEqualToDocumentID(_):
                    query.where = predicate.makeFilter(database: database, collectionID: collectionID)!
                case .isNotEqualToDocumentID(_):
                    query.where = predicate.makeFilter(database: database, collectionID: collectionID)!
                case .isInDocumentID(_):
                    query.where = predicate.makeFilter(database: database, collectionID: collectionID)!
                case .isNotInDocumentID(_):
                    query.where = predicate.makeFilter(database: database, collectionID: collectionID)!
                case .arrayContainsDocumentID(_):
                    query.where = predicate.makeFilter(database: database, collectionID: collectionID)!
                case .arrayContainsAnyDocumentID(_):
                    query.where = predicate.makeFilter(database: database, collectionID: collectionID)!
                case .isLessThanDocumentID(_):
                    query.where = predicate.makeFilter(database: database, collectionID: collectionID)!
                case .isGreaterThanDocumentID(_):
                    query.where = predicate.makeFilter(database: database, collectionID: collectionID)!
                case .isLessThanOrEqualToDocumentID(_):
                    query.where = predicate.makeFilter(database: database, collectionID: collectionID)!
                case .isGreaterThanOrEqualToDocumentID(_):
                    query.where = predicate.makeFilter(database: database, collectionID: collectionID)!
                }
            }
        }
    }

    public func getDocuments<Transport: ClientTransport>(firestore: Firestore<Transport>, metadata: Metadata) async throws -> QuerySnapshot {
        let client = Google_Firestore_V1_Firestore.Client(wrapping: firestore.grpcClient)

        var requestMessage = Google_Firestore_V1_RunQueryRequest()
        requestMessage.parent = name
        requestMessage.structuredQuery = makeQuery()

        let request = ClientRequest<Google_Firestore_V1_RunQueryRequest>(
            message: requestMessage,
            metadata: metadata
        )

        nonisolated(unsafe) var documents: [QueryDocumentSnapshot] = []

        try await client.runQuery(
            request: request,
            serializer: ProtobufSerializer<Google_Firestore_V1_RunQueryRequest>(),
            deserializer: ProtobufDeserializer<Google_Firestore_V1_RunQueryResponse>()
        ) { response in
            for try await message in response.messages {
                if message.hasDocument {
                    let documentReference = DocumentReference(name: message.document.name)
                    let documentSnapshot = QueryDocumentSnapshot(document: message.document, documentReference: documentReference)
                    documents.append(documentSnapshot)
                }
            }
        }

        return QuerySnapshot(documents: documents)
    }
}

extension Query {

    public func getDocuments<T: Decodable, Transport: ClientTransport>(type: T.Type, firestore: Firestore<Transport>, metadata: Metadata) async throws -> [T] {
        let snapshot = try await getDocuments(firestore: firestore, metadata: metadata)
        return try snapshot.documents.compactMap { queryDocumentSnapshot in
            guard let data = queryDocumentSnapshot.data() else {
                return nil
            }
            return try FirestoreDecoder().decode(type, from: data, in: queryDocumentSnapshot.documentReference)
        }
    }
}

extension Query {

    public func addSnapshotListener<Transport: ClientTransport>(firestore: Firestore<Transport>, metadata: Metadata) async throws -> AsyncThrowingStream<QuerySnapshot, Error> {
        // Create a target for this query
        var target = Google_Firestore_V1_Target()
        target.query = Google_Firestore_V1_Target.QueryTarget.with {
            $0.parent = self.name
            $0.structuredQuery = self.makeQuery()
        }
        target.targetID = 1

        // Listen to changes
        let responseStream = try await firestore.listen(target: target)

        // Transform ListenResponse stream to QuerySnapshot stream
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // Maintain a map of documents by their path
                    var documents: [String: QueryDocumentSnapshot] = [:]

                    for try await response in responseStream {
                        var hasChanges = false

                        // Check the response type and handle accordingly
                        guard let responseType = response.responseType else {
                            continue
                        }

                        switch responseType {
                        case .documentChange(let change):
                            let documentReference = DocumentReference(name: change.document.name)
                            let snapshot = QueryDocumentSnapshot(
                                document: change.document,
                                documentReference: documentReference
                            )
                            documents[change.document.name] = snapshot
                            hasChanges = true

                        case .documentDelete(let deleteInfo):
                            let documentName = deleteInfo.document
                            documents.removeValue(forKey: documentName)
                            hasChanges = true

                        case .documentRemove(let removeInfo):
                            let documentName = removeInfo.document
                            documents.removeValue(forKey: documentName)
                            hasChanges = true

                        case .targetChange(_):
                            hasChanges = true

                        case .filter(_):
                            // Filter changes might affect the result set
                            hasChanges = true
                        }

                        // Emit snapshot when changes occur
                        if hasChanges {
                            let sortedDocuments = documents.values.sorted { $0.documentReference.path < $1.documentReference.path }
                            let snapshot = QuerySnapshot(documents: sortedDocuments)
                            continuation.yield(snapshot)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
