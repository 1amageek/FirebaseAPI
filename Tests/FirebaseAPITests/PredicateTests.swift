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
}
