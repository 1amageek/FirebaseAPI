//
//  ReferenceTests.swift
//
//
//  Created by Norikazu Muramoto on 2023/05/14.
//

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
}
