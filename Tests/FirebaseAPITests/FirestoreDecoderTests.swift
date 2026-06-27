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

    @Test("Decode missing ExplicitNull property wrapper")
    func testDecoderMissingExplicitNull() throws {
        struct Object: Codable, Equatable {
            @ExplicitNull var value: String?
        }
        let data = try FirestoreDecoder().decode(Object.self, from: [:] as [String: Any])
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

    @Test("Decode invalid URL string throws decoding error")
    func testDecoderInvalidURLStringThrowsDecodingError() throws {
        do {
            _ = try FirestoreDecoder().decode(URL.self, from: "://bad url")
            Issue.record("Expected invalid URL string to throw a decoding error.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.isEmpty)
        } catch {
            Issue.record("Expected dataCorrupted error, got \(error).")
        }
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

    @Test("Decode numeric values from Firestore storage types")
    func testDecoderNumericValuesFromFirestoreStorageTypes() throws {
        struct Object: Codable, Equatable {
            var int8: Int8
            var int16: Int16
            var int32: Int32
            var int64: Int64
            var uint: UInt
            var uint8: UInt8
            var uint16: UInt16
            var uint32: UInt32
            var uint64: UInt64
            var float: Float
            var double: Double
        }

        let data = try FirestoreDecoder().decode(Object.self, from: [
            "int8": Int64(8),
            "int16": Int64(16),
            "int32": Int64(32),
            "int64": Int64(64),
            "uint": Int64(9),
            "uint8": Int64(18),
            "uint16": Int64(36),
            "uint32": Int64(72),
            "uint64": Int64(144),
            "float": Double(1.5),
            "double": Int64(2)
        ] as [String: Any])

        #expect(data == Object(
            int8: 8,
            int16: 16,
            int32: 32,
            int64: 64,
            uint: 9,
            uint8: 18,
            uint16: 36,
            uint32: 72,
            uint64: 144,
            float: 1.5,
            double: 2
        ))
    }

    @Test("Decode numeric arrays from Firestore storage types")
    func testDecoderNumericArraysFromFirestoreStorageTypes() throws {
        struct Object: Codable, Equatable {
            var int64s: [Int64]
            var floats: [Float]
        }

        let data = try FirestoreDecoder().decode(Object.self, from: [
            "int64s": [Int(1), Int(2)],
            "floats": [Double(1.5), Double(2.5)]
        ] as [String: Any])

        #expect(data == Object(int64s: [1, 2], floats: [1.5, 2.5]))
    }

    @Test("Decode single numeric values from Firestore storage types")
    func testDecoderSingleNumericValuesFromFirestoreStorageTypes() throws {
        let int64 = try FirestoreDecoder().decode(Int64.self, from: Int(42))
        let float = try FirestoreDecoder().decode(Float.self, from: Double(1.25))

        #expect(int64 == 42)
        #expect(float == 1.25)
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

    @Test("Decode invalid Date string throws decoding error")
    func testDecoderInvalidDateStringThrowsDecodingError() throws {
        struct Object: Decodable {
            var value: Date
        }

        do {
            _ = try FirestoreDecoder().decode(Object.self, from: ["value": "not-a-date"])
            Issue.record("Expected invalid Date string to throw a decoding error.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["value"])
        } catch {
            Issue.record("Expected dataCorrupted error, got \(error).")
        }
    }

    @Test("Decode Date preserves timestamp nanoseconds")
    func testDecoderDatePreservesTimestampNanoseconds() throws {
        struct Object: Codable, Equatable {
            var value: Date
        }

        let timestamp = Timestamp(seconds: 10, nanos: 250_000_000)
        let data = try FirestoreDecoder().decode(Object.self, from: ["value": timestamp])
        let single = try FirestoreDecoder().decode(Date.self, from: timestamp)

        #expect(abs(data.value.timeIntervalSince1970 - 10.25) < 0.000_001)
        #expect(abs(single.timeIntervalSince1970 - 10.25) < 0.000_001)
    }

    @Test("Timestamp Date bridge preserves nanoseconds")
    func testTimestampDateBridgePreservesNanoseconds() {
        let timestamp = Timestamp(seconds: 10, nanos: 250_000_000)
        let date = Date(timestamp: timestamp)
        let roundTrip = Timestamp(date)

        #expect(abs(date.timeIntervalSince1970 - 10.25) < 0.000_001)
        #expect(roundTrip == timestamp)
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

    @Test("Decode Data value")
    func testDecoderData() throws {
        struct Object: Codable, Equatable {
            var value: Data
        }
        let bytes = Data([1, 2, 3])
        let data = try FirestoreDecoder().decode(Object.self, from: ["value": bytes])
        #expect(data.value == bytes)
    }

    @Test("Decode FirestoreVector value")
    func testDecoderFirestoreVector() throws {
        struct Object: Codable, Equatable {
            var value: FirestoreVector
        }
        let vector = FirestoreVector([1.0, 2.0, 3.0])
        let data = try FirestoreDecoder().decode(Object.self, from: ["value": vector])
        #expect(data.value == vector)
    }

    @Test("Decode FirestoreVector value from RPC array")
    func testDecoderFirestoreVectorFromRPCArray() throws {
        struct Object: Codable, Equatable {
            var value: FirestoreVector
        }
        let data = try FirestoreDecoder().decode(Object.self, from: ["value": [1.0, 2.0, 3.0]])
        #expect(data.value == FirestoreVector([1.0, 2.0, 3.0]))
    }

    @Test("DocumentSnapshot data(as:) decodes model")
    func testDocumentSnapshotDataAsDecodesModel() throws {
        struct Object: Codable, Equatable {
            @DocumentID var id: String
            var blob: Data
            var embedding: FirestoreVector
        }

        let reference = DocumentReference(Database(projectId: "project"), parentPath: "objects", documentID: "objectID")
        let snapshot = DocumentSnapshot(
            fields: [
                "blob": .bytes(Data([1, 2, 3])),
                "embedding": .array([.double(1.0), .double(2.0), .double(3.0)])
            ],
            documentReference: reference
        )

        let data = try snapshot.data(as: Object.self)

        #expect(snapshot.documentID == "objectID")
        #expect(snapshot.id == "objectID")
        #expect(snapshot.reference == reference)
        #expect(snapshot.documentReference == reference)
        #expect(data?.id == "objectID")
        #expect(data?.blob == Data([1, 2, 3]))
        #expect(data?.embedding == FirestoreVector([1.0, 2.0, 3.0]))
    }

    @Test("DocumentSnapshot data(as:) returns nil for missing document")
    func testDocumentSnapshotDataAsReturnsNilForMissingDocument() throws {
        struct Object: Codable, Equatable {
            var value: String
        }

        let reference = DocumentReference(Database(projectId: "project"), parentPath: "objects", documentID: "objectID")
        let snapshot = DocumentSnapshot(documentReference: reference)
        let data = try snapshot.data(as: Object.self)

        #expect(data == nil)
    }

    @Test("QueryDocumentSnapshot data(as:) decodes model")
    func testQueryDocumentSnapshotDataAsDecodesModel() throws {
        struct Object: Codable, Equatable {
            @DocumentID var id: String
            var name: String
        }

        let reference = DocumentReference(Database(projectId: "project"), parentPath: "objects", documentID: "objectID")
        let snapshot = QueryDocumentSnapshot(
            fields: ["name": .string("Ada")],
            documentReference: reference
        )

        let data = try snapshot.data(as: Object.self)

        #expect(snapshot.documentID == "objectID")
        #expect(snapshot.id == "objectID")
        #expect(snapshot.reference == reference)
        #expect(snapshot.documentReference == reference)
        #expect(data.id == "objectID")
        #expect(data.name == "Ada")
    }

    @Test("QuerySnapshot documents(as:) decodes models")
    func testQuerySnapshotDocumentsAsDecodesModels() throws {
        struct Object: Codable, Equatable {
            @DocumentID var id: String
            var embedding: FirestoreVector
        }

        let database = Database(projectId: "project")
        let snapshot = QuerySnapshot(
            documents: [
                QueryDocumentSnapshot(
                    fields: ["embedding": .array([.double(1.0), .double(2.0)])],
                    documentReference: DocumentReference(database, parentPath: "objects", documentID: "one")
                ),
                QueryDocumentSnapshot(
                    fields: ["embedding": .array([.double(3.0), .double(4.0)])],
                    documentReference: DocumentReference(database, parentPath: "objects", documentID: "two")
                )
            ]
        )

        let data = try snapshot.documents(as: Object.self)

        #expect(data == [
            Object(id: "one", embedding: FirestoreVector([1.0, 2.0])),
            Object(id: "two", embedding: FirestoreVector([3.0, 4.0]))
        ])
    }

    @Test("DocumentSnapshot get reads field paths")
    func testDocumentSnapshotGetReadsFieldPaths() throws {
        let timestamp = Timestamp(seconds: 1, nanos: 2)
        let reference = DocumentReference(Database(projectId: "project"), parentPath: "objects", documentID: "objectID")
        let snapshot = DocumentSnapshot(
            fields: [
                "profile": .map(["name": .string("Ada")]),
                "profile.name": .string("Literal"),
                "updatedAt": .timestamp(timestamp)
            ],
            documentReference: reference
        )
        let querySnapshot = QueryDocumentSnapshot(
            fields: [
                "profile": .map(["name": .string("Ada")])
            ],
            documentReference: reference
        )

        #expect(snapshot.get("profile.name") as? String == "Ada")
        #expect(snapshot.get(FieldPath("profile.name")) as? String == "Literal")
        #expect(snapshot.get(FieldPath("profile", "name")) as? String == "Ada")
        #expect(snapshot.get("missing") == nil)
        #expect(snapshot.get("updatedAt", serverTimestampBehavior: .estimate) as? Timestamp == timestamp)
        #expect(snapshot.data(with: .previous)?["updatedAt"] as? Timestamp == timestamp)
        #expect(snapshot["profile.name"] as? String == "Ada")
        #expect(snapshot[FieldPath("profile.name")] as? String == "Literal")
        #expect(querySnapshot.get("profile.name") as? String == "Ada")
        #expect(querySnapshot["profile.name"] as? String == "Ada")
        #expect(querySnapshot.data(with: .none)["profile"] is [String: Any])
        #expect(snapshot.get("profile.") == nil)
    }

    @Test("Decode ServerTimestamp property wrapper value")
    func testDecoderServerTimestampValue() throws {
        struct Object: Codable, Equatable {
            @ServerTimestamp var updatedAt: Timestamp?
        }
        let timestamp = Timestamp(seconds: 1, nanos: 2)
        let data = try FirestoreDecoder().decode(Object.self, from: ["updatedAt": timestamp])
        #expect(data.updatedAt == timestamp)
    }

    @Test("Decode missing ServerTimestamp property wrapper")
    func testDecoderMissingServerTimestamp() throws {
        struct Object: Codable, Equatable {
            @ServerTimestamp var updatedAt: Timestamp?
        }
        let data = try FirestoreDecoder().decode(Object.self, from: [:] as [String: Any])
        #expect(data.updatedAt == nil)
    }

    @Test("Decode missing required custom value with reference throws decoding error")
    func testDecoderMissingRequiredCustomValueWithReferenceThrowsDecodingError() throws {
        struct Nested: Decodable {
            var value: Int
        }
        struct Object: Decodable {
            var nested: Nested
        }

        let database = Database(projectId: "project")
        let ref = DocumentReference(database, parentPath: "objects", documentID: "objectID")

        do {
            _ = try FirestoreDecoder().decode(Object.self, from: [:] as [String: Any], in: ref)
            Issue.record("Expected missing required custom value to throw a decoding error.")
        } catch DecodingError.valueNotFound(let type, let context) {
            #expect(String(reflecting: type) == String(reflecting: Nested.self))
            #expect(context.codingPath.map(\.stringValue) == ["nested"])
        } catch {
            Issue.record("Expected valueNotFound error, got \(error).")
        }
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
