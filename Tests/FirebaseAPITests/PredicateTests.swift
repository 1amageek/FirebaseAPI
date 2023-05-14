//
//  PredicateTests.swift
//  
//
//  Created by Norikazu Muramoto on 2023/05/14.
//

import XCTest
@testable import FirestoreAPI

final class PredicateTests: XCTestCase {


    func testPredicates() throws {

        if case .isEqualTo(let field, let value) = ("test" == 0), let value = value as? Int {
            XCTAssertEqual(field, "test")
            XCTAssertEqual(value, 0)
        } else {
            fatalError()
        }

        if case .isNotEqualTo(let field, let value) = ("test" != 0), let value = value as? Int {
            XCTAssertEqual(field, "test")
            XCTAssertEqual(value, 0)
        } else {
            fatalError()
        }

        if case .isLessThan(let field, let value) = ("test" < 0), let value = value as? Int {
            XCTAssertEqual(field, "test")
            XCTAssertEqual(value, 0)
        } else {
            fatalError()
        }

        if case .isLessThanOrEqualTo(let field, let value) = ("test" <= 0), let value = value as? Int {
            XCTAssertEqual(field, "test")
            XCTAssertEqual(value, 0)
        } else {
            fatalError()
        }

        if case .isGreaterThan(let field, let value) = ("test" > 0), let value = value as? Int {
            XCTAssertEqual(field, "test")
            XCTAssertEqual(value, 0)
        } else {
            fatalError()
        }

        if case .isGreaterThanOrEqualTo(let field, let value) = ("test" >= 0), let value = value as? Int {
            XCTAssertEqual(field, "test")
            XCTAssertEqual(value, 0)
        } else {
            fatalError()
        }
    }
}
