//
//  FirestoreDecoderTests.swift
//  
//
//  Created by Norikazu Muramoto on 2023/05/04.
//

import XCTest
@testable import FirestoreAPI

final class FirestoreDecoderTests: XCTestCase {

    func testDecoderCodingPath() async throws {
        struct Deep: Identifiable, Codable, Equatable {
            @DocumentID var id: String
            var intValue: [Int] = []
            var stringValue: Int = 0
        }
        struct Nested: Identifiable, Codable, Equatable {
            @DocumentID var id: String
            var second: Deep = Deep(id: "id")
        }
        struct Object: Identifiable, Codable, Equatable {
            @DocumentID var id: String
            var first: Nested = Nested(id: "id")
        }
        let database = Database(projectId: "project")
        let ref = DocumentReference(database, parentPath: "objects", documentID: "objectID")

        do {
            let data = try FirestoreDecoder().decode(Object.self, from: [
                "first": [
                    "id": "nestedID",
                    "second": [
                        "id": "deepID",
                        "intValue": ["0"],
                        "stringValue": "0"
                    ]
                ]
            ] as [String: Any], in: ref)
        } catch {
            print(error)
        }
    }

    func testDecoderDocumentID() async throws {
        struct Nested: Identifiable, Codable, Equatable {
            @DocumentID var id: String
        }
        struct Object: Identifiable, Codable, Equatable {
            @DocumentID var id: String
            var nested: Nested = Nested(id: "id")
        }
        let database = Database(projectId: "project")
        let ref = DocumentReference(database, parentPath: "objects", documentID: "objectID")
        let data = try! FirestoreDecoder().decode(Object.self, from: ["nested": ["id": "nestedID"]] as [String: Any], in: ref)

        XCTAssertEqual(data.id, "objectID")
        XCTAssertEqual(data.nested.id, "nestedID")
    }
    
    func testDecoderReferencePath() async throws {
        struct Nested: Identifiable, Codable, Equatable {
            @DocumentID var id: String
            @ReferencePath var path: String
        }
        struct Object: Codable, Equatable {
            @ReferencePath var path: String
            var nested: Nested = Nested(id: "id", path: "path")
        }
        let database = Database(projectId: "project")
        let ref = DocumentReference(database, parentPath: "objects", documentID: "objectID")
        let data = try! FirestoreDecoder().decode(Object.self, from: ["nested": ["id": "nestedID", "path": "path"]] as [String: Any], in: ref)

        XCTAssertEqual(data.path, "objects/objectID")
        XCTAssertEqual(data.nested.id, "nestedID")
        XCTAssertEqual(data.nested.path, "path")
    }

    func testDecoderNull() async throws {
        struct Object: Codable, Equatable {
            var value: String?
        }
        let data = try! FirestoreDecoder().decode(Object.self, from: [:] as [String: Any])
        XCTAssertNil(data.value)
    }

    func testDecoderExplicitNull() async throws {
        struct Object: Codable, Equatable {
            @ExplicitNull var value: String?
        }
        let data = try! FirestoreDecoder().decode(Object.self, from: ["value": NSNull()] as [String: Any])
        XCTAssertNil(data.value)
    }

    func testDecoderString() async throws {
        struct Object: Codable, Equatable {
            var value: String = "string"
        }
        let data = try! FirestoreDecoder().decode(Object.self, from: ["value": "string"])
        XCTAssertEqual(data.value, "string")
    }

    func testDecoderURL() async throws {
        struct Object: Codable, Equatable {
            var value: URL = URL(string: "https://firebase.google.com/")!
        }
        let data = try! FirestoreDecoder().decode(Object.self, from: ["value": "https://firebase.google.com/"])
        XCTAssertEqual(data.value, URL(string: "https://firebase.google.com/")!)
    }

    func testDecoderInt() async throws {
        struct Object: Codable, Equatable {
            var value: Int = 0
        }
        let data = try! FirestoreDecoder().decode(Object.self, from: ["value": 0])
        XCTAssertEqual(data.value, 0)
    }

    func testDecoderDouble() async throws {
        struct Object: Codable, Equatable {
            var value: Double = 0
        }
        let data = try! FirestoreDecoder().decode(Object.self, from: ["value": 0.0])
        XCTAssertEqual(data.value, 0.0)
    }

    func testDecoderDecimal() async throws {
        struct Object: Codable, Equatable {
            var value: Decimal = 0
        }
        let data = try! FirestoreDecoder().decode(Object.self, from: ["value": 0.0])
        XCTAssertEqual(data.value, 0.0)
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
        let dateForamatter: DateFormatter = {
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = .autoupdatingCurrent
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
            return dateFormatter
        }()
        let data = try! FirestoreDecoder().decode(Object.self, from: ["value": dateForamatter.string(from: Date(timeIntervalSince1970: 0))])
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

    func testDecoderArrayURL() async throws {
        struct Object: Codable, Equatable {
            var value: [URL] = [URL(string: "https://firebase.google.com/")!, URL(string: "https://console.cloud.google.com/")!]
        }
        let data = try! FirestoreDecoder().decode(Object.self, from: ["value": ["https://firebase.google.com/", "https://console.cloud.google.com/"]])
        XCTAssertEqual(data.value, [URL(string: "https://firebase.google.com/")!, URL(string: "https://console.cloud.google.com/")!])
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
        let dateForamatter: DateFormatter = {
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = .autoupdatingCurrent
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
            return dateFormatter
        }()
        let data = try! FirestoreDecoder().decode(Object.self, from: ["value": [
            dateForamatter.string(from: Date(timeIntervalSince1970: 0)),
            dateForamatter.string(from: Date(timeIntervalSince1970: 1))
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

        enum EnumValue: String, Codable {
            case value
        }

        struct DeepNestObject: Codable, Equatable {
            var number: Int = 0
            var string: String = "string"
            var url: URL = URL(string: "https://firebase.google.com/")!
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
            var url: URL = URL(string: "https://firebase.google.com/")!
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
            var url: URL = URL(string: "https://firebase.google.com/")!
            var bool: Bool = true
            var array: [String] = ["0", "1"]
            var map: [String: String] = ["value": "value"]
            var date: Date = Date(timeIntervalSince1970: 0)
            var nested: NestObject = NestObject()
            var enumValue: EnumValue = .value
            var timestamp: Timestamp = Timestamp(seconds: 0, nanos: 0)
            var geoPoint: GeoPoint = GeoPoint(latitude: 0, longitude: 0)
            var reference: DocumentReference = DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id")
        }

        let dateForamatter: DateFormatter = {
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = .autoupdatingCurrent
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
            return dateFormatter
        }()

        let deepNestedData: [String: Any] = [
            "number": 0,
            "string": "string",
            "url": "https://firebase.google.com/",
            "bool": true,
            "array": ["0", "1"],
            "map": ["key": "value"],
            "date": dateForamatter.string(from: Date(timeIntervalSince1970: 0)),
            "timestamp": Timestamp(seconds: 0, nanos: 0),
            "geoPoint": GeoPoint(latitude: 0, longitude: 0),
            "reference": DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id")
        ]

        let nestedData: [String: Any] = [
            "number": 0,
            "string": "string",
            "url": "https://firebase.google.com/",
            "bool": true,
            "array": ["0", "1"],
            "map": ["key": "value"],
            "date": dateForamatter.string(from: Date(timeIntervalSince1970: 0)),
            "timestamp": Timestamp(seconds: 0, nanos: 0),
            "geoPoint": GeoPoint(latitude: 0, longitude: 0),
            "reference": DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id"),
            "nested": deepNestedData
        ]

        let object: [String: Any] = [
            "number": 0,
            "string": "string",
            "url": "https://firebase.google.com/",
            "bool": true,
            "array": ["0", "1"],
            "map": ["key": "value"],
            "date": dateForamatter.string(from: Date(timeIntervalSince1970: 0)),
            "enumValue": "value",
            "timestamp": Timestamp(seconds: 0, nanos: 0),
            "geoPoint": GeoPoint(latitude: 0, longitude: 0),
            "reference": DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id"),
            "nested": nestedData
        ]

        let data = try! FirestoreDecoder().decode(Object.self, from: object)
        XCTAssertEqual(data.number, 0)
        XCTAssertEqual(data.string, "string")
        XCTAssertEqual(data.url, URL(string: "https://firebase.google.com/")!)
        XCTAssertEqual(data.bool, true)
        XCTAssertEqual(data.array, ["0", "1"])
        XCTAssertEqual(data.map, ["key": "value"])
        XCTAssertEqual(data.date, Date(timeIntervalSince1970: 0))
        XCTAssertEqual(data.enumValue, .value)
        XCTAssertEqual(data.timestamp, Timestamp(seconds: 0, nanos: 0))
        XCTAssertEqual(data.geoPoint, GeoPoint(latitude: 0, longitude: 0))
        XCTAssertEqual(data.reference, DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id"))
        let next = data.nested
        XCTAssertEqual(next.number, 0)
        XCTAssertEqual(next.string, "string")
        XCTAssertEqual(next.url, URL(string: "https://firebase.google.com/")!)
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
        XCTAssertEqual(deep.url, URL(string: "https://firebase.google.com/")!)
        XCTAssertEqual(deep.bool, true)
        XCTAssertEqual(deep.array, ["0", "1"])
        XCTAssertEqual(deep.map, ["key": "value"])
        XCTAssertEqual(deep.date, Date(timeIntervalSince1970: 0))
        XCTAssertEqual(deep.timestamp, Timestamp(seconds: 0, nanos: 0))
        XCTAssertEqual(deep.geoPoint, GeoPoint(latitude: 0, longitude: 0))
        XCTAssertEqual(deep.reference, DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id"))
    }
}
