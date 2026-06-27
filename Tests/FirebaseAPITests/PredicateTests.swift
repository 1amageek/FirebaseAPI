//
//  PredicateTests.swift
//
//
//  Created by Norikazu Muramoto on 2023/05/14.
//

import Testing
@testable import FirestoreAPI

@Suite("Query Predicate Tests")
struct PredicateTests {

    @Test("Predicate isEqualTo operator")
    func testIsEqualTo() {
        let predicate = "test" == 0

        guard case .isEqualTo(let field, let value) = predicate,
              let intValue = value as? Int else {
            Issue.record("Expected isEqualTo predicate")
            return
        }

        #expect(field == "test")
        #expect(intValue == 0)
    }

    @Test("Predicate isNotEqualTo operator")
    func testIsNotEqualTo() {
        let predicate = "test" != 0

        guard case .isNotEqualTo(let field, let value) = predicate,
              let intValue = value as? Int else {
            Issue.record("Expected isNotEqualTo predicate")
            return
        }

        #expect(field == "test")
        #expect(intValue == 0)
    }

    @Test("Predicate isLessThan operator")
    func testIsLessThan() {
        let predicate = "test" < 0

        guard case .isLessThan(let field, let value) = predicate,
              let intValue = value as? Int else {
            Issue.record("Expected isLessThan predicate")
            return
        }

        #expect(field == "test")
        #expect(intValue == 0)
    }

    @Test("Predicate isLessThanOrEqualTo operator")
    func testIsLessThanOrEqualTo() {
        let predicate = "test" <= 0

        guard case .isLessThanOrEqualTo(let field, let value) = predicate,
              let intValue = value as? Int else {
            Issue.record("Expected isLessThanOrEqualTo predicate")
            return
        }

        #expect(field == "test")
        #expect(intValue == 0)
    }

    @Test("Predicate isGreaterThan operator")
    func testIsGreaterThan() {
        let predicate = "test" > 0

        guard case .isGreaterThan(let field, let value) = predicate,
              let intValue = value as? Int else {
            Issue.record("Expected isGreaterThan predicate")
            return
        }

        #expect(field == "test")
        #expect(intValue == 0)
    }

    @Test("Predicate isGreaterThanOrEqualTo operator")
    func testIsGreaterThanOrEqualTo() {
        let predicate = "test" >= 0

        guard case .isGreaterThanOrEqualTo(let field, let value) = predicate,
              let intValue = value as? Int else {
            Issue.record("Expected isGreaterThanOrEqualTo predicate")
            return
        }

        #expect(field == "test")
        #expect(intValue == 0)
    }

    @Test("DocumentID filter uses the queried collection path")
    func testDocumentIDFilterUsesCollectionPath() throws {
        let database = Database(projectId: "test-project")
        let query = Query(database, parentPath: nil, collectionID: "users", predicates: [
            .isEqualToDocumentID("user123")
        ])

        let filter = try query.makeQuery().where.fieldFilter

        #expect(filter.field.fieldPath == "__name__")
        #expect(filter.value.referenceValue == "projects/test-project/databases/(default)/documents/users/user123")
    }

    @Test("DocumentID filter uses parent collection path")
    func testDocumentIDFilterUsesParentCollectionPath() throws {
        let database = Database(projectId: "test-project")
        let query = Query(database, parentPath: "organizations/org123", collectionID: "users", predicates: [
            .isEqualToDocumentID("user123")
        ])

        let filter = try query.makeQuery().where.fieldFilter

        #expect(filter.field.fieldPath == "__name__")
        #expect(filter.value.referenceValue == "projects/test-project/databases/(default)/documents/organizations/org123/users/user123")
    }
}
