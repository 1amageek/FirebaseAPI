import FirestoreEmbedded
import Testing

@Suite("Firestore Embedded Tests")
struct FirestoreEmbeddedTests {
    @Test("Embedded database and document reference build resource paths")
    func testEmbeddedDatabaseAndDocumentReferenceBuildResourcePaths() throws {
        let database = try FirestoreEmbeddedDatabase(projectID: "/demo-project/", databaseID: "/main/")
        let reference = try FirestoreEmbeddedReference(database: database, documentPath: "/users/user-1/")

        #expect(database.resourcePath == "projects/demo-project/databases/main")
        #expect(reference.documentPath == "users/user-1")
        #expect(reference.documentID == "user-1")
        #expect(reference.resourcePath == "projects/demo-project/databases/main/documents/users/user-1")
    }

    @Test("Embedded paths reject invalid document and collection shapes")
    func testEmbeddedPathsRejectInvalidDocumentAndCollectionShapes() throws {
        let database = try FirestoreEmbeddedDatabase(projectID: "demo-project")

        #expect(throws: FirestoreEmbeddedError.self) {
            _ = try FirestoreEmbeddedReference(database: database, documentPath: "users")
        }

        #expect(throws: FirestoreEmbeddedError.self) {
            _ = try FirestoreEmbeddedQuery(database: database, collectionPath: "users/user-1")
        }
    }

    @Test("Embedded scalar values validate Firestore bounds")
    func testEmbeddedScalarValuesValidateFirestoreBounds() throws {
        _ = try FirestoreEmbeddedGeoPoint(latitude: 35.681236, longitude: 139.767125)
        _ = try FirestoreEmbeddedTimestamp(seconds: 1_700_000_000, nanoseconds: 999_999_999)

        #expect(throws: FirestoreEmbeddedError.self) {
            _ = try FirestoreEmbeddedGeoPoint(latitude: 91, longitude: 0)
        }

        #expect(throws: FirestoreEmbeddedError.self) {
            _ = try FirestoreEmbeddedTimestamp(seconds: 1, nanoseconds: 1_000_000_000)
        }
    }

    @Test("Embedded values can describe nested document data")
    func testEmbeddedValuesCanDescribeNestedDocumentData() throws {
        let database = try FirestoreEmbeddedDatabase(projectID: "demo-project")
        let reference = try FirestoreEmbeddedReference(database: database, documentPath: "users/user-1")
        let value = FirestoreEmbeddedValue.map([
            try FirestoreEmbeddedField("name", .string("Aki")),
            try FirestoreEmbeddedField("friend", .reference(reference)),
            try FirestoreEmbeddedField("scores", .array([.int(10), .int(20)]))
        ])
        let expected = FirestoreEmbeddedValue.map([
            try FirestoreEmbeddedField("name", .string("Aki")),
            try FirestoreEmbeddedField("friend", .reference(reference)),
            try FirestoreEmbeddedField("scores", .array([.int(10), .int(20)]))
        ])

        #expect(value == expected)
    }

    @Test("Embedded filters validate compound branches")
    func testEmbeddedFiltersValidateCompoundBranches() throws {
        let active = try FirestoreEmbeddedFilter.field("active", .equal, .bool(true))
        let score = try FirestoreEmbeddedFilter.field("score", .greaterThanOrEqual, .int(10))
        let combined = try FirestoreEmbeddedFilter.all([active, score])

        #expect(combined == .and([active, score]))

        #expect(throws: FirestoreEmbeddedError.self) {
            _ = try FirestoreEmbeddedFilter.any([])
        }
    }

    @Test("Embedded query descriptors compose filters order and limits")
    func testEmbeddedQueryDescriptorsComposeFiltersOrderAndLimits() throws {
        let database = try FirestoreEmbeddedDatabase(projectID: "demo-project")
        let active = try FirestoreEmbeddedFilter.field("active", .equal, .bool(true))
        let score = try FirestoreEmbeddedFilter.field("score", .greaterThan, .int(10))
        let query = try FirestoreEmbeddedQuery(database: database, collectionPath: "/teams/team-1/users/")
            .where(active)
            .where(score)
            .order(by: "score", descending: true)
            .limit(to: 25)

        #expect(query.parentResourcePath == "projects/demo-project/databases/(default)/documents/teams/team-1")
        #expect(query.collectionID == "users")
        #expect(query.filter == .and([active, score]))
        #expect(query.orderBy == [try FirestoreEmbeddedOrder(fieldPath: "score", descending: true)])
        #expect(query.limit == 25)
    }
}
