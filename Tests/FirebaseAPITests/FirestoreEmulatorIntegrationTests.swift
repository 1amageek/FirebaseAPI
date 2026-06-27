import Foundation
import Testing
@testable import FirestoreAPI
@testable import FirestoreGeoQuery

@Suite("Firestore Emulator Integration Tests")
struct FirestoreEmulatorIntegrationTests {
    @Test("Firestore emulator performs CRUD, query, count, and listen", .timeLimit(.minutes(1)))
    func testFirestoreEmulatorCRUDQueryCountAndListen() async throws {
        guard let configuration = try Self.configuration() else {
            return
        }

        let firestore = try FirestoreAdmin.emulator(
            projectId: configuration.projectID,
            databaseId: configuration.databaseID,
            host: configuration.host,
            port: configuration.port,
            logLevel: .warning
        )

        let testID = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let collection = try firestore.collection("firebase_api_integration_\(testID)")
        let primaryDocument = try collection.document("primary")
        let listenerDocument = try collection.document("listener")

        do {
            try await primaryDocument.setData([
                "active": true,
                "name": "Ada",
                "score": 1
            ])

            let initialSnapshot = try await primaryDocument.getDocument()
            let initialData = try #require(initialSnapshot.data())
            #expect(initialSnapshot.exists)
            #expect(initialData["name"] as? String == "Ada")
            #expect(initialData["score"] as? Int == 1)

            try await primaryDocument.updateData(["score": 2])
            let updatedSnapshot = try await primaryDocument.getDocument()
            let updatedData = try #require(updatedSnapshot.data())
            #expect(updatedData["score"] as? Int == 2)

            let querySnapshot = try await collection
                .whereField("active", isEqualTo: true)
                .order(by: "score", descending: false)
                .limit(to: 5)
                .getDocuments()
            #expect(querySnapshot.documents.map(\.documentReference.documentID) == ["primary"])

            let count = try await collection.count()
            #expect(count == 1)

            let stream = try await collection
                .whereField("active", isEqualTo: true)
                .addSnapshotListener()
            try await listenerDocument.setData([
                "active": true,
                "name": "Grace",
                "score": 3
            ])
            let listenedSnapshot = try await Self.firstSnapshot(
                containingDocumentID: "listener",
                in: stream
            )
            #expect(listenedSnapshot.documents.contains { $0.documentReference.documentID == "listener" })

            try await primaryDocument.delete()
            try await listenerDocument.delete()
            await firestore.shutdown()
        } catch {
            await Self.deleteIgnoringErrors([primaryDocument, listenerDocument])
            await firestore.shutdown()
            throw error
        }
    }

    @Test("Firestore emulator restores limitToLast document cursor result order", .timeLimit(.minutes(1)))
    func testFirestoreEmulatorLimitToLastDocumentCursorRestoresResultOrder() async throws {
        guard let configuration = try Self.configuration() else {
            return
        }

        let firestore = try FirestoreAdmin.emulator(
            projectId: configuration.projectID,
            databaseId: configuration.databaseID,
            host: configuration.host,
            port: configuration.port,
            logLevel: .warning
        )

        let testID = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let collection = try firestore.collection("firebase_api_cursor_\(testID)")
        let score10Document = try collection.document("score10")
        let score20Document = try collection.document("score20")
        let score30Document = try collection.document("score30")
        let score40Document = try collection.document("score40")
        let documents = [
            score10Document,
            score20Document,
            score30Document,
            score40Document
        ]

        do {
            try await score10Document.setData(["score": 10])
            try await score20Document.setData(["score": 20])
            try await score30Document.setData(["score": 30])
            try await score40Document.setData(["score": 40])

            let lowerBound = try await score10Document.getDocument()
            let upperBound = try await score40Document.getDocument()
            let snapshot = try await collection
                .order(by: "score", descending: false)
                .start(afterDocument: lowerBound)
                .end(atDocument: upperBound)
                .limit(toLast: 2)
                .getDocuments()

            #expect(snapshot.documents.map { $0.documentReference.documentID } == ["score30", "score40"])
            #expect(snapshot.documents.map { $0.data()["score"] as? Int } == [30, 40])

            await Self.deleteIgnoringErrors(documents)
            await firestore.shutdown()
        } catch {
            await Self.deleteIgnoringErrors(documents)
            await firestore.shutdown()
            throw error
        }
    }

    @Test("Firestore emulator listen survives dropped TCP connection", .timeLimit(.minutes(1)))
    func testFirestoreEmulatorListenReconnectsAfterTCPDrop() async throws {
        guard let configuration = try Self.configuration() else {
            return
        }

        let proxy = FirestoreTCPProxy(
            targetHost: configuration.host,
            targetPort: configuration.port
        )
        let proxyPort = try await proxy.start()

        let listenerFirestore = try FirestoreAdmin.emulator(
            projectId: configuration.projectID,
            databaseId: configuration.databaseID,
            host: "127.0.0.1",
            port: proxyPort,
            maxRetryAttempts: 6,
            retryStrategy: .linearBackoff(interval: .milliseconds(50), maximum: .milliseconds(50)),
            logLevel: .warning
        )
        let writerFirestore = try FirestoreAdmin.emulator(
            projectId: configuration.projectID,
            databaseId: configuration.databaseID,
            host: configuration.host,
            port: configuration.port,
            logLevel: .warning
        )

        let testID = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let collectionPath = "firebase_api_reconnect_\(testID)"
        let listenerCollection = try listenerFirestore.collection(collectionPath)
        let writerCollection = try writerFirestore.collection(collectionPath)
        let primaryDocument = try writerCollection.document("primary")
        let reconnectedDocument = try writerCollection.document("after_drop")

        do {
            try await primaryDocument.setData([
                "active": true,
                "score": 1
            ])

            let stream = try await listenerCollection
                .whereField("active", isEqualTo: true)
                .order(by: "score", descending: false)
                .addSnapshotListener()
            var iterator = stream.makeAsyncIterator()

            let initialSnapshot = try await Self.nextSnapshot(
                containingDocumentID: "primary",
                from: &iterator
            )
            #expect(initialSnapshot.documents.map { $0.documentReference.documentID } == ["primary"])

            await proxy.dropActiveConnections()
            try await Task.sleep(for: .milliseconds(100))

            try await reconnectedDocument.setData([
                "active": true,
                "score": 2
            ])

            let reconnectedSnapshot = try await Self.nextSnapshot(
                containingDocumentID: "after_drop",
                from: &iterator
            )
            #expect(reconnectedSnapshot.documents.map { $0.documentReference.documentID } == ["primary", "after_drop"])

            try await primaryDocument.delete()
            try await reconnectedDocument.delete()
            await listenerFirestore.shutdown()
            await writerFirestore.shutdown()
            await proxy.stop()
        } catch {
            await Self.deleteIgnoringErrors([primaryDocument, reconnectedDocument])
            await listenerFirestore.shutdown()
            await writerFirestore.shutdown()
            await proxy.stop()
            throw error
        }
    }

    @Test("Firestore emulator performs native GeoQuery", .timeLimit(.minutes(1)))
    func testFirestoreEmulatorGeoQuery() async throws {
        guard let configuration = try Self.configuration() else {
            return
        }

        let firestore = try FirestoreAdmin.emulator(
            projectId: configuration.projectID,
            databaseId: configuration.databaseID,
            host: configuration.host,
            port: configuration.port,
            logLevel: .warning
        )

        let testID = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let collection = try firestore.collection("firebase_api_geo_\(testID)")
        let center = GeoPoint(latitude: 37.4219999, longitude: -122.0840575)
        let near = GeoPoint(latitude: 37.4222, longitude: -122.084)
        let far = GeoPoint(latitude: 37.8, longitude: -122.4)
        let centerDocument = try collection.document("center")
        let nearDocument = try collection.document("near")
        let farDocument = try collection.document("far")

        do {
            try await centerDocument.setData([
                "geohash": GeoHash.encode(latitude: center.latitude, longitude: center.longitude, precision: 9),
                "location": center
            ])
            try await nearDocument.setData([
                "geohash": GeoHash.encode(latitude: near.latitude, longitude: near.longitude, precision: 9),
                "location": near
            ])
            try await farDocument.setData([
                "geohash": GeoHash.encode(latitude: far.latitude, longitude: far.longitude, precision: 9),
                "location": far
            ])

            let results = try await collection
                .geoQuery(center: center, radiusInMeters: 100)
                .getDocuments()

            #expect(results.map { $0.document.documentReference.documentID } == ["center", "near"])
            #expect(results[0].distanceInMeters <= results[1].distanceInMeters)

            try await centerDocument.delete()
            try await nearDocument.delete()
            try await farDocument.delete()
            await firestore.shutdown()
        } catch {
            await Self.deleteIgnoringErrors([centerDocument, nearDocument, farDocument])
            await firestore.shutdown()
            throw error
        }
    }

    @Test("Firestore emulator performs Pipeline aggregations and lambda expressions", .timeLimit(.minutes(1)))
    func testFirestoreEmulatorPipelineAggregationsAndLambdaExpressions() async throws {
        guard Self.pipelineSmokeEnabled(),
              let configuration = try Self.configuration()
        else {
            return
        }

        let firestore = try FirestoreAdmin.emulator(
            projectId: configuration.projectID,
            databaseId: configuration.databaseID,
            host: configuration.host,
            port: configuration.port,
            logLevel: .warning
        )

        let testID = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let collection = try firestore.collection("firebase_api_pipeline_\(testID)")
        let primaryDocument = try collection.document("primary")

        do {
            try await primaryDocument.setData([
                "authorId": "ada",
                "published": true,
                "rating": 5,
                "scores": [1, 2, 3]
            ])

            let projectionSnapshot = try await firestore.execute(
                firestore.pipeline()
                    .collection(collection.path)
                    .select([
                        PipelineValue.field("scores")
                            .arrayFilter(parameter: "score") { score in
                                score.greaterThan(1)
                            }
                            .as("passingScores"),
                        PipelineValue.field("scores")
                            .arrayTransform(parameter: "score") { score in
                                score.multiply(2)
                            }
                            .as("doubledScores"),
                        PipelineValue.switchOn(
                            [
                                PipelineSwitchCase(
                                    PipelineValue.field("rating").greaterThan(4),
                                    then: .string("high")
                                )
                            ],
                            default: .string("standard")
                        )
                        .as("ratingBand"),
                        PipelineValue.field("rating").exists().as("hasRating"),
                        PipelineValue.concat([.string("Author ID: "), .field("authorId")])
                            .as("authorLabel")
                    ])
            )

            let projectionRow = try #require(projectionSnapshot.rows.first)
            #expect(projectionSnapshot.rows.count == 1)
            #expect(Self.integerArray(projectionRow["passingScores"]) == [2, 3])
            #expect(Self.integerArray(projectionRow["doubledScores"]) == [2, 4, 6])
            #expect(projectionRow["ratingBand"] as? String == "high")
            #expect(projectionRow["hasRating"] as? Bool == true)
            #expect(projectionRow["authorLabel"] as? String == "Author ID: ada")

            let aggregateSnapshot = try await firestore.execute(
                firestore.pipeline()
                    .collection(collection.path)
                    .aggregate([
                        PipelineValue.countAll().as("totalCount"),
                        PipelineValue.field("rating").sum().as("totalRating"),
                        PipelineValue.field("rating").average().as("averageRating")
                    ])
            )
            let aggregateRow = try #require(aggregateSnapshot.rows.first)
            #expect(aggregateSnapshot.rows.count == 1)
            #expect(aggregateRow["totalCount"] as? Int == 1)
            #expect(aggregateRow["totalRating"] as? Int == 5)
            #expect(aggregateRow["averageRating"] as? Double == 5)

            try await primaryDocument.delete()
            await firestore.shutdown()
        } catch {
            await Self.deleteIgnoringErrors([primaryDocument])
            await firestore.shutdown()
            throw error
        }
    }

    @Test("Firestore emulator performs Pipeline DML and subqueries", .timeLimit(.minutes(1)))
    func testFirestoreEmulatorPipelineDMLAndSubqueries() async throws {
        guard Self.pipelineSmokeEnabled(),
              let configuration = try Self.configuration()
        else {
            return
        }

        let firestore = try FirestoreAdmin.emulator(
            projectId: configuration.projectID,
            databaseId: configuration.databaseID,
            host: configuration.host,
            port: configuration.port,
            logLevel: .warning
        )

        let testID = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let books = try firestore.collection("firebase_api_pipeline_books_\(testID)")
        let authors = try firestore.collection("firebase_api_pipeline_authors_\(testID)")
        let reviews = try firestore.collection("firebase_api_pipeline_reviews_\(testID)")
        let draftBook = try books.document("draft")
        let archivedBook = try books.document("archived")
        let author = try authors.document("ada")
        let reviewA = try reviews.document("reviewA")
        let reviewB = try reviews.document("reviewB")
        let reviewC = try reviews.document("reviewC")
        let documents = [
            draftBook,
            archivedBook,
            author,
            reviewA,
            reviewB,
            reviewC
        ]

        do {
            try await draftBook.setData([
                "score": 1,
                "status": "draft"
            ])
            try await archivedBook.setData([
                "score": 0,
                "status": "archived"
            ])

            _ = try await firestore.execute(
                firestore.pipeline()
                    .collection(books.path)
                    .where(PipelineValue.field("status").equal("draft"))
                    .update([
                        PipelineValue.string("published").as("status"),
                        PipelineValue.field("score").add(1).as("score")
                    ])
            )
            _ = try await firestore.execute(
                firestore.pipeline()
                    .collection(books.path)
                    .where(PipelineValue.field("status").equal("archived"))
                    .delete()
            )

            let updatedBook = try await draftBook.getDocument()
            let updatedData = try #require(updatedBook.data())
            #expect(updatedData["status"] as? String == "published")
            #expect(updatedData["score"] as? Int == 2)

            let deletedBook = try await archivedBook.getDocument()
            #expect(!deletedBook.exists)

            try await author.setData([
                "authorId": "ada",
                "name": "Ada"
            ])
            try await reviewA.setData([
                "authorId": "ada",
                "rating": 5
            ])
            try await reviewB.setData([
                "authorId": "ada",
                "rating": 3
            ])
            try await reviewC.setData([
                "authorId": "grace",
                "rating": 4
            ])

            let authorReviews = FirestorePipeline()
                .collection(reviews.path)
                .where(PipelineValue.field("authorId").equal(.variable("author_id")))
                .sort([PipelineValue.field("rating").descending()])
                .select([
                    PipelineValue.field("rating").as("rating")
                ])
            let joinedSnapshot = try await firestore.execute(
                firestore.pipeline()
                    .collection(authors.path)
                    .where(PipelineValue.field("authorId").equal("ada"))
                    .define([
                        PipelineValue.field("authorId").as("author_id")
                    ])
                    .select([
                        PipelineValue.field("authorId").as("authorId"),
                        authorReviews.toArrayExpression().as("reviews")
                    ])
            )

            let joinedRow = try #require(joinedSnapshot.rows.first)
            #expect(joinedSnapshot.rows.count == 1)
            #expect(joinedRow["authorId"] as? String == "ada")
            let joinedReviews = try #require(joinedRow["reviews"] as? [[String: Any]])
            let ratings = joinedReviews.compactMap { $0["rating"] as? Int }
            #expect(ratings == [5, 3])

            await Self.deleteIgnoringErrors(documents)
            await firestore.shutdown()
        } catch {
            await Self.deleteIgnoringErrors(documents)
            await firestore.shutdown()
            throw error
        }
    }

    private static func firstSnapshot(
        containingDocumentID documentID: String,
        in stream: AsyncThrowingStream<QuerySnapshot, Error>
    ) async throws -> QuerySnapshot {
        var iterator = stream.makeAsyncIterator()
        return try await nextSnapshot(containingDocumentID: documentID, from: &iterator)
    }

    private static func nextSnapshot(
        containingDocumentID documentID: String,
        from iterator: inout AsyncThrowingStream<QuerySnapshot, Error>.Iterator
    ) async throws -> QuerySnapshot {
        while let snapshot = try await iterator.next() {
            if snapshot.documents.contains(where: { $0.documentReference.documentID == documentID }) {
                return snapshot
            }
        }
        throw FirestoreError.noResult
    }

    private static func deleteIgnoringErrors(_ documents: [DocumentReference]) async {
        for document in documents {
            do {
                try await document.delete()
            } catch {
                continue
            }
        }
    }

    private static func pipelineSmokeEnabled(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> Bool {
        environment["FIRESTORE_EMULATOR_PIPELINE_SMOKE"] == "1"
    }

    private static func integerArray(_ value: Any?) -> [Int]? {
        if let values = value as? [Int] {
            return values
        }
        guard let values = value as? [Any] else {
            return nil
        }
        var integers: [Int] = []
        for value in values {
            guard let integer = value as? Int else {
                return nil
            }
            integers.append(integer)
        }
        return integers
    }

    private static func configuration(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> FirestoreEmulatorConfiguration? {
        guard let hostPort = environment["FIRESTORE_EMULATOR_HOST"], !hostPort.isEmpty else {
            return nil
        }

        let endpoint = try parseHostPort(hostPort)
        let projectID = environment["FIRESTORE_EMULATOR_PROJECT_ID"] ?? "firebase-api-emulator-test"
        let databaseID = environment["FIRESTORE_EMULATOR_DATABASE_ID"] ?? "(default)"
        return FirestoreEmulatorConfiguration(
            projectID: projectID,
            databaseID: databaseID,
            host: endpoint.host,
            port: endpoint.port
        )
    }

    private static func parseHostPort(_ value: String) throws -> (host: String, port: Int) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = trimmed.split(separator: ":", omittingEmptySubsequences: false)
        guard let portComponent = components.last,
              let port = Int(portComponent),
              port > 0
        else {
            throw FirestoreError.invalidConfiguration("FIRESTORE_EMULATOR_HOST must include a valid port.")
        }

        let rawHost = components.dropLast().joined(separator: ":")
        let host: String
        if rawHost.hasPrefix("[") && rawHost.hasSuffix("]") {
            host = String(rawHost.dropFirst().dropLast())
        } else {
            host = rawHost
        }

        guard !host.isEmpty else {
            throw FirestoreError.invalidConfiguration("FIRESTORE_EMULATOR_HOST must include a host.")
        }
        return (host, port)
    }
}

private struct FirestoreEmulatorConfiguration: Sendable {
    let projectID: String
    let databaseID: String
    let host: String
    let port: Int
}
