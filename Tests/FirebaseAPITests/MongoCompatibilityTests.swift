import FirestoreMongo
import Testing
@testable import FirestoreAPI

@Suite("Mongo Compatibility Tests")
struct MongoCompatibilityTests {
    @Test("Mongo GeoJSON point uses longitude latitude order")
    func testMongoGeoJSONPointUsesLongitudeLatitudeOrder() throws {
        let point = try FirestoreMongoGeoJSONPoint(longitude: -122.0840575, latitude: 37.4219999)

        #expect(point.document == [
            "type": .string("Point"),
            "coordinates": .array([
                .double(-122.0840575),
                .double(37.4219999)
            ])
        ])
    }

    @Test("Mongo near query builds GeoJSON query document")
    func testMongoNearQueryBuildsGeoJSONQueryDocument() throws {
        let point = try FirestoreMongoGeoJSONPoint(longitude: -122.0840575, latitude: 37.4219999)
        let query = try FirestoreMongoGeoNearQuery(
            fieldPath: "location",
            point: point,
            maxDistanceMeters: 1_000,
            minDistanceMeters: 10
        )

        #expect(query.document == [
            "location": .document([
                "$near": .document([
                    "$geometry": .document([
                        "type": .string("Point"),
                        "coordinates": .array([
                            .double(-122.0840575),
                            .double(37.4219999)
                        ])
                    ]),
                    "$maxDistance": .double(1_000),
                    "$minDistance": .double(10)
                ])
            ])
        ])
    }

    @Test("Mongo near query validates coordinates and distances")
    func testMongoNearQueryValidatesCoordinatesAndDistances() throws {
        do {
            _ = try FirestoreMongoGeoJSONPoint(longitude: 181, latitude: 0)
            Issue.record("Expected invalid longitude to throw")
        } catch FirestoreError.invalidFieldValue(let message) {
            #expect(message.contains("longitude"))
        }

        let point = try FirestoreMongoGeoJSONPoint(longitude: 0, latitude: 0)
        do {
            _ = try FirestoreMongoGeoNearQuery(
                fieldPath: "location",
                point: point,
                maxDistanceMeters: 10,
                minDistanceMeters: 20
            )
            Issue.record("Expected invalid distance ordering to throw")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("$minDistance"))
        }
    }

    @Test("Mongo geo index builds 2dsphere document")
    func testMongoGeoIndexBuilds2dsphereDocument() throws {
        let index = try FirestoreMongoGeoIndex(fieldPath: "location")

        #expect(index.document == [
            "location": .string("2dsphere")
        ])
    }
}
