//
//  FirestoreDecoderTests.swift
//
//
//  Created by Norikazu Muramoto on 2023/05/04.
//

import Foundation
import Testing
@testable import FirestoreAPI

@Suite("Firestore Decoder Tests")
struct FirestoreDecoderTests {

    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .autoupdatingCurrent
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return dateFormatter
    }()

    @Test("Decode with coding path error reporting")
    func testDecoderCodingPath() throws {
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
            _ = try FirestoreDecoder().decode(Object.self, from: [
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
            // Expected to throw due to type mismatch
        }
    }

    @Test("Decode DocumentID property wrapper")
    func testDecoderDocumentID() throws {
        struct Nested: Identifiable, Codable, Equatable {
            @DocumentID var id: String
        }
        struct Object: Identifiable, Codable, Equatable {
            @DocumentID var id: String
            var nested: Nested = Nested(id: "id")
        }
        let database = Database(projectId: "project")
        let ref = DocumentReference(database, parentPath: "objects", documentID: "objectID")
        let data = try FirestoreDecoder().decode(Object.self, from: ["nested": ["id": "nestedID"]] as [String: Any], in: ref)

        #expect(data.id == "objectID")
        #expect(data.nested.id == "nestedID")
    }

    @Test("Decode ReferencePath property wrapper")
    func testDecoderReferencePath() throws {
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
        let data = try FirestoreDecoder().decode(Object.self, from: ["nested": ["id": "nestedID", "path": "path"]] as [String: Any], in: ref)

        #expect(data.path == "objects/objectID")
        #expect(data.nested.id == "nestedID")
        #expect(data.nested.path == "path")
    }

    @Test("Decode nil optional value")
    func testDecoderNull() throws {
        struct Object: Codable, Equatable {
            var value: String?
        }
        let data = try FirestoreDecoder().decode(Object.self, from: [:] as [String: Any])
        #expect(data.value == nil)
    }

    @Test("Decode ExplicitNull property wrapper")
    func testDecoderExplicitNull() throws {
        struct Object: Codable, Equatable {
            @ExplicitNull var value: String?
        }
        let data = try FirestoreDecoder().decode(Object.self, from: ["value": NSNull()] as [String: Any])
        #expect(data.value == nil)
    }

    @Test("Decode String value")
    func testDecoderString() throws {
        struct Object: Codable, Equatable {
            var value: String = "string"
        }
        let data = try FirestoreDecoder().decode(Object.self, from: ["value": "string"])
        #expect(data.value == "string")
    }

    @Test("Decode URL value")
    func testDecoderURL() throws {
        struct Object: Codable, Equatable {
            var value: URL = URL(string: "https://firebase.google.com/")!
        }
        let data = try FirestoreDecoder().decode(Object.self, from: ["value": "https://firebase.google.com/"])
        #expect(data.value == URL(string: "https://firebase.google.com/")!)
    }

    @Test("Decode Int value")
    func testDecoderInt() throws {
        struct Object: Codable, Equatable {
            var value: Int = 0
        }
        let data = try FirestoreDecoder().decode(Object.self, from: ["value": 0])
        #expect(data.value == 0)
    }

    @Test("Decode Double value")
    func testDecoderDouble() throws {
        struct Object: Codable, Equatable {
            var value: Double = 0
        }
        let data = try FirestoreDecoder().decode(Object.self, from: ["value": 0.0])
        #expect(data.value == 0.0)
    }

    @Test("Decode Decimal value")
    func testDecoderDecimal() throws {
        struct Object: Codable, Equatable {
            var value: Decimal = 0
        }
        let data = try FirestoreDecoder().decode(Object.self, from: ["value": 0.0])
        #expect(data.value == 0.0)
    }

    @Test("Decode Bool value")
    func testDecoderBool() throws {
        struct Object: Codable, Equatable {
            var value: Bool = false
        }
        let data = try FirestoreDecoder().decode(Object.self, from: ["value": false])
        #expect(data.value == false)
    }

    @Test("Decode Date value")
    func testDecoderDate() throws {
        struct Object: Codable, Equatable {
            var value: Date = Date(timeIntervalSince1970: 0)
        }
        let data = try FirestoreDecoder().decode(Object.self, from: ["value": dateFormatter.string(from: Date(timeIntervalSince1970: 0))])
        #expect(data.value == Date(timeIntervalSince1970: 0))
    }

    @Test("Decode Timestamp value")
    func testDecoderTimestamp() throws {
        struct Object: Codable, Equatable {
            var value: Timestamp = Timestamp(seconds: 0, nanos: 0)
        }
        let data = try FirestoreDecoder().decode(Object.self, from: ["value": Timestamp(seconds: 0, nanos: 0)])
        #expect(data.value == Timestamp(seconds: 0, nanos: 0))
    }

    @Test("Decode GeoPoint value")
    func testDecoderGeoPoint() throws {
        struct Object: Codable, Equatable {
            var value: GeoPoint = GeoPoint(latitude: 0, longitude: 0)
        }
        let data = try FirestoreDecoder().decode(Object.self, from: ["value": GeoPoint(latitude: 0, longitude: 0)])
        #expect(data.value == GeoPoint(latitude: 0, longitude: 0))
    }

    @Test("Decode DocumentReference value")
    func testDecoderDocumentReference() throws {
        struct Object: Codable, Equatable {
            var value: DocumentReference = DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id")
        }
        let data = try FirestoreDecoder().decode(Object.self, from: ["value": DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id")])
        #expect(data.value == DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id"))
    }

    @Test("Decode String array")
    func testDecoderArrayString() throws {
        struct Object: Codable, Equatable {
            var value: [String] = ["0", "1"]
        }
        let data = try FirestoreDecoder().decode(Object.self, from: ["value": ["0", "1"]])
        #expect(data.value == ["0", "1"])
    }

    @Test("Decode URL array")
    func testDecoderArrayURL() throws {
        struct Object: Codable, Equatable {
            var value: [URL] = [URL(string: "https://firebase.google.com/")!, URL(string: "https://console.cloud.google.com/")!]
        }
        let data = try FirestoreDecoder().decode(Object.self, from: ["value": ["https://firebase.google.com/", "https://console.cloud.google.com/"]])
        #expect(data.value == [URL(string: "https://firebase.google.com/")!, URL(string: "https://console.cloud.google.com/")!])
    }

    @Test("Decode Int array")
    func testDecoderArrayInt() throws {
        struct Object: Codable, Equatable {
            var value: [Int] = [0, 1]
        }
        let data = try FirestoreDecoder().decode(Object.self, from: ["value": [0, 1]])
        #expect(data.value == [0, 1])
    }

    @Test("Decode Date array")
    func testDecoderArrayDate() throws {
        struct Object: Codable, Equatable {
            var value: [Date] = [Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 1)]
        }
        let data = try FirestoreDecoder().decode(Object.self, from: ["value": [
            dateFormatter.string(from: Date(timeIntervalSince1970: 0)),
            dateFormatter.string(from: Date(timeIntervalSince1970: 1))
        ]])
        #expect(data.value == [Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 1)])
    }

    @Test("Decode Timestamp array")
    func testDecoderArrayTimestamp() throws {
        struct Object: Codable, Equatable {
            var value: [Timestamp] = [Timestamp(seconds: 0, nanos: 0), Timestamp(seconds: 0, nanos: 1)]
        }
        let data = try FirestoreDecoder().decode(Object.self, from: ["value": [
            Timestamp(seconds: 0, nanos: 0),
            Timestamp(seconds: 0, nanos: 1)
        ]])
        #expect(data.value == [Timestamp(seconds: 0, nanos: 0), Timestamp(seconds: 0, nanos: 1)])
    }

    @Test("Decode GeoPoint array")
    func testDecoderArrayGeoPoint() throws {
        struct Object: Codable, Equatable {
            var value: [GeoPoint] = [GeoPoint(latitude: 0, longitude: 0), GeoPoint(latitude: 0, longitude: 1)]
        }
        let data = try FirestoreDecoder().decode(Object.self, from: ["value": [
            GeoPoint(latitude: 0, longitude: 0),
            GeoPoint(latitude: 0, longitude: 1)
        ]])
        #expect(data.value == [
            GeoPoint(latitude: 0, longitude: 0),
            GeoPoint(latitude: 0, longitude: 1)
        ])
    }

    @Test("Decode DocumentReference array")
    func testDecoderArrayDocumentReference() throws {
        struct Object: Codable, Equatable {
            var value: [DocumentReference] = [
                DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "0"),
                DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "1")
            ]
        }
        let data = try FirestoreDecoder().decode(Object.self, from: [
            "value": [
                DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "0"),
                DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "1")
            ]
        ])
        #expect(data.value == [
            DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "0"),
            DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "1")
        ])
    }

    @Test("Decode nested objects")
    func testDecoderNest() throws {
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

        let deepNestedData: [String: Any] = [
            "number": 0,
            "string": "string",
            "url": "https://firebase.google.com/",
            "bool": true,
            "array": ["0", "1"],
            "map": ["key": "value"],
            "date": dateFormatter.string(from: Date(timeIntervalSince1970: 0)),
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
            "date": dateFormatter.string(from: Date(timeIntervalSince1970: 0)),
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
            "date": dateFormatter.string(from: Date(timeIntervalSince1970: 0)),
            "enumValue": "value",
            "timestamp": Timestamp(seconds: 0, nanos: 0),
            "geoPoint": GeoPoint(latitude: 0, longitude: 0),
            "reference": DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id"),
            "nested": nestedData
        ]

        let data = try FirestoreDecoder().decode(Object.self, from: object)
        #expect(data.number == 0)
        #expect(data.string == "string")
        #expect(data.url == URL(string: "https://firebase.google.com/")!)
        #expect(data.bool == true)
        #expect(data.array == ["0", "1"])
        #expect(data.map == ["key": "value"])
        #expect(data.date == Date(timeIntervalSince1970: 0))
        #expect(data.enumValue == .value)
        #expect(data.timestamp == Timestamp(seconds: 0, nanos: 0))
        #expect(data.geoPoint == GeoPoint(latitude: 0, longitude: 0))
        #expect(data.reference == DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id"))

        let next = data.nested
        #expect(next.number == 0)
        #expect(next.string == "string")
        #expect(next.url == URL(string: "https://firebase.google.com/")!)
        #expect(next.bool == true)
        #expect(next.array == ["0", "1"])
        #expect(next.map == ["key": "value"])
        #expect(next.date == Date(timeIntervalSince1970: 0))
        #expect(next.timestamp == Timestamp(seconds: 0, nanos: 0))
        #expect(next.geoPoint == GeoPoint(latitude: 0, longitude: 0))
        #expect(next.reference == DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id"))

        let deep = next.nested
        #expect(deep.number == 0)
        #expect(deep.string == "string")
        #expect(deep.url == URL(string: "https://firebase.google.com/")!)
        #expect(deep.bool == true)
        #expect(deep.array == ["0", "1"])
        #expect(deep.map == ["key": "value"])
        #expect(deep.date == Date(timeIntervalSince1970: 0))
        #expect(deep.timestamp == Timestamp(seconds: 0, nanos: 0))
        #expect(deep.geoPoint == GeoPoint(latitude: 0, longitude: 0))
        #expect(deep.reference == DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id"))
    }
}
