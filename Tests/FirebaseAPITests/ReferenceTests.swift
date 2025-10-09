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
    func testCollectionPathSingleLevel() {
        #expect(firestore.collection("test").path == "test")
    }

    @Test("Collection reference path - nested level 1")
    func testCollectionPathNestedLevel1() {
        #expect(firestore.collection("test/1/test").path == "test/1/test")
    }

    @Test("Collection reference path - nested level 2")
    func testCollectionPathNestedLevel2() {
        #expect(firestore.collection("test/1/test/2/test").path == "test/1/test/2/test")
    }

    @Test("Document reference name - level 1")
    func testDocumentNameLevel1() {
        #expect(firestore.document("test/1").name == "projects/test/databases/(default)/documents/test/1")
    }

    @Test("Document reference name - level 2")
    func testDocumentNameLevel2() {
        #expect(firestore.document("test/1/test/2").name == "projects/test/databases/(default)/documents/test/1/test/2")
    }

    @Test("Document reference name - level 3")
    func testDocumentNameLevel3() {
        #expect(firestore.document("test/1/test/2/test/3").name == "projects/test/databases/(default)/documents/test/1/test/2/test/3")
    }

    @Test("Document reference path - level 1")
    func testDocumentPathLevel1() {
        #expect(firestore.document("test/1").path == "test/1")
    }

    @Test("Document reference path - level 2")
    func testDocumentPathLevel2() {
        #expect(firestore.document("test/1/test/2").path == "test/1/test/2")
    }

    @Test("Document reference path - level 3")
    func testDocumentPathLevel3() {
        #expect(firestore.document("test/1/test/2/test/3").path == "test/1/test/2/test/3")
    }

    @Test("DocumentReference Codable round-trip")
    func testDocumentReferenceCodableRoundTrip() throws {
        let original = firestore.document("users/123")

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
        let original = firestore.document("users/123/posts/456")

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(original)
        let decoded = try decoder.decode(DocumentReference.self, from: encoded)

        #expect(decoded.path == "users/123/posts/456")
        #expect(decoded.documentID == "456")
    }

    @Test("CollectionReference parent returns DocumentReference")
    func testCollectionParentReturnsDocument() {
        let collection = firestore.collection("users/123/posts")
        let parent = collection.parent

        #expect(parent != nil)
        #expect(parent?.path == "users/123")
        #expect(parent?.documentID == "123")
    }

    @Test("Top-level CollectionReference parent is nil")
    func testTopLevelCollectionParentIsNil() {
        let collection = firestore.collection("users")
        let parent = collection.parent

        #expect(parent == nil)
    }
}
