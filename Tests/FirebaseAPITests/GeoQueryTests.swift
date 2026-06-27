import Foundation
import FirestoreRuntimeSupport
import Synchronization
import Testing
@testable import FirestoreAPI
@testable import FirestoreGeoQuery

@Suite("GeoQuery Tests")
struct GeoQueryTests {
    @Test("FirestoreGeoHash encodes GeoPoint values")
    func testFirestoreGeoHashEncodesGeoPointValues() throws {
        let point = GeoPoint(latitude: 37.4219999, longitude: -122.0840575)

        let publicHash = try FirestoreGeoHash.encode(point)
        let internalHash = GeoHash.encode(latitude: point.latitude, longitude: point.longitude, precision: 10)

        #expect(publicHash == internalHash)
    }

    @Test("FirestoreGeoHash rejects invalid field values")
    func testFirestoreGeoHashRejectsInvalidFieldValues() throws {
        do {
            _ = try FirestoreGeoHash.encode(latitude: 91, longitude: 0)
            Issue.record("Expected invalid latitude to throw")
        } catch FirestoreError.invalidFieldValue(let message) {
            #expect(message.contains("valid latitude and longitude"))
        }

        do {
            _ = try FirestoreGeoHash.encode(GeoPoint(latitude: 0, longitude: 0), precision: 0)
            Issue.record("Expected invalid precision to throw")
        } catch FirestoreError.invalidFieldValue(let message) {
            #expect(message.contains("precision"))
        }
    }

    @Test("GeoHash query bounds use ordered geohash ranges")
    func testGeoHashQueryBoundsUseOrderedGeohashRanges() throws {
        let center = GeoPoint(latitude: 37.4219999, longitude: -122.0840575)

        let bounds = try GeoHash.queryBounds(center: center, radiusInMeters: 1_000)

        #expect(!bounds.isEmpty)
        #expect(bounds.count <= 9)
        #expect(bounds.allSatisfy { !$0.start.isEmpty && !$0.end.isEmpty && $0.start <= $0.end })
    }

    @Test("GeoHash query bounds cover perimeter points within radius")
    func testGeoHashQueryBoundsCoverPerimeterPointsWithinRadius() throws {
        let cases = [
            (GeoPoint(latitude: 37.4219999, longitude: -122.0840575), 1.0),
            (GeoPoint(latitude: 37.4219999, longitude: -122.0840575), 100.0),
            (GeoPoint(latitude: 0, longitude: 0), 500.0),
            (GeoPoint(latitude: 65, longitude: 25), 5_000.0),
            (GeoPoint(latitude: 0, longitude: 179.9), 20_000.0)
        ]

        for (center, radius) in cases {
            let bounds = try GeoHash.queryBounds(center: center, radiusInMeters: radius)
            for bearing in stride(from: 0.0, to: 360.0, by: 10.0) {
                let point = destination(from: center, bearingDegrees: bearing, distanceInMeters: radius * 0.99)
                let hash = GeoHash.encode(latitude: point.latitude, longitude: point.longitude, precision: 10)
                #expect(
                    bounds.contains { $0.start <= hash && hash <= $0.end },
                    "Expected bounds to contain \(hash) for center \(center), radius \(radius), bearing \(bearing)"
                )
            }
        }
    }

    @Test("GeoHash query bounds cover a small-radius boundary regression")
    func testGeoHashQueryBoundsCoverSmallRadiusBoundaryRegression() throws {
        let center = GeoPoint(latitude: 37.4219999, longitude: -122.0840575)
        let point = GeoPoint(latitude: 37.422008501598, longitude: -122.084054394325)

        let bounds = try GeoHash.queryBounds(center: center, radiusInMeters: 1)
        let hash = GeoHash.encode(latitude: point.latitude, longitude: point.longitude, precision: 10)

        #expect(bounds.contains { $0.start <= hash && hash <= $0.end })
    }

    @Test("GeoQuery executes geohash ranges and filters by distance")
    func testGeoQueryExecutesGeohashRangesAndFiltersByDistance() async throws {
        let runtime = GeoQueryRuntime()
        let center = GeoPoint(latitude: 37.4219999, longitude: -122.0840575)
        let near = GeoPoint(latitude: 37.4222, longitude: -122.084)
        let far = GeoPoint(latitude: 37.8, longitude: -122.4)
        runtime.setDocuments([
            runtime.document(
                id: "center",
                fields: [
                    "hash": .string(GeoHash.encode(latitude: center.latitude, longitude: center.longitude, precision: 9)),
                    "geo": .map(["location": .geoPoint(center)])
                ]
            ),
            runtime.document(
                id: "near",
                fields: [
                    "hash": .string(GeoHash.encode(latitude: near.latitude, longitude: near.longitude, precision: 9)),
                    "geo": .map(["location": .geoPoint(near)])
                ]
            ),
            runtime.document(
                id: "far",
                fields: [
                    "hash": .string(GeoHash.encode(latitude: far.latitude, longitude: far.longitude, precision: 9)),
                    "geo": .map(["location": .geoPoint(far)])
                ]
            ),
            runtime.document(
                id: "missing-location",
                fields: ["hash": .string("9q9hv")]
            )
        ])
        let collection = CollectionReference(
            runtime.runtimeDatabase,
            parentPath: nil,
            collectionID: "places",
            runtime: runtime
        )

        let results = try await collection
            .geoQuery(
                center: center,
                radiusInMeters: 100,
                geohashField: "hash",
                locationField: "geo.location"
            )
            .getDocuments()

        let state = runtime.snapshot()
        #expect(results.map { $0.document.id } == ["center", "near"])
        #expect(results[0].distanceInMeters <= results[1].distanceInMeters)
        #expect(!state.queries.isEmpty)
        #expect(state.queries.count <= 9)
        #expect(state.queries.allSatisfy { $0.orderFields == ["hash"] })
        #expect(state.queries.allSatisfy { !$0.startValues.isEmpty && !$0.endValues.isEmpty })
    }

    @Test("GeoQuery rejects base queries with non-filter predicates")
    func testGeoQueryRejectsBaseQueriesWithNonFilterPredicates() async throws {
        let runtime = GeoQueryRuntime()
        let query = Query(
            runtime.runtimeDatabase,
            parentPath: nil,
            collectionID: "places",
            predicates: [.orderBy("score", false)],
            runtime: runtime
        )

        do {
            _ = try await query
                .geoQuery(
                    center: GeoPoint(latitude: 37.4219999, longitude: -122.0840575),
                    radiusInMeters: 100
                )
                .getDocuments()
            Issue.record("Expected invalid query error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("filters only"))
        }
    }

    @Test("GeoQuery rejects vector findNearest base queries")
    func testGeoQueryRejectsVectorFindNearestBaseQueries() async throws {
        let runtime = GeoQueryRuntime()
        let query = Query(
            runtime.runtimeDatabase,
            parentPath: nil,
            collectionID: "places",
            predicates: [],
            runtime: runtime
        )
        .findNearest(
            vectorField: "embedding",
            queryVector: FirestoreVector([1.0, 2.0]),
            limit: 5,
            distanceMeasure: .cosine
        )

        do {
            _ = try await query
                .geoQuery(
                    center: GeoPoint(latitude: 37.4219999, longitude: -122.0840575),
                    radiusInMeters: 100
                )
                .getDocuments()
            Issue.record("Expected invalid query error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("filters only"))
        }
    }
}

private struct RecordedGeoQuery: Sendable {
    let orderFields: [String]
    let startValues: [String]
    let endValues: [String]
}

private final class GeoQueryRuntime: FirestoreRuntime {
    struct State: Sendable {
        var documents: [QueryDocumentSnapshot] = []
        var queries: [RecordedGeoQuery] = []
    }

    let runtimeDatabase = Database(projectId: "test-project")
    private let state = Mutex(State())

    func setDocuments(_ documents: [QueryDocumentSnapshot]) {
        state.withLock { $0.documents = documents }
    }

    func snapshot() -> State {
        state.withLock { $0 }
    }

    func document(id: String, fields: [String: FirestoreDocumentValue]) -> QueryDocumentSnapshot {
        QueryDocumentSnapshot(
            fields: fields,
            documentReference: DocumentReference(
                runtimeDatabase,
                parentPath: "places",
                documentID: id,
                runtime: self
            )
        )
    }

    func getDocument(_ reference: DocumentReference) async throws -> DocumentSnapshot {
        DocumentSnapshot(documentReference: reference)
    }

    func setData(_ data: [String: Any], merge: Bool, for reference: DocumentReference) async throws {}

    func setData(_ data: [String: Any], mergeFields: [String], for reference: DocumentReference) async throws {}

    func updateData(_ fields: [String: Any], for reference: DocumentReference) async throws {}

    func deleteDocument(_ reference: DocumentReference) async throws {}

    func listCollections(in reference: DocumentReference) async throws -> [CollectionReference] {
        []
    }

    func listen(to reference: DocumentReference) async throws -> AsyncThrowingStream<DocumentSnapshot, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }

    func getDocuments(for query: Query) async throws -> QuerySnapshot {
        let record = RecordedGeoQuery(
            orderFields: query.predicates.compactMap { predicate in
                if case .orderBy(let field, _) = predicate {
                    return field
                }
                return nil
            },
            startValues: query.predicates.flatMap { predicate in
                if case .startAt(let values) = predicate {
                    return values.compactMap { $0 as? String }
                }
                return []
            },
            endValues: query.predicates.flatMap { predicate in
                if case .endAt(let values) = predicate {
                    return values.compactMap { $0 as? String }
                }
                return []
            }
        )

        let documents = state.withLock { state in
            state.queries.append(record)
            return state.documents
        }
        return QuerySnapshot(documents: documents.filter { record.matches($0) })
    }

    func listen(to query: Query) async throws -> AsyncThrowingStream<QuerySnapshot, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }

    func aggregate(_ query: Query, fields: [AggregateField]) async throws -> AggregateQuerySnapshot {
        AggregateQuerySnapshot(data: [:])
    }

    func explain(_ query: Query, options: FirestoreExplainOptions) async throws -> QueryExplainResult {
        QueryExplainResult(
            snapshot: nil,
            metrics: FirestoreExplainMetrics(
                planSummary: FirestoreExplainPlanSummary(indexesUsed: []),
                executionStats: nil
            )
        )
    }

    func explainAggregation(
        _ query: Query,
        fields: [AggregateField],
        options: FirestoreExplainOptions
    ) async throws -> AggregateQueryExplainResult {
        AggregateQueryExplainResult(
            snapshot: nil,
            metrics: FirestoreExplainMetrics(
                planSummary: FirestoreExplainPlanSummary(indexesUsed: []),
                executionStats: nil
            )
        )
    }

    func executePipeline(_ pipeline: FirestorePipeline) async throws -> PipelineQuerySnapshot {
        PipelineQuerySnapshot(rows: [], executionTime: nil)
    }

    func explainPipeline(_ pipeline: FirestorePipeline, options: PipelineExplainOptions) async throws -> PipelineExplainResult {
        PipelineExplainResult(
            snapshot: nil,
            stats: PipelineExplainStats(
                outputFormat: options.outputFormat,
                text: nil,
                json: nil,
                rawTypeURL: nil,
                rawData: nil
            )
        )
    }
}

private extension RecordedGeoQuery {
    func matches(_ document: QueryDocumentSnapshot) -> Bool {
        guard let geohashField = orderFields.first,
              let startValue = startValues.first,
              let endValue = endValues.first
        else {
            return true
        }

        guard let geohash = stringValue(in: document, fieldPath: geohashField) else {
            return false
        }

        return startValue <= geohash && geohash <= endValue
    }

    private func stringValue(in document: QueryDocumentSnapshot, fieldPath: String) -> String? {
        var currentValue: Any? = document.data()
        for component in fieldPath.split(separator: ".").map(String.init) {
            guard let map = currentValue as? [String: Any] else {
                return nil
            }
            currentValue = map[component]
        }
        return currentValue as? String
    }
}

private func destination(
    from center: GeoPoint,
    bearingDegrees: Double,
    distanceInMeters: Double
) -> GeoPoint {
    let earthRadiusInMeters = 6_371_008.8
    let angularDistance = distanceInMeters / earthRadiusInMeters
    let bearingRadians = bearingDegrees * .pi / 180
    let latitudeRadians = center.latitude * .pi / 180
    let longitudeRadians = center.longitude * .pi / 180
    let destinationLatitude = asin(
        sin(latitudeRadians) * cos(angularDistance)
            + cos(latitudeRadians) * sin(angularDistance) * cos(bearingRadians)
    )
    let destinationLongitude = longitudeRadians + atan2(
        sin(bearingRadians) * sin(angularDistance) * cos(latitudeRadians),
        cos(angularDistance) - sin(latitudeRadians) * sin(destinationLatitude)
    )

    return GeoPoint(
        latitude: destinationLatitude * 180 / .pi,
        longitude: normalizeLongitude(destinationLongitude * 180 / .pi)
    )
}

private func normalizeLongitude(_ value: Double) -> Double {
    var longitude = value
    while longitude < -180 {
        longitude += 360
    }
    while longitude > 180 {
        longitude -= 360
    }
    return longitude
}
