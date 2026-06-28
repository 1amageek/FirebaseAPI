import Foundation
import FirestoreAdmin
import Testing

@Suite("Firestore Live Integration Tests")
struct FirestoreLiveIntegrationTests {
    @Test("Live Firestore performs Admin CRUD, query, and count", .timeLimit(.minutes(2)))
    func testLiveFirestoreCRUDQueryAndCount() async throws {
        guard let configuration = Self.configuration() else {
            return
        }

        let firestore = try await Firestore.applicationDefaultResolvingProjectID(
            projectId: configuration.projectID,
            databaseId: configuration.databaseID,
            settings: FirestoreSettings(
                timeout: .seconds(30),
                maxRetryAttempts: 3,
                retryStrategy: .exponentialBackoff(
                    initial: .milliseconds(200),
                    maximum: .seconds(2),
                    multiplier: 1.5,
                    jitter: 0.1
                ),
                logLevel: .warning
            )
        )

        let testID = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let collection = try firestore.collection("firebase_api_live_smoke_\(testID)")
        let document = try collection.document("primary")

        do {
            try await document.setData([
                "active": true,
                "name": "Live Smoke",
                "score": 1
            ])

            let createdSnapshot = try await document.getDocument()
            let createdData = try #require(createdSnapshot.data())
            #expect(createdSnapshot.exists)
            #expect(createdData["name"] as? String == "Live Smoke")
            #expect(createdData["score"] as? Int == 1)

            try await document.updateData(["score": 2])

            let querySnapshot = try await collection
                .whereField("active", isEqualTo: true)
                .order(by: "score", descending: false)
                .limit(to: 1)
                .getDocuments()
            #expect(querySnapshot.documents.map(\.documentReference.documentID) == ["primary"])
            #expect(querySnapshot.documents.first?.data()["score"] as? Int == 2)

            let count = try await collection.count()
            #expect(count == 1)

            try await document.delete()
            let deletedSnapshot = try await document.getDocument()
            #expect(!deletedSnapshot.exists)
            await firestore.shutdown()
        } catch {
            await Self.deleteIgnoringErrors([document])
            await firestore.shutdown()
            throw error
        }
    }

    private static func configuration(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> FirestoreLiveConfiguration? {
        guard environment["FIRESTORE_LIVE_SMOKE"] == "1" else {
            return nil
        }

        return FirestoreLiveConfiguration(
            projectID: environment["FIRESTORE_LIVE_PROJECT_ID"],
            databaseID: environment["FIRESTORE_LIVE_DATABASE_ID"] ?? "(default)"
        )
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
}

private struct FirestoreLiveConfiguration: Sendable {
    let projectID: String?
    let databaseID: String
}
