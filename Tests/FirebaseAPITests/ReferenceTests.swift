//
//  ReferenceTests.swift
//
//
//  Created by Norikazu Muramoto on 2023/05/14.
//

import Foundation
import Testing
@testable import FirestoreAPI

@Suite("Reference Path Tests")
struct ReferenceTests {

    let firestore = Firestore(projectId: "test", transport: MockClientTransport())

    @Test("Collection reference path - single level")
    func testCollectionPathSingleLevel() throws {
        #expect(try firestore.collection("test").path == "test")
    }

    @Test("Collection reference path - nested level 1")
    func testCollectionPathNestedLevel1() throws {
        #expect(try firestore.collection("test/1/test").path == "test/1/test")
    }

    @Test("Collection reference path - nested level 2")
    func testCollectionPathNestedLevel2() throws {
        #expect(try firestore.collection("test/1/test/2/test").path == "test/1/test/2/test")
    }

    @Test("Document reference name - level 1")
    func testDocumentNameLevel1() throws {
        #expect(try firestore.document("test/1").name == "projects/test/databases/(default)/documents/test/1")
    }

    @Test("Document reference name - level 2")
    func testDocumentNameLevel2() throws {
        #expect(try firestore.document("test/1/test/2").name == "projects/test/databases/(default)/documents/test/1/test/2")
    }

    @Test("Document reference name - level 3")
    func testDocumentNameLevel3() throws {
        #expect(try firestore.document("test/1/test/2/test/3").name == "projects/test/databases/(default)/documents/test/1/test/2/test/3")
    }

    @Test("Document reference path - level 1")
    func testDocumentPathLevel1() throws {
        #expect(try firestore.document("test/1").path == "test/1")
    }

    @Test("Document reference path - level 2")
    func testDocumentPathLevel2() throws {
        #expect(try firestore.document("test/1/test/2").path == "test/1/test/2")
    }

    @Test("Document reference path - level 3")
    func testDocumentPathLevel3() throws {
        #expect(try firestore.document("test/1/test/2/test/3").path == "test/1/test/2/test/3")
    }

    @Test("DocumentReference Codable round-trip")
    func testDocumentReferenceCodableRoundTrip() throws {
        let original = try firestore.document("users/123")

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(original)
        let decoded = try decoder.decode(DocumentReference.self, from: encoded)

        #expect(decoded.path == original.path)
        #expect(decoded.documentID == original.documentID)
        #expect(decoded.name == original.name)
    }

    @Test("DocumentReference Codable round-trip - nested")
    func testDocumentReferenceCodableRoundTripNested() throws {
        let original = try firestore.document("users/123/posts/456")

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(original)
        let decoded = try decoder.decode(DocumentReference.self, from: encoded)

        #expect(decoded.path == "users/123/posts/456")
        #expect(decoded.documentID == "456")
    }

    @Test("DocumentReference Codable rejects invalid path")
    func testDocumentReferenceCodableRejectsInvalidPath() throws {
        let encoded = try JSONEncoder().encode(
            EncodedDocumentReference(database: Database(projectId: "test"), path: "users//123")
        )

        #expect(throws: FirestoreError.self) {
            _ = try JSONDecoder().decode(DocumentReference.self, from: encoded)
        }
    }

    @Test("CollectionReference Codable round-trip")
    func testCollectionReferenceCodableRoundTrip() throws {
        let original = try firestore.collection("users/123/posts")

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CollectionReference.self, from: encoded)

        #expect(decoded.path == "users/123/posts")
        #expect(decoded.collectionID == "posts")
        #expect(decoded.parent?.path == "users/123")
    }

    @Test("CollectionReference Codable rejects invalid path")
    func testCollectionReferenceCodableRejectsInvalidPath() throws {
        let invalidCollections = [
            EncodedCollectionReference(database: Database(projectId: "test"), parentPath: "users", collectionID: "posts"),
            EncodedCollectionReference(database: Database(projectId: "test"), parentPath: "users//123", collectionID: "posts"),
            EncodedCollectionReference(database: Database(projectId: "test"), parentPath: "users/123", collectionID: ""),
            EncodedCollectionReference(database: Database(projectId: "test"), parentPath: nil, collectionID: "users/123/posts")
        ]

        for invalidCollection in invalidCollections {
            let encoded = try JSONEncoder().encode(invalidCollection)
            #expect(throws: FirestoreError.self) {
                _ = try JSONDecoder().decode(CollectionReference.self, from: encoded)
            }
        }
    }

    @Test("CollectionReference parent returns DocumentReference")
    func testCollectionParentReturnsDocument() throws {
        let collection = try firestore.collection("users/123/posts")
        let parent = collection.parent

        #expect(parent != nil)
        #expect(parent?.path == "users/123")
        #expect(parent?.documentID == "123")
    }

    @Test("Top-level CollectionReference parent is nil")
    func testTopLevelCollectionParentIsNil() throws {
        let collection = try firestore.collection("users")
        let parent = collection.parent

        #expect(parent == nil)
    }
}

private struct EncodedDocumentReference: Encodable {
    let database: Database
    let path: String
}

private struct EncodedCollectionReference: Encodable {
    let database: Database
    let parentPath: String?
    let collectionID: String
}
