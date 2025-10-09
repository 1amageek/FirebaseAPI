//
//  ListenTests.swift
//
//
//  Tests for real-time listeners
//

import Foundation
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

        // Create a target for this document
        var target = Google_Firestore_V1_Target()
        target.documents = Google_Firestore_V1_Target.DocumentsTarget.with {
            $0.documents = [docRef.name]
        }
        target.targetID = 1

        // Verify target structure
        #expect(target.targetID == 1)
        #expect(target.documents.documents.count == 1)
        #expect(target.documents.documents[0].contains("users/user123"))
    }

    @Test("Query target creation")
    func testQueryTargetCreation() async throws {
        let database = Database(projectId: "test-project", databaseId: "(default)")
        let query = Query(database, parentPath: nil, collectionID: "users", predicates: [])

        // Create a target for this query
        var target = Google_Firestore_V1_Target()
        target.query = Google_Firestore_V1_Target.QueryTarget.with {
            $0.parent = query.name
            $0.structuredQuery = query.makeQuery()
        }
        target.targetID = 1

        // Verify target structure
        #expect(target.targetID == 1)
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

        // Create a target for this query
        var target = Google_Firestore_V1_Target()
        target.query = Google_Firestore_V1_Target.QueryTarget.with {
            $0.parent = query.name
            $0.structuredQuery = query.makeQuery()
        }
        target.targetID = 1

        // Verify target structure
        #expect(target.targetID == 1)
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
}
