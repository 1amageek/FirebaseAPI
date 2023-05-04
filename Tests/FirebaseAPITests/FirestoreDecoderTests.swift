//
//  FirestoreDecoderTests.swift
//  
//
//  Created by Norikazu Muramoto on 2023/05/04.
//

import XCTest
@testable import FirestoreAPI

final class FirestoreDecoderTests: XCTestCase {

    func testDecoderString() async throws {
        struct Object: Codable, Equatable {
            var value: String = "string"
        }
        let data = try! FirestoreDecoder().decode(Object.self, from: ["value": "string"])
        XCTAssertEqual(data.value, "string")
    }

    func testDecoderInt() async throws {
        struct Object: Codable, Equatable {
            var value: Int = 0
        }
        let data = try! FirestoreDecoder().decode(Object.self, from: ["value": 0])
        XCTAssertEqual(data.value, 0)
    }

    func testDecoderBool() async throws {
        struct Object: Codable, Equatable {
            var value: Bool = false
        }
        let data = try! FirestoreDecoder().decode(Object.self, from: ["value": false])
        XCTAssertEqual(data.value, false)
    }

    func testDecoderDate() async throws {
        struct Object: Codable, Equatable {
            var value: Date = Date(timeIntervalSince1970: 0)
        }
        let data = try! FirestoreDecoder().decode(Object.self, from: ["value": Date(timeIntervalSince1970: 0)])
        XCTAssertEqual(data.value, Date(timeIntervalSince1970: 0))
    }

    func testDecoderTimestamp() async throws {
        struct Object: Codable, Equatable {
            var value: Timestamp = Timestamp(seconds: 0, nanos: 0)
        }
        let data = try! FirestoreDecoder().decode(Object.self, from: ["value": Timestamp(seconds: 0, nanos: 0)])
        XCTAssertEqual(data.value, Timestamp(seconds: 0, nanos: 0))
    }

    func testDecoderGeoPoint() async throws {
        struct Object: Codable, Equatable {
            var value: GeoPoint = GeoPoint(latitude: 0, longitude: 0)
        }
        let data = try! FirestoreDecoder().decode(Object.self, from: ["value": GeoPoint(latitude: 0, longitude: 0)])
        XCTAssertEqual(data.value, GeoPoint(latitude: 0, longitude: 0))
    }

    func testDecoderDocumentReference() async throws {
        struct Object: Codable, Equatable {
            var value: DocumentReference = DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id")
        }
        let data = try! FirestoreDecoder().decode(Object.self, from: ["value": DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id")])
        XCTAssertEqual(data.value, DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id"))
    }

    func testDecoderArrayString() async throws {
        struct Object: Codable, Equatable {
            var value: [String] = ["0", "1"]
        }
        let data = try! FirestoreDecoder().decode(Object.self, from: ["value": ["0", "1"]])
        XCTAssertEqual(data.value, ["0", "1"])
    }

    func testDecoderArrayInt() async throws {
        struct Object: Codable, Equatable {
            var value: [Int] = [0, 1]
        }
        let data = try! FirestoreDecoder().decode(Object.self, from: ["value": [0, 1]])
        XCTAssertEqual(data.value, [0, 1])
    }

    func testDecoderArrayDate() async throws {
        struct Object: Codable, Equatable {
            var value: [Date] = [Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 1)]
        }
        let data = try! FirestoreDecoder().decode(Object.self, from: ["value": [
            Date(timeIntervalSince1970: 0),
            Date(timeIntervalSince1970: 1)
        ]])
        XCTAssertEqual(data.value, [Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 1)])
    }

    func testDecoderArrayTimestamp() async throws {
        struct Object: Codable, Equatable {
            var value: [Timestamp] = [Timestamp(seconds: 0, nanos: 0), Timestamp(seconds: 0, nanos: 1)]
        }
        let data = try! FirestoreDecoder().decode(Object.self, from: ["value": [
            Timestamp(seconds: 0, nanos: 0),
            Timestamp(seconds: 0, nanos: 1)
        ]])
        XCTAssertEqual(data.value, [Timestamp(seconds: 0, nanos: 0), Timestamp(seconds: 0, nanos: 1)])
    }

    func testDecoderArrayGeoPoint() async throws {
        struct Object: Codable, Equatable {
            var value: [GeoPoint] = [GeoPoint(latitude: 0, longitude: 0), GeoPoint(latitude: 0, longitude: 1)]
        }
        let data = try! FirestoreDecoder().decode(Object.self, from: ["value": [
            GeoPoint(latitude: 0, longitude: 0),
            GeoPoint(latitude: 0, longitude: 1)
        ]])
        XCTAssertEqual(data.value, [
            GeoPoint(latitude: 0, longitude: 0),
            GeoPoint(latitude: 0, longitude: 1)
        ])
    }

    func testDecoderArrayDocumentReference() async throws {
        struct Object: Codable, Equatable {
            var value: [DocumentReference] = [
                DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "0"),
                DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "1")
            ]
        }
        let data = try! FirestoreDecoder().decode(Object.self, from: [
            "value": [
                DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "0"),
                DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "1")
            ]
        ])
        XCTAssertEqual(data.value, [
            DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "0"),
            DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "1")
        ])
    }

    func testDecoderNest() async throws {

        struct DeepNestObject: Codable, Equatable {
            var number: Int = 0
            var string: String = "string"
            var bool: Bool = true
            var array: [String] = ["0", "1"]
            var map: [String: String] = ["value": "value"]
            var date: Date = Date(timeIntervalSince1970: 0)
            var timestamp: Timestamp = Timestamp(seconds: 0, nanos: 0)
            var geoPoint: GeoPoint = GeoPoint(latitude: 0, longitude: 0)
            var reference: DocumentReference = DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id")
        }

        struct NestObject: Codable, Equatable {
            var number: Int = 0
            var string: String = "string"
            var bool: Bool = true
            var array: [String] = ["0", "1"]
            var map: [String: String] = ["value": "value"]
            var date: Date = Date(timeIntervalSince1970: 0)
            var nested: DeepNestObject = DeepNestObject()
            var timestamp: Timestamp = Timestamp(seconds: 0, nanos: 0)
            var geoPoint: GeoPoint = GeoPoint(latitude: 0, longitude: 0)
            var reference: DocumentReference = DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id")
        }

        struct Object: Codable, Equatable {
            var number: Int = 0
            var string: String = "string"
            var bool: Bool = true
            var array: [String] = ["0", "1"]
            var map: [String: String] = ["value": "value"]
            var date: Date = Date(timeIntervalSince1970: 0)
            var nested: NestObject = NestObject()
            var timestamp: Timestamp = Timestamp(seconds: 0, nanos: 0)
            var geoPoint: GeoPoint = GeoPoint(latitude: 0, longitude: 0)
            var reference: DocumentReference = DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id")
        }

        let deepNestedData: [String: Any] = [
            "number": 0,
            "string": "string",
            "bool": true,
            "array": ["0", "1"],
            "map": ["key": "value"],
            "date": Date(timeIntervalSince1970: 0),
            "timestamp": Timestamp(seconds: 0, nanos: 0),
            "geoPoint": GeoPoint(latitude: 0, longitude: 0),
            "reference": DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id")
        ]

        let nestedData: [String: Any] = [
            "number": 0,
            "string": "string",
            "bool": true,
            "array": ["0", "1"],
            "map": ["key": "value"],
            "date": Date(timeIntervalSince1970: 0),
            "timestamp": Timestamp(seconds: 0, nanos: 0),
            "geoPoint": GeoPoint(latitude: 0, longitude: 0),
            "reference": DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id"),
            "nested": deepNestedData
        ]

        let object: [String: Any] = [
            "number": 0,
            "string": "string",
            "bool": true,
            "array": ["0", "1"],
            "map": ["key": "value"],
            "date": Date(timeIntervalSince1970: 0),
            "timestamp": Timestamp(seconds: 0, nanos: 0),
            "geoPoint": GeoPoint(latitude: 0, longitude: 0),
            "reference": DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id"),
            "nested": nestedData
        ]

        let data = try! FirestoreDecoder().decode(Object.self, from: object)
        XCTAssertEqual(data.number, 0)
        XCTAssertEqual(data.string, "string")
        XCTAssertEqual(data.bool, true)
        XCTAssertEqual(data.array, ["0", "1"])
        XCTAssertEqual(data.map, ["key": "value"])
        XCTAssertEqual(data.date, Date(timeIntervalSince1970: 0))
        XCTAssertEqual(data.timestamp, Timestamp(seconds: 0, nanos: 0))
        XCTAssertEqual(data.geoPoint, GeoPoint(latitude: 0, longitude: 0))
        XCTAssertEqual(data.reference, DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id"))
        let next = data.nested
        XCTAssertEqual(next.number, 0)
        XCTAssertEqual(next.string, "string")
        XCTAssertEqual(next.bool, true)
        XCTAssertEqual(next.array, ["0", "1"])
        XCTAssertEqual(next.map, ["key": "value"])
        XCTAssertEqual(next.date, Date(timeIntervalSince1970: 0))
        XCTAssertEqual(next.timestamp, Timestamp(seconds: 0, nanos: 0))
        XCTAssertEqual(next.geoPoint, GeoPoint(latitude: 0, longitude: 0))
        XCTAssertEqual(next.reference, DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id"))
        let deep = next.nested
        XCTAssertEqual(deep.number, 0)
        XCTAssertEqual(deep.string, "string")
        XCTAssertEqual(deep.bool, true)
        XCTAssertEqual(deep.array, ["0", "1"])
        XCTAssertEqual(deep.map, ["key": "value"])
        XCTAssertEqual(deep.date, Date(timeIntervalSince1970: 0))
        XCTAssertEqual(deep.timestamp, Timestamp(seconds: 0, nanos: 0))
        XCTAssertEqual(deep.geoPoint, GeoPoint(latitude: 0, longitude: 0))
        XCTAssertEqual(deep.reference, DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id"))
    }
}
