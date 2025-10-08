//
//  FirestoreEncoderTests.swift
//
//
//  Created by Norikazu Muramoto on 2023/05/04.
//

import Foundation
import Testing
@testable import FirestoreAPI

@Suite("Firestore Encoder Tests")
struct FirestoreEncoderTests {

    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .autoupdatingCurrent
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return dateFormatter
    }()

    @Test("Encode DocumentID property wrapper")
    func testEncoderDocumentID() throws {
        struct Nested: Identifiable, Codable, Equatable {
            @DocumentID var id: String
        }
        struct Object: Identifiable, Codable, Equatable {
            @DocumentID var id: String
            var nested: Nested = Nested(id: "id")
        }
        let data = try FirestoreEncoder().encode(Object(id: "id"))
        #expect(data["nested"] as! [String: String] == ["id": "id"])
    }

    @Test("Encode nil optional value")
    func testEncoderNull() throws {
        struct Object: Codable, Equatable {
            var key: String?
        }
        let data = try FirestoreEncoder().encode(Object())
        let key = data.keys.first
        let value = data["key"] as? String

        #expect(key == nil)
        #expect(value == nil)
    }

    @Test("Encode ExplicitNull property wrapper")
    func testEncoderExplicitNull() throws {
        struct Object: Codable, Equatable {
            @ExplicitNull var key: String?
        }
        let data = try FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as? String

        #expect(key == "key")
        #expect(value == nil)
    }

    @Test("Encode String value")
    func testEncoderString() throws {
        struct Object: Codable, Equatable {
            var key: String = "string"
        }
        let data = try FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! String

        #expect(key == "key")
        #expect(value == "string")
    }

    @Test("Encode URL value")
    func testEncoderURL() throws {
        struct Object: Codable, Equatable {
            var key: URL = URL(string: "https://firebase.google.com/")!
        }
        let data = try FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! String

        #expect(key == "key")
        #expect(value == "https://firebase.google.com/")
    }

    @Test("Encode Int value")
    func testEncoderInt() throws {
        struct Object: Codable, Equatable {
            var key: Int = 0
        }
        let data = try FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! Int

        #expect(key == "key")
        #expect(value == 0)
    }

    @Test("Encode Double value")
    func testEncoderDouble() throws {
        struct Object: Codable, Equatable {
            var key: Double = 0.0
        }
        let data = try FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! Double

        #expect(key == "key")
        #expect(value == 0)
    }

    @Test("Encode Decimal value")
    func testEncoderDecimal() throws {
        struct Object: Codable, Equatable {
            var key: Decimal = 0.0
        }
        let data = try FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! Double

        #expect(key == "key")
        #expect(value == 0)
    }

    @Test("Encode Bool value")
    func testEncoderBool() throws {
        struct Object: Codable, Equatable {
            var key: Bool = false
        }
        let data = try FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! Bool

        #expect(key == "key")
        #expect(value == false)
    }

    @Test("Encode Date value")
    func testEncoderDate() throws {
        struct Object: Codable, Equatable {
            var key: Date = Date(timeIntervalSince1970: 0)
        }
        let data = try FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! String

        #expect(key == "key")
        #expect(value == dateFormatter.string(from: Date(timeIntervalSince1970: 0)))
    }

    @Test("Encode Timestamp value")
    func testEncoderTimestamp() throws {
        struct Object: Codable, Equatable {
            var key: Timestamp = Timestamp(seconds: 0, nanos: 0)
        }
        let data = try FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! Timestamp

        #expect(key == "key")
        #expect(value == Timestamp(seconds: 0, nanos: 0))
    }

    @Test("Encode GeoPoint value")
    func testEncoderGeoPoint() throws {
        struct Object: Codable, Equatable {
            var key: GeoPoint = GeoPoint(latitude: 0, longitude: 0)
        }
        let data = try FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! GeoPoint

        #expect(key == "key")
        #expect(value == GeoPoint(latitude: 0, longitude: 0))
    }

    @Test("Encode DocumentReference value")
    func testEncoderDocumentReference() throws {
        struct Object: Codable, Equatable {
            var key: DocumentReference = DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id")
        }
        let data = try FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! DocumentReference

        #expect(key == "key")
        #expect(value == DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id"))
    }

    @Test("Encode String array")
    func testEncoderArrayString() throws {
        struct Object: Codable, Equatable {
            var key: [String] = ["0", "1"]
        }
        let data = try FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! [String]

        #expect(key == "key")
        #expect(value == ["0", "1"])
    }

    @Test("Encode URL array")
    func testEncoderArrayURL() throws {
        struct Object: Codable, Equatable {
            var key: [URL] = [URL(string: "https://firebase.google.com/")!, URL(string: "https://console.cloud.google.com/")!]
        }
        let data = try FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! [String]

        #expect(key == "key")
        #expect(value == ["https://firebase.google.com/", "https://console.cloud.google.com/"])
    }

    @Test("Encode Int array")
    func testEncoderArrayInt() throws {
        struct Object: Codable, Equatable {
            var key: [Int] = [0, 1]
        }
        let data = try FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! [Int]

        #expect(key == "key")
        #expect(value == [0, 1])
    }

    @Test("Encode Date array")
    func testEncoderArrayDate() throws {
        struct Object: Codable, Equatable {
            var key: [Date] = [Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 1)]
        }
        let data = try FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! [String]

        #expect(key == "key")
        #expect(value == [dateFormatter.string(from: Date(timeIntervalSince1970: 0)), dateFormatter.string(from: Date(timeIntervalSince1970: 1))])
    }

    @Test("Encode Timestamp array")
    func testEncoderArrayTimestamp() throws {
        struct Object: Codable, Equatable {
            var key: [Timestamp] = [Timestamp(seconds: 0, nanos: 0), Timestamp(seconds: 0, nanos: 1)]
        }
        let data = try FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! [Timestamp]

        #expect(key == "key")
        #expect(value == [Timestamp(seconds: 0, nanos: 0), Timestamp(seconds: 0, nanos: 1)])
    }

    @Test("Encode GeoPoint array")
    func testEncoderArrayGeoPoint() throws {
        struct Object: Codable, Equatable {
            var key: [GeoPoint] = [GeoPoint(latitude: 0, longitude: 0), GeoPoint(latitude: 0, longitude: 1)]
        }
        let data = try FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! [GeoPoint]

        #expect(key == "key")
        #expect(value == [GeoPoint(latitude: 0, longitude: 0), GeoPoint(latitude: 0, longitude: 1)])
    }

    @Test("Encode DocumentReference array")
    func testEncoderArrayDocumentReference() throws {
        struct Object: Codable, Equatable {
            var key: [DocumentReference] = [
                DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "0"),
                DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "1")
            ]
        }
        let data = try FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! [DocumentReference]

        #expect(key == "key")
        #expect(value == [
            DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "0"),
            DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "1")
        ])
    }

    @Test("Encode nested objects")
    func testEncoderNest() throws {
        struct DeepNestObject: Codable, Equatable {
            var number: Int = 0
            var string: String = "string"
            var url: URL = URL(string: "https://firebase.google.com/")!
            var bool: Bool = true
            var array: [String] = ["0", "1"]
            var map: [String: String] = ["key": "value"]
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
            var map: [String: String] = ["key": "value"]
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
            var map: [String: String] = ["key": "value"]
            var date: Date = Date(timeIntervalSince1970: 0)
            var nested: NestObject = NestObject()
            var timestamp: Timestamp = Timestamp(seconds: 0, nanos: 0)
            var geoPoint: GeoPoint = GeoPoint(latitude: 0, longitude: 0)
            var reference: DocumentReference = DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id")
        }

        let data = try FirestoreEncoder().encode(Object())
        #expect(data["number"] as! Int == 0)
        #expect(data["string"] as! String == "string")
        #expect(data["url"] as! String == "https://firebase.google.com/")
        #expect(data["bool"] as! Bool == true)
        #expect(data["array"] as! [String] == ["0", "1"])
        #expect(data["map"] as! [String: String] == ["key": "value"])
        #expect(data["date"] as! String == dateFormatter.string(from: Date(timeIntervalSince1970: 0)))
        #expect(data["timestamp"] as! Timestamp == Timestamp(seconds: 0, nanos: 0))
        #expect(data["geoPoint"] as! GeoPoint == GeoPoint(latitude: 0, longitude: 0))
        #expect(data["reference"] as! DocumentReference == DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id"))

        let next = data["nested"] as! [String: Any]
        #expect(next["number"] as! Int == 0)
        #expect(next["string"] as! String == "string")
        #expect(next["url"] as! String == "https://firebase.google.com/")
        #expect(next["bool"] as! Bool == true)
        #expect(next["array"] as! [String] == ["0", "1"])
        #expect(next["map"] as! [String: String] == ["key": "value"])
        #expect(next["date"] as! String == dateFormatter.string(from: Date(timeIntervalSince1970: 0)))
        #expect(next["timestamp"] as! Timestamp == Timestamp(seconds: 0, nanos: 0))
        #expect(next["geoPoint"] as! GeoPoint == GeoPoint(latitude: 0, longitude: 0))
        #expect(next["reference"] as! DocumentReference == DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id"))

        let deep = next["nested"] as! [String: Any]
        #expect(deep["number"] as! Int == 0)
        #expect(deep["string"] as! String == "string")
        #expect(deep["url"] as! String == "https://firebase.google.com/")
        #expect(deep["bool"] as! Bool == true)
        #expect(deep["array"] as! [String] == ["0", "1"])
        #expect(deep["map"] as! [String: String] == ["key": "value"])
        #expect(data["date"] as! String == dateFormatter.string(from: Date(timeIntervalSince1970: 0)))
        #expect(deep["timestamp"] as! Timestamp == Timestamp(seconds: 0, nanos: 0))
        #expect(deep["geoPoint"] as! GeoPoint == GeoPoint(latitude: 0, longitude: 0))
        #expect(deep["reference"] as! DocumentReference == DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id"))
    }
}
