//
//  ListenTests.swift
//
//
//  Tests for real-time listeners
//

import Foundation
import FirestoreProtobuf
import FirestoreRPC
import FirestoreRuntimeSupport
import Testing
import GRPCCore
import SwiftProtobuf
@testable import FirestoreAPI

@Suite("Listen API Tests")
struct ListenTests {

    @Test("ListenResponse documentChange creates DocumentSnapshot")
    func testDocumentChangeResponse() async throws {
        // Create a mock document
        var document = Google_Firestore_V1_Document()
        document.name = "projects/test-project/databases/(default)/documents/users/user123"
        document.fields = [
            "name": Google_Firestore_V1_Value.with {
                $0.stringValue = "John Doe"
            },
            "age": Google_Firestore_V1_Value.with {
                $0.integerValue = 30
            }
        ]
        document.createTime = Google_Protobuf_Timestamp()
        document.updateTime = Google_Protobuf_Timestamp()

        // Create a documentChange response
        var response = Google_Firestore_V1_ListenResponse()
        response.documentChange = Google_Firestore_V1_DocumentChange.with {
            $0.document = document
            $0.targetIds = [1]
        }

        // Verify response type
        #expect(response.responseType != nil)

        if case .documentChange(let change) = response.responseType {
            #expect(change.document.name == document.name)
            #expect(change.document.fields["name"]?.stringValue == "John Doe")
            #expect(change.document.fields["age"]?.integerValue == 30)
        } else {
            Issue.record("Expected documentChange response type")
        }
    }

    @Test("ListenResponse documentDelete creates empty DocumentSnapshot")
    func testDocumentDeleteResponse() async throws {
        // Create a documentDelete response
        var response = Google_Firestore_V1_ListenResponse()
        response.documentDelete = Google_Firestore_V1_DocumentDelete.with {
            $0.document = "projects/test-project/databases/(default)/documents/users/user123"
            $0.removedTargetIds = [1]
        }

        // Verify response type
        #expect(response.responseType != nil)

        if case .documentDelete(let deleteInfo) = response.responseType {
            #expect(deleteInfo.document == "projects/test-project/databases/(default)/documents/users/user123")
        } else {
            Issue.record("Expected documentDelete response type")
        }
    }

    @Test("ListenResponse documentRemove removes from target")
    func testDocumentRemoveResponse() async throws {
        // Create a documentRemove response
        var response = Google_Firestore_V1_ListenResponse()
        response.documentRemove = Google_Firestore_V1_DocumentRemove.with {
            $0.document = "projects/test-project/databases/(default)/documents/users/user123"
            $0.removedTargetIds = [1]
        }

        // Verify response type
        #expect(response.responseType != nil)

        if case .documentRemove(let removeInfo) = response.responseType {
            #expect(removeInfo.document == "projects/test-project/databases/(default)/documents/users/user123")
        } else {
            Issue.record("Expected documentRemove response type")
        }
    }

    @Test("ListenResponse targetChange updates target state")
    func testTargetChangeResponse() async throws {
        // Create a targetChange response
        var response = Google_Firestore_V1_ListenResponse()
        response.targetChange = Google_Firestore_V1_TargetChange.with {
            $0.targetChangeType = .add
            $0.targetIds = [1]
        }

        // Verify response type
        #expect(response.responseType != nil)

        if case .targetChange(let change) = response.responseType {
            #expect(change.targetChangeType == .add)
            #expect(change.targetIds == [1])
        } else {
            Issue.record("Expected targetChange response type")
        }
    }

    @Test("DocumentReference target creation")
    func testDocumentReferenceTargetCreation() async throws {
        let database = Database(projectId: "test-project", databaseId: "(default)")
        let docRef = DocumentReference(database, parentPath: "users", documentID: "user123")

        let target = ListenTargetBuilder().makeDocumentTarget(for: docRef, targetID: 41)

        #expect(target.targetID == 41)
        #expect(target.documents.documents.count == 1)
        #expect(target.documents.documents[0].contains("users/user123"))
    }

    @Test("Query target creation")
    func testQueryTargetCreation() async throws {
        let database = Database(projectId: "test-project", databaseId: "(default)")
        let query = Query(database, parentPath: nil, collectionID: "users", predicates: [])

        let target = try ListenTargetBuilder().makeQueryTarget(for: query, targetID: 42)

        #expect(target.targetID == 42)
        #expect(target.query.structuredQuery.from.count == 1)
        #expect(target.query.structuredQuery.from[0].collectionID == "users")
    }

    @Test("Query with predicates target creation")
    func testQueryWithPredicatesTargetCreation() async throws {
        let database = Database(projectId: "test-project", databaseId: "(default)")
        let query = Query(database, parentPath: nil, collectionID: "users", predicates: [
            .isGreaterThanOrEqualTo("age", 18),
            .isEqualTo("active", true)
        ])

        let target = try ListenTargetBuilder().makeQueryTarget(for: query, targetID: 43)

        #expect(target.targetID == 43)
        let structuredQuery = target.query.structuredQuery
        #expect(structuredQuery.from.count == 1)
        #expect(structuredQuery.from[0].collectionID == "users")
        #expect(structuredQuery.hasWhere)
    }

    @Test("Multiple ListenResponse processing")
    func testMultipleResponseProcessing() async throws {
        // Create multiple responses simulating a real-time stream
        var document1 = Google_Firestore_V1_Document()
        document1.name = "projects/test-project/databases/(default)/documents/users/user1"
        document1.fields = ["name": Google_Firestore_V1_Value.with { $0.stringValue = "Alice" }]

        var document2 = Google_Firestore_V1_Document()
        document2.name = "projects/test-project/databases/(default)/documents/users/user2"
        document2.fields = ["name": Google_Firestore_V1_Value.with { $0.stringValue = "Bob" }]

        var response1 = Google_Firestore_V1_ListenResponse()
        response1.documentChange = Google_Firestore_V1_DocumentChange.with {
            $0.document = document1
        }

        var response2 = Google_Firestore_V1_ListenResponse()
        response2.documentChange = Google_Firestore_V1_DocumentChange.with {
            $0.document = document2
        }

        var response3 = Google_Firestore_V1_ListenResponse()
        response3.documentDelete = Google_Firestore_V1_DocumentDelete.with {
            $0.document = document1.name
        }

        let responses = [response1, response2, response3]

        // Verify we can process all responses
        var documentMap: [String: Google_Firestore_V1_Document] = [:]

        for response in responses {
            guard let responseType = response.responseType else { continue }

            switch responseType {
            case .documentChange(let change):
                documentMap[change.document.name] = change.document
            case .documentDelete(let deleteInfo):
                documentMap.removeValue(forKey: deleteInfo.document)
            case .documentRemove(let removeInfo):
                documentMap.removeValue(forKey: removeInfo.document)
            case .targetChange(_), .filter(_):
                break
            }
        }

        // After processing, should only have user2 (user1 was deleted)
        #expect(documentMap.count == 1)
        #expect(documentMap.keys.contains(document2.name))
        #expect(!documentMap.keys.contains(document1.name))
    }

    @Test("QueryListenState emits initial snapshot when target becomes current")
    func testQueryListenStateEmitsInitialSnapshotOnCurrent() throws {
        let targetID: Int32 = 51
        var state = QueryListenState(targetID: targetID, runtime: nil)

        let firstDocument = makeDocument(id: "userB", name: "Bob")
        let secondDocument = makeDocument(id: "userA", name: "Alice")

        let firstResult = try state.apply(documentChangeResponse(firstDocument, targetID: targetID))
        let secondResult = try state.apply(documentChangeResponse(secondDocument, targetID: targetID))
        let currentSnapshot = try state.apply(currentResponse(targetID: targetID))

        #expect(firstResult == nil)
        #expect(secondResult == nil)
        #expect(currentSnapshot?.documents.count == 2)
        #expect(currentSnapshot?.documentChanges.map(\.type) == [.added, .added])
        #expect(currentSnapshot?.documentChanges.map(\.newIndex) == [0, 1])
        #expect(currentSnapshot?.documentChanges.allSatisfy { $0.oldIndex == DocumentChange.notFoundIndex } == true)
        #expect(currentSnapshot?.metadata == .serverSynchronized)
    }

    @Test("QueryListenState preserves listen document order")
    func testQueryListenStatePreservesListenDocumentOrder() throws {
        let targetID: Int32 = 52
        var state = QueryListenState(targetID: targetID, runtime: nil)

        let firstDocument = makeDocument(id: "userB", name: "Bob")
        let secondDocument = makeDocument(id: "userA", name: "Alice")

        _ = try state.apply(documentChangeResponse(firstDocument, targetID: targetID))
        _ = try state.apply(documentChangeResponse(secondDocument, targetID: targetID))
        let snapshot = try state.apply(currentResponse(targetID: targetID))

        #expect(snapshot?.documents.map(\.documentReference.documentID) == ["userB", "userA"])
    }

    @Test("QueryListenState emits empty initial snapshot")
    func testQueryListenStateEmitsEmptyInitialSnapshot() throws {
        let targetID: Int32 = 53
        var state = QueryListenState(targetID: targetID, runtime: nil)

        let snapshot = try state.apply(currentResponse(targetID: targetID))

        #expect(snapshot?.isEmpty == true)
        #expect(snapshot?.documentChanges.isEmpty == true)
        #expect(snapshot?.metadata.hasPendingWrites == false)
        #expect(snapshot?.metadata.isFromCache == false)
    }

    @Test("QueryListenState emits modified change after initial snapshot")
    func testQueryListenStateEmitsModifiedChangeAfterInitialSnapshot() throws {
        let targetID: Int32 = 54
        var state = QueryListenState(targetID: targetID, runtime: nil)

        _ = try state.apply(documentChangeResponse(makeDocument(id: "user1", name: "Alice"), targetID: targetID))
        _ = try state.apply(currentResponse(targetID: targetID))

        let snapshot = try state.apply(documentChangeResponse(makeDocument(id: "user1", name: "Alicia"), targetID: targetID))
        let change = try #require(snapshot?.documentChanges.first)

        #expect(snapshot?.documents.count == 1)
        #expect(change.type == .modified)
        #expect(change.oldIndex == 0)
        #expect(change.newIndex == 0)
        #expect(change.document.data()["name"] as? String == "Alicia")
    }

    @Test("QueryListenState emits removed change after initial snapshot")
    func testQueryListenStateEmitsRemovedChangeAfterInitialSnapshot() throws {
        let targetID: Int32 = 55
        var state = QueryListenState(targetID: targetID, runtime: nil)

        let firstDocument = makeDocument(id: "user1", name: "Alice")
        let secondDocument = makeDocument(id: "user2", name: "Bob")

        _ = try state.apply(documentChangeResponse(firstDocument, targetID: targetID))
        _ = try state.apply(documentChangeResponse(secondDocument, targetID: targetID))
        _ = try state.apply(currentResponse(targetID: targetID))

        let snapshot = try state.apply(documentDeleteResponse(secondDocument.name, targetID: targetID))
        let change = try #require(snapshot?.documentChanges.first)

        #expect(snapshot?.documents.map(\.documentReference.documentID) == ["user1"])
        #expect(change.type == .removed)
        #expect(change.oldIndex == 1)
        #expect(change.newIndex == DocumentChange.notFoundIndex)
        #expect(change.document.documentReference.documentID == "user2")
    }

    @Test("QueryListenState requests resync on existence filter mismatch")
    func testQueryListenStateRequestsResyncOnExistenceFilterMismatch() throws {
        let targetID: Int32 = 56
        var state = QueryListenState(targetID: targetID, runtime: nil)

        _ = try state.apply(documentChangeResponse(makeDocument(id: "user1", name: "Alice"), targetID: targetID))
        _ = try state.apply(currentResponse(targetID: targetID))

        do {
            _ = try state.apply(existenceFilterResponse(count: 0, targetID: targetID))
            Issue.record("Expected listen resync request")
        } catch let error as ListenResyncRequired {
            #expect(error.targetID == targetID)
            #expect(error.expectedCount == 1)
            #expect(error.actualCount == 0)
        }
    }

    @Test("DocumentListenState requests resync on existence filter mismatch")
    func testDocumentListenStateRequestsResyncOnExistenceFilterMismatch() throws {
        let targetID: Int32 = 63
        let reference = makeDocumentReference(id: "user1")
        var state = DocumentListenState(targetID: targetID, reference: reference)

        let document = makeDocument(id: "user1", name: "Alice")
        _ = try state.apply(documentChangeResponse(document, targetID: targetID))
        _ = try state.apply(currentResponse(targetID: targetID))

        do {
            _ = try state.apply(existenceFilterResponse(count: 0, targetID: targetID))
            Issue.record("Expected listen resync request")
        } catch let error as ListenResyncRequired {
            #expect(error.targetID == targetID)
            #expect(error.expectedCount == 1)
            #expect(error.actualCount == 0)
        }
    }

    @Test("QueryListenState stores target resume token")
    func testQueryListenStateStoresTargetResumeToken() throws {
        let targetID: Int32 = 64
        let token = Data([1, 2, 3])
        var state = QueryListenState(targetID: targetID, runtime: nil)

        _ = try state.apply(resumeTokenResponse(token, targetID: targetID))

        #expect(state.resumeToken == token)
    }

    @Test("DocumentListenState stores target resume token")
    func testDocumentListenStateStoresTargetResumeToken() throws {
        let targetID: Int32 = 65
        let token = Data([4, 5, 6])
        let reference = makeDocumentReference(id: "user1")
        var state = DocumentListenState(targetID: targetID, reference: reference)

        _ = try state.apply(resumeTokenResponse(token, targetID: targetID))

        #expect(state.resumeToken == token)
    }

    @Test("QueryListenState orders initial snapshot by query sort order")
    func testQueryListenStateOrdersInitialSnapshotByQuerySortOrder() throws {
        let targetID: Int32 = 60
        var state = QueryListenState(
            targetID: targetID,
            runtime: nil,
            sortOrders: [QuerySortOrder(fieldPath: "score", descending: false)]
        )

        _ = try state.apply(documentChangeResponse(makeScoredDocument(id: "user2", score: 20), targetID: targetID))
        _ = try state.apply(documentChangeResponse(makeScoredDocument(id: "user1", score: 10), targetID: targetID))
        let snapshot = try state.apply(currentResponse(targetID: targetID))

        #expect(snapshot?.documents.map(\.documentReference.documentID) == ["user1", "user2"])
        #expect(snapshot?.documentChanges.map(\.newIndex) == [0, 1])
    }

    @Test("QueryListenState moves modified document when order field changes")
    func testQueryListenStateMovesModifiedDocumentWhenOrderFieldChanges() throws {
        let targetID: Int32 = 61
        var state = QueryListenState(
            targetID: targetID,
            runtime: nil,
            sortOrders: [QuerySortOrder(fieldPath: "score", descending: false)]
        )

        _ = try state.apply(documentChangeResponse(makeScoredDocument(id: "user1", score: 10), targetID: targetID))
        _ = try state.apply(documentChangeResponse(makeScoredDocument(id: "user2", score: 20), targetID: targetID))
        _ = try state.apply(currentResponse(targetID: targetID))

        let snapshot = try state.apply(documentChangeResponse(makeScoredDocument(id: "user1", score: 30), targetID: targetID))
        let change = try #require(snapshot?.documentChanges.first)

        #expect(snapshot?.documents.map(\.documentReference.documentID) == ["user2", "user1"])
        #expect(change.type == .modified)
        #expect(change.oldIndex == 0)
        #expect(change.newIndex == 1)
    }

    @Test("QueryListenState applies descending query sort order")
    func testQueryListenStateAppliesDescendingQuerySortOrder() throws {
        let targetID: Int32 = 62
        var state = QueryListenState(
            targetID: targetID,
            runtime: nil,
            sortOrders: [QuerySortOrder(fieldPath: "score", descending: true)]
        )

        _ = try state.apply(documentChangeResponse(makeScoredDocument(id: "user1", score: 10), targetID: targetID))
        _ = try state.apply(documentChangeResponse(makeScoredDocument(id: "user2", score: 20), targetID: targetID))
        let snapshot = try state.apply(currentResponse(targetID: targetID))

        #expect(snapshot?.documents.map(\.documentReference.documentID) == ["user2", "user1"])
    }

    @Test("DocumentListenState emits initial existing snapshot when target becomes current")
    func testDocumentListenStateEmitsInitialExistingSnapshotOnCurrent() throws {
        let targetID: Int32 = 57
        let reference = makeDocumentReference(id: "user1")
        var state = DocumentListenState(targetID: targetID, reference: reference)

        let document = makeDocument(id: "user1", name: "Alice")
        let firstResult = try state.apply(documentChangeResponse(document, targetID: targetID))
        let snapshot = try state.apply(currentResponse(targetID: targetID))

        #expect(firstResult == nil)
        #expect(snapshot?.exists == true)
        #expect(snapshot?.data()?["name"] as? String == "Alice")
        #expect(snapshot?.metadata == .serverSynchronized)
    }

    @Test("DocumentListenState emits missing initial snapshot")
    func testDocumentListenStateEmitsMissingInitialSnapshot() throws {
        let targetID: Int32 = 58
        let reference = makeDocumentReference(id: "missing")
        var state = DocumentListenState(targetID: targetID, reference: reference)

        let snapshot = try state.apply(currentResponse(targetID: targetID))

        #expect(snapshot?.exists == false)
        #expect(snapshot?.data() == nil)
        #expect(snapshot?.metadata.hasPendingWrites == false)
        #expect(snapshot?.metadata.isFromCache == false)
    }

    @Test("DocumentListenState emits missing snapshot after delete")
    func testDocumentListenStateEmitsMissingSnapshotAfterDelete() throws {
        let targetID: Int32 = 59
        let reference = makeDocumentReference(id: "user1")
        var state = DocumentListenState(targetID: targetID, reference: reference)

        let document = makeDocument(id: "user1", name: "Alice")
        _ = try state.apply(documentChangeResponse(document, targetID: targetID))
        _ = try state.apply(currentResponse(targetID: targetID))

        let snapshot = try state.apply(documentDeleteResponse(document.name, targetID: targetID))

        #expect(snapshot?.exists == false)
        #expect(snapshot?.documentReference.documentID == "user1")
    }

    @Test("Listen states validate response document names")
    func testListenStatesValidateResponseDocumentNames() throws {
        let targetID: Int32 = 66
        let reference = makeDocumentReference(id: "user1")
        var documentState = DocumentListenState(targetID: targetID, reference: reference)
        let mismatchedDocument = makeDocument(id: "user2", name: "Bob")

        do {
            _ = try documentState.apply(documentChangeResponse(mismatchedDocument, targetID: targetID))
            Issue.record("Expected listen document path mismatch to throw.")
        } catch FirestoreError.invalidPath(let message) {
            #expect(message.contains("target document reference"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        let database = Database(projectId: "test-project")
        let runtime = ListenStateRuntime(database: database)
        var queryState = QueryListenState(targetID: targetID, runtime: runtime)
        let otherDatabaseDocument = Google_Firestore_V1_Document.with {
            $0.name = "projects/other-project/databases/(default)/documents/users/user1"
        }

        do {
            _ = try queryState.apply(documentChangeResponse(otherDatabaseDocument, targetID: targetID))
            Issue.record("Expected listen query database mismatch to throw.")
        } catch FirestoreError.databaseMismatch(let expected, let actual) {
            #expect(expected == "projects/test-project/databases/(default)")
            #expect(actual == "projects/other-project/databases/(default)")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        do {
            _ = try queryState.apply(documentDeleteResponse(otherDatabaseDocument.name, targetID: targetID))
            Issue.record("Expected listen query delete database mismatch to throw.")
        } catch FirestoreError.databaseMismatch(let expected, let actual) {
            #expect(expected == "projects/test-project/databases/(default)")
            #expect(actual == "projects/other-project/databases/(default)")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

private func makeDocument(id: String, name: String) -> Google_Firestore_V1_Document {
    Google_Firestore_V1_Document.with {
        $0.name = "projects/test-project/databases/(default)/documents/users/\(id)"
        $0.fields = [
            "name": Google_Firestore_V1_Value.with {
                $0.stringValue = name
            }
        ]
    }
}

private func makeScoredDocument(id: String, score: Int64) -> Google_Firestore_V1_Document {
    Google_Firestore_V1_Document.with {
        $0.name = "projects/test-project/databases/(default)/documents/users/\(id)"
        $0.fields = [
            "score": Google_Firestore_V1_Value.with {
                $0.integerValue = score
            }
        ]
    }
}

private func makeDocumentReference(id: String) -> DocumentReference {
    let database = Database(projectId: "test-project", databaseId: "(default)")
    return DocumentReference(database, parentPath: "users", documentID: id)
}

private func documentChangeResponse(
    _ document: Google_Firestore_V1_Document,
    targetID: Int32
) -> Google_Firestore_V1_ListenResponse {
    Google_Firestore_V1_ListenResponse.with {
        $0.documentChange = Google_Firestore_V1_DocumentChange.with {
            $0.document = document
            $0.targetIds = [targetID]
        }
    }
}

private func documentDeleteResponse(
    _ documentName: String,
    targetID: Int32
) -> Google_Firestore_V1_ListenResponse {
    Google_Firestore_V1_ListenResponse.with {
        $0.documentDelete = Google_Firestore_V1_DocumentDelete.with {
            $0.document = documentName
            $0.removedTargetIds = [targetID]
        }
    }
}

private func currentResponse(targetID: Int32) -> Google_Firestore_V1_ListenResponse {
    Google_Firestore_V1_ListenResponse.with {
        $0.targetChange = Google_Firestore_V1_TargetChange.with {
            $0.targetChangeType = .current
            $0.targetIds = [targetID]
        }
    }
}

private func resumeTokenResponse(
    _ token: Data,
    targetID: Int32
) -> Google_Firestore_V1_ListenResponse {
    Google_Firestore_V1_ListenResponse.with {
        $0.targetChange = Google_Firestore_V1_TargetChange.with {
            $0.targetChangeType = .noChange
            $0.targetIds = [targetID]
            $0.resumeToken = token
        }
    }
}

private func existenceFilterResponse(
    count: Int32,
    targetID: Int32
) -> Google_Firestore_V1_ListenResponse {
    Google_Firestore_V1_ListenResponse.with {
        $0.filter = Google_Firestore_V1_ExistenceFilter.with {
            $0.count = count
            $0.targetID = targetID
        }
    }
}

private final class ListenStateRuntime: FirestoreRuntime {
    let runtimeDatabase: Database

    init(database: Database) {
        self.runtimeDatabase = database
    }

    func getDocument(_ reference: DocumentReference) async throws -> DocumentSnapshot {
        DocumentSnapshot(documentReference: reference)
    }

    func setData(_ data: [String: Any], merge: Bool, for reference: DocumentReference) async throws {}

    func setData(_ data: [String: Any], mergeFields: [String], for reference: DocumentReference) async throws {}

    func updateData(_ fields: [String: Any], for reference: DocumentReference) async throws {}

    func deleteDocument(_ reference: DocumentReference) async throws {}

    func listCollections(in reference: DocumentReference) async throws -> [CollectionReference] {
        []
    }

    func listen(to reference: DocumentReference) async throws -> AsyncThrowingStream<DocumentSnapshot, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }

    func getDocuments(for query: Query) async throws -> QuerySnapshot {
        QuerySnapshot(documents: [])
    }

    func listen(to query: Query) async throws -> AsyncThrowingStream<QuerySnapshot, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }

    func aggregate(_ query: Query, fields: [AggregateField]) async throws -> AggregateQuerySnapshot {
        AggregateQuerySnapshot(data: [:])
    }

    func explain(_ query: Query, options: FirestoreExplainOptions) async throws -> QueryExplainResult {
        QueryExplainResult(snapshot: nil, metrics: FirestoreExplainMetrics(planSummary: .init(indexesUsed: []), executionStats: nil))
    }

    func explainAggregation(
        _ query: Query,
        fields: [AggregateField],
        options: FirestoreExplainOptions
    ) async throws -> AggregateQueryExplainResult {
        AggregateQueryExplainResult(snapshot: nil, metrics: FirestoreExplainMetrics(planSummary: .init(indexesUsed: []), executionStats: nil))
    }

    func executePipeline(_ pipeline: FirestorePipeline) async throws -> PipelineQuerySnapshot {
        PipelineQuerySnapshot(rows: [], executionTime: nil)
    }

    func explainPipeline(
        _ pipeline: FirestorePipeline,
        options: PipelineExplainOptions
    ) async throws -> PipelineExplainResult {
        PipelineExplainResult(snapshot: nil, stats: PipelineExplainStats(outputFormat: options.outputFormat, text: nil, json: nil, rawTypeURL: nil, rawData: nil))
    }

}
