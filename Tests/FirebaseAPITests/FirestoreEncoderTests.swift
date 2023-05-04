import XCTest
@testable import FirestoreAPI

final class FirestoreEncoderTests: XCTestCase {

    func testEncoderString() async throws {
        struct Object: Codable, Equatable {
            var key: String = "string"
        }
        let data = try! FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! String

        XCTAssertEqual(key, "key")
        XCTAssertEqual(value, "string")
    }

    func testEncoderInt() async throws {
        struct Object: Codable, Equatable {
            var key: Int = 0
        }
        let data = try! FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! Int

        XCTAssertEqual(key, "key")
        XCTAssertEqual(value, 0)
    }

    func testEncoderBool() async throws {
        struct Object: Codable, Equatable {
            var key: Bool = false
        }
        let data = try! FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! Bool

        XCTAssertEqual(key, "key")
        XCTAssertEqual(value, false)
    }

    func testEncoderDate() async throws {
        struct Object: Codable, Equatable {
            var key: Date = Date(timeIntervalSince1970: 0)
        }
        let data = try! FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! Date

        XCTAssertEqual(key, "key")
        XCTAssertEqual(value, Date(timeIntervalSince1970: 0))
    }

    func testEncoderTimestamp() async throws {
        struct Object: Codable, Equatable {
            var key: Timestamp = Timestamp(seconds: 0, nanos: 0)
        }
        let data = try! FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! Timestamp

        XCTAssertEqual(key, "key")
        XCTAssertEqual(value, Timestamp(seconds: 0, nanos: 0))
    }

    func testEncoderGeoPoint() async throws {
        struct Object: Codable, Equatable {
            var key: GeoPoint = GeoPoint(latitude: 0, longitude: 0)
        }
        let data = try! FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! GeoPoint

        XCTAssertEqual(key, "key")
        XCTAssertEqual(value, GeoPoint(latitude: 0, longitude: 0))
    }

    func testEncoderDocumentReference() async throws {
        struct Object: Codable, Equatable {
            var key: DocumentReference = DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id")
        }
        let data = try! FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! DocumentReference

        XCTAssertEqual(key, "key")
        XCTAssertEqual(value, DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id"))
    }

    func testEncoderArrayString() async throws {
        struct Object: Codable, Equatable {
            var key: [String] = ["0", "1"]
        }
        let data = try! FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! [String]

        XCTAssertEqual(key, "key")
        XCTAssertEqual(value, ["0", "1"])
    }

    func testEncoderArrayInt() async throws {
        struct Object: Codable, Equatable {
            var key: [Int] = [0, 1]
        }
        let data = try! FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! [Int]

        XCTAssertEqual(key, "key")
        XCTAssertEqual(value, [0, 1])
    }

    func testEncoderArrayDate() async throws {
        struct Object: Codable, Equatable {
            var key: [Date] = [Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 1)]
        }
        let data = try! FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! [Date]

        XCTAssertEqual(key, "key")
        XCTAssertEqual(value, [Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 1)])
    }

    func testEncoderArrayTimestamp() async throws {
        struct Object: Codable, Equatable {
            var key: [Timestamp] = [Timestamp(seconds: 0, nanos: 0), Timestamp(seconds: 0, nanos: 1)]
        }
        let data = try! FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! [Timestamp]

        XCTAssertEqual(key, "key")
        XCTAssertEqual(value, [Timestamp(seconds: 0, nanos: 0), Timestamp(seconds: 0, nanos: 1)])
    }

    func testEncoderArrayGeoPoint() async throws {
        struct Object: Codable, Equatable {
            var key: [GeoPoint] = [GeoPoint(latitude: 0, longitude: 0), GeoPoint(latitude: 0, longitude: 1)]
        }
        let data = try! FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! [GeoPoint]

        XCTAssertEqual(key, "key")
        XCTAssertEqual(value, [GeoPoint(latitude: 0, longitude: 0), GeoPoint(latitude: 0, longitude: 1)])
    }

    func testEncoderArrayDocumentReference() async throws {
        struct Object: Codable, Equatable {
            var key: [DocumentReference] = [
                DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "0"),
                DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "1")
            ]
        }
        let data = try! FirestoreEncoder().encode(Object())
        let key = data.keys.first!
        let value = data["key"] as! [DocumentReference]

        XCTAssertEqual(key, "key")
        XCTAssertEqual(value, [
            DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "0"),
            DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "1")
        ])
    }


    func testEncoderNest() async throws {

        struct DeepNestObject: Codable, Equatable {
            var number: Int = 0
            var string: String = "string"
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
            var bool: Bool = true
            var array: [String] = ["0", "1"]
            var map: [String: String] = ["key": "value"]
            var date: Date = Date(timeIntervalSince1970: 0)
            var nested: NestObject = NestObject()
            var timestamp: Timestamp = Timestamp(seconds: 0, nanos: 0)
            var geoPoint: GeoPoint = GeoPoint(latitude: 0, longitude: 0)
            var reference: DocumentReference = DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id")
        }

        let data = try! FirestoreEncoder().encode(Object())
        XCTAssertEqual(data["number"] as! Int, 0)
        XCTAssertEqual(data["string"] as! String, "string")
        XCTAssertEqual(data["bool"] as! Bool, true)
        XCTAssertEqual(data["array"] as! [String], ["0", "1"])
        XCTAssertEqual(data["map"] as! [String: String], ["key": "value"])
        XCTAssertEqual(data["date"] as! Date, Date(timeIntervalSince1970: 0))
        XCTAssertEqual(data["timestamp"] as! Timestamp, Timestamp(seconds: 0, nanos: 0))
        XCTAssertEqual(data["geoPoint"] as! GeoPoint, GeoPoint(latitude: 0, longitude: 0))
        XCTAssertEqual(data["reference"] as! DocumentReference, DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id"))
        let next = data["nested"] as! [String: Any]
        XCTAssertEqual(next["number"] as! Int, 0)
        XCTAssertEqual(next["string"] as! String, "string")
        XCTAssertEqual(next["bool"] as! Bool, true)
        XCTAssertEqual(next["array"] as! [String], ["0", "1"])
        XCTAssertEqual(next["map"] as! [String: String], ["key": "value"])
        XCTAssertEqual(next["date"] as! Date, Date(timeIntervalSince1970: 0))
        XCTAssertEqual(next["timestamp"] as! Timestamp, Timestamp(seconds: 0, nanos: 0))
        XCTAssertEqual(next["geoPoint"] as! GeoPoint, GeoPoint(latitude: 0, longitude: 0))
        XCTAssertEqual(next["reference"] as! DocumentReference, DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id"))
        let deep = next["nested"] as! [String: Any]
        XCTAssertEqual(deep["number"] as! Int, 0)
        XCTAssertEqual(deep["string"] as! String, "string")
        XCTAssertEqual(deep["bool"] as! Bool, true)
        XCTAssertEqual(deep["array"] as! [String], ["0", "1"])
        XCTAssertEqual(deep["map"] as! [String: String], ["key": "value"])
        XCTAssertEqual(deep["date"] as! Date, Date(timeIntervalSince1970: 0))
        XCTAssertEqual(deep["timestamp"] as! Timestamp, Timestamp(seconds: 0, nanos: 0))
        XCTAssertEqual(deep["geoPoint"] as! GeoPoint, GeoPoint(latitude: 0, longitude: 0))
        XCTAssertEqual(deep["reference"] as! DocumentReference, DocumentReference(Database(projectId: "project"), parentPath: "documents", documentID: "id"))
    }

}
