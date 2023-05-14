//
//  ReferenceTests.swift
//  
//
//  Created by Norikazu Muramoto on 2023/05/14.
//

import XCTest
@testable import FirestoreAPI

final class ReferenceTests: XCTestCase {

    func testCollectionPath() throws {
        XCTAssertEqual(Firestore(projectId: "test").collection("test").path, "test")
        XCTAssertEqual(Firestore(projectId: "test").collection("test/1/test").path, "test/1/test")
        XCTAssertEqual(Firestore(projectId: "test").collection("test/1/test/2/test").path, "test/1/test/2/test")
    }

    func testCollectionName() throws {
        XCTAssertEqual(Firestore(projectId: "test").document("test/1").name, "projects/test/databases/(default)/documents/test/1")
        XCTAssertEqual(Firestore(projectId: "test").document("test/1/test/2").name, "projects/test/databases/(default)/documents/test/1/test/2")
        XCTAssertEqual(Firestore(projectId: "test").document("test/1/test/2/test/3").name, "projects/test/databases/(default)/documents/test/1/test/2/test/3")
    }

    func testDocumentPath() throws {
        XCTAssertEqual(Firestore(projectId: "test").document("test/1").path, "test/1")
        XCTAssertEqual(Firestore(projectId: "test").document("test/1/test/2").path, "test/1/test/2")
        XCTAssertEqual(Firestore(projectId: "test").document("test/1/test/2/test/3").path, "test/1/test/2/test/3")
    }

    func testDocumentName() throws {
        XCTAssertEqual(Firestore(projectId: "test").document("test/1").name, "projects/test/databases/(default)/documents/test/1")
        XCTAssertEqual(Firestore(projectId: "test").document("test/1/test/2").name, "projects/test/databases/(default)/documents/test/1/test/2")
        XCTAssertEqual(Firestore(projectId: "test").document("test/1/test/2/test/3").name, "projects/test/databases/(default)/documents/test/1/test/2/test/3")
    }

}
