import Foundation
import FirestorePipeline
import FirestorePipelineRPC
import FirestoreProtobuf
import FirestoreRPC
import FirestoreRPCSupport
import FirestoreRuntimeSupport
import SwiftProtobuf
import Testing
@testable import FirestoreAPI

@Suite("RPC Compiler Tests")
struct RPCCompilerTests {
    @Test("QueryCompiler preserves nested query parent")
    func testQueryCompilerPreservesNestedQueryParent() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: "organizations/org123",
            collectionID: "users",
            predicates: [.isEqualToDocumentID("user123")]
        )

        let request = try QueryCompiler(query: query).makeRunQueryRequest()

        #expect(request.parent == "projects/test-project/databases/(default)/documents/organizations/org123")
        #expect(request.structuredQuery.from.first?.collectionID == "users")
        #expect(request.structuredQuery.where.fieldFilter.value.referenceValue == "projects/test-project/databases/(default)/documents/organizations/org123/users/user123")
    }

    @Test("QueryCompiler combines multiple filters with AND")
    func testQueryCompilerCombinesMultipleFiltersWithAnd() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: [
                .isGreaterThanOrEqualTo("age", 18),
                .isEqualTo("active", true)
            ]
        )

        let request = try QueryCompiler(query: query).makeRunQueryRequest()
        let compositeFilter = request.structuredQuery.where.compositeFilter

        #expect(compositeFilter.op == .and)
        #expect(compositeFilter.filters.count == 2)
        #expect(compositeFilter.filters[0].fieldFilter.field.fieldPath == "age")
        #expect(compositeFilter.filters[0].fieldFilter.op == .greaterThanOrEqual)
        #expect(compositeFilter.filters[1].fieldFilter.field.fieldPath == "active")
        #expect(compositeFilter.filters[1].fieldFilter.op == .equal)
    }

    @Test("QueryCompiler encodes membership filters with array comparison values")
    func testQueryCompilerEncodesMembershipFiltersWithArrayComparisonValues() throws {
        let database = Database(projectId: "test-project")
        let comparisonValues: [Any] = [["west_coast"], ["east_coast"]]
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "cities",
            predicates: []
        )
        .whereField("regions", in: comparisonValues)

        let filter = try QueryCompiler(query: query).makeRunQueryRequest().structuredQuery.where.fieldFilter
        let values = filter.value.arrayValue.values

        #expect(filter.field.fieldPath == "regions")
        #expect(filter.op == .in)
        #expect(values.count == 2)
        #expect(values[0].arrayValue.values.map(\.stringValue) == ["west_coast"])
        #expect(values[1].arrayValue.values.map(\.stringValue) == ["east_coast"])
    }

    @Test("QueryCompiler rejects nested arrays inside membership comparison arrays")
    func testQueryCompilerRejectsNestedArraysInsideMembershipComparisonArrays() throws {
        let database = Database(projectId: "test-project")
        let comparisonValues: [Any] = [[["west_coast"]]]
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "cities",
            predicates: []
        )
        .whereField("regions", in: comparisonValues)

        do {
            _ = try QueryCompiler(query: query).makeRunQueryRequest()
            Issue.record("Expected invalid field value error")
        } catch FirestoreError.invalidFieldValue(let message) {
            #expect(message.contains("Arrays cannot directly contain arrays"))
        }
    }

    @Test("Query chaining preserves sort limit and cursor predicates")
    func testQueryChainingPreservesSortLimitAndCursorPredicates() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: []
        )
        .order(by: "score")
        .start(at: [10])
        .limit(to: 3)
        .whereField("active", isEqualTo: true)
        .whereField("tier", isEqualTo: "paid")

        let request = try QueryCompiler(query: query).makeRunQueryRequest()
        let structuredQuery = request.structuredQuery
        let compositeFilter = structuredQuery.where.compositeFilter

        #expect(compositeFilter.op == .and)
        #expect(compositeFilter.filters.count == 2)
        #expect(compositeFilter.filters[0].fieldFilter.field.fieldPath == "active")
        #expect(compositeFilter.filters[1].fieldFilter.field.fieldPath == "tier")
        #expect(structuredQuery.orderBy.map { $0.field.fieldPath } == ["score"])
        #expect(structuredQuery.startAt.values.map(\.integerValue) == [10])
        #expect(structuredQuery.limit.value == 3)
    }

    @Test("Collection and collection group sources expose cursor predicates")
    func testCollectionAndCollectionGroupSourcesExposeCursorPredicates() throws {
        let database = Database(projectId: "test-project")
        let collectionQuery = CollectionReference(
            database,
            parentPath: nil,
            collectionID: "users"
        )
        .start(at: [10])
        .end(before: [20])
        .order(by: "score")

        let collectionGroupQuery = CollectionGroup(
            database,
            groupID: "reviews"
        )
        .start(after: ["a"])
        .end(at: ["z"])
        .order(by: "author")

        let collectionRequest = try QueryCompiler(query: collectionQuery).makeRunQueryRequest()
        let collectionGroupRequest = try QueryCompiler(query: collectionGroupQuery).makeRunQueryRequest()

        #expect(collectionRequest.structuredQuery.from.first?.collectionID == "users")
        #expect(collectionRequest.structuredQuery.from.first?.allDescendants == false)
        #expect(collectionRequest.structuredQuery.orderBy.map(\.field.fieldPath) == ["score"])
        #expect(collectionRequest.structuredQuery.startAt.values.map(\.integerValue) == [10])
        #expect(collectionRequest.structuredQuery.startAt.before)
        #expect(collectionRequest.structuredQuery.endAt.values.map(\.integerValue) == [20])
        #expect(collectionRequest.structuredQuery.endAt.before)

        #expect(collectionGroupRequest.structuredQuery.from.first?.collectionID == "reviews")
        #expect(collectionGroupRequest.structuredQuery.from.first?.allDescendants == true)
        #expect(collectionGroupRequest.structuredQuery.orderBy.map(\.field.fieldPath) == ["author"])
        #expect(collectionGroupRequest.structuredQuery.startAt.values.map(\.stringValue) == ["a"])
        #expect(!collectionGroupRequest.structuredQuery.startAt.before)
        #expect(collectionGroupRequest.structuredQuery.endAt.values.map(\.stringValue) == ["z"])
        #expect(!collectionGroupRequest.structuredQuery.endAt.before)
    }

    @Test("Document ID field value cursors compile to reference values")
    func testDocumentIDFieldValueCursorsCompileToReferenceValues() throws {
        let database = Database(projectId: "test-project")
        let collectionQuery = try CollectionReference(
            database,
            parentPath: "organizations/org123",
            collectionID: "users"
        )
        .order(by: FieldPath.documentID())
        .start(at: ["user123"])
        let collectionGroupQuery = try CollectionGroup(
            database,
            groupID: "reviews"
        )
        .order(by: FieldPath.documentID())
        .start(after: ["users/user123/reviews/review123"])

        let collectionRequest = try QueryCompiler(query: collectionQuery).makeRunQueryRequest()
        let collectionGroupRequest = try QueryCompiler(query: collectionGroupQuery).makeRunQueryRequest()

        #expect(collectionRequest.structuredQuery.orderBy.map(\.field.fieldPath) == ["__name__"])
        #expect(collectionRequest.structuredQuery.startAt.values.map(\.referenceValue) == [
            "projects/test-project/databases/(default)/documents/organizations/org123/users/user123"
        ])
        #expect(collectionRequest.structuredQuery.startAt.before)

        #expect(collectionGroupRequest.structuredQuery.from.first?.allDescendants == true)
        #expect(collectionGroupRequest.structuredQuery.orderBy.map(\.field.fieldPath) == ["__name__"])
        #expect(collectionGroupRequest.structuredQuery.startAt.values.map(\.referenceValue) == [
            "projects/test-project/databases/(default)/documents/users/user123/reviews/review123"
        ])
        #expect(!collectionGroupRequest.structuredQuery.startAt.before)
    }

    @Test("Document ID field value cursors validate collection path shape")
    func testDocumentIDFieldValueCursorsValidateCollectionPathShape() throws {
        let database = Database(projectId: "test-project")
        let collectionQuery = try CollectionReference(
            database,
            parentPath: nil,
            collectionID: "users"
        )
        .order(by: FieldPath.documentID())
        .start(at: ["users/user123"])
        let collectionGroupQuery = try CollectionGroup(
            database,
            groupID: "reviews"
        )
        .order(by: FieldPath.documentID())
        .start(at: ["review123"])
        let emptyDocumentIDQuery = try CollectionReference(
            database,
            parentPath: nil,
            collectionID: "users"
        )
        .order(by: FieldPath.documentID())
        .start(at: [""])

        var collectionDidThrow = false
        do {
            _ = try QueryCompiler(query: collectionQuery).makeRunQueryRequest()
        } catch FirestoreError.invalidQuery(let message) {
            collectionDidThrow = message.contains("plain document ID")
        } catch {
            collectionDidThrow = false
        }

        var collectionGroupDidThrow = false
        do {
            _ = try QueryCompiler(query: collectionGroupQuery).makeRunQueryRequest()
        } catch FirestoreError.invalidQuery(let message) {
            collectionGroupDidThrow = message.contains("valid document path")
        } catch {
            collectionGroupDidThrow = false
        }

        var emptyDocumentIDDidThrow = false
        do {
            _ = try QueryCompiler(query: emptyDocumentIDQuery).makeRunQueryRequest()
        } catch FirestoreError.invalidQuery(let message) {
            emptyDocumentIDDidThrow = message.contains("must not be empty")
        } catch {
            emptyDocumentIDDidThrow = false
        }

        #expect(collectionDidThrow)
        #expect(collectionGroupDidThrow)
        #expect(emptyDocumentIDDidThrow)
    }

    @Test("Document snapshot cursors compile ordered field and document ID values")
    func testDocumentSnapshotCursorsCompileOrderedFieldAndDocumentIDValues() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let querySnapshot = QueryDocumentSnapshot(
            fields: [
                "score": .integer(42),
                "profile": .map(["rank": .integer(7)])
            ],
            documentReference: reference
        )
        let documentSnapshot = DocumentSnapshot(
            fields: [
                "score": .integer(42),
                "profile": .map(["rank": .integer(7)])
            ],
            documentReference: reference
        )

        let query = try Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: []
        )
        .order(by: "score")
        .order(by: "profile.rank")
        .order(by: FieldPath.documentID())
        .start(atDocument: querySnapshot)
        .end(beforeDocument: documentSnapshot)

        let request = try QueryCompiler(query: query).makeRunQueryRequest()
        let startValues = request.structuredQuery.startAt.values
        let endValues = request.structuredQuery.endAt.values

        #expect(request.structuredQuery.orderBy.map(\.field.fieldPath) == ["score", "profile.rank", "__name__"])
        #expect(startValues.count == 3)
        #expect(startValues[0].integerValue == 42)
        #expect(startValues[1].integerValue == 7)
        #expect(startValues[2].referenceValue == "projects/test-project/databases/(default)/documents/users/user123")
        #expect(request.structuredQuery.startAt.before)
        #expect(endValues.count == 3)
        #expect(endValues[0].integerValue == 42)
        #expect(endValues[1].integerValue == 7)
        #expect(endValues[2].referenceValue == "projects/test-project/databases/(default)/documents/users/user123")
        #expect(request.structuredQuery.endAt.before)
    }

    @Test("Document snapshot cursors with limitToLast swap normalized bounds")
    func testDocumentSnapshotCursorsWithLimitToLastSwapNormalizedBounds() throws {
        let database = Database(projectId: "test-project")
        let startReference = DocumentReference(database, parentPath: "users", documentID: "userA")
        let endReference = DocumentReference(database, parentPath: "users", documentID: "userZ")
        let startSnapshot = QueryDocumentSnapshot(
            fields: ["score": .integer(10)],
            documentReference: startReference
        )
        let endSnapshot = QueryDocumentSnapshot(
            fields: ["score": .integer(20)],
            documentReference: endReference
        )

        let query = try Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: []
        )
        .order(by: "score")
        .start(afterDocument: startSnapshot)
        .end(atDocument: endSnapshot)
        .limit(toLast: 2)

        let plan = try QueryCompiler(query: query).makeRunQueryPlan()
        let structuredQuery = plan.request.structuredQuery
        let startValues = structuredQuery.startAt.values
        let endValues = structuredQuery.endAt.values

        #expect(plan.requiresResultOrderReversal)
        #expect(structuredQuery.orderBy.map(\.field.fieldPath) == ["score", "__name__"])
        #expect(structuredQuery.orderBy.map(\.direction) == [.descending, .descending])
        #expect(structuredQuery.limit.value == 2)
        #expect(startValues.count == 2)
        #expect(startValues[0].integerValue == 20)
        #expect(startValues[1].referenceValue == "projects/test-project/databases/(default)/documents/users/userZ")
        #expect(structuredQuery.startAt.before)
        #expect(endValues.count == 2)
        #expect(endValues[0].integerValue == 10)
        #expect(endValues[1].referenceValue == "projects/test-project/databases/(default)/documents/users/userA")
        #expect(structuredQuery.endAt.before)
    }

    @Test("Document snapshot cursors add implicit document ID ordering")
    func testDocumentSnapshotCursorsAddImplicitDocumentIDOrdering() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let snapshot = QueryDocumentSnapshot(
            fields: ["score": .integer(42)],
            documentReference: reference
        )

        let keyOnlyQuery = try Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: []
        )
        .start(atDocument: snapshot)
        let descendingQuery = try Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: []
        )
        .order(by: "score", descending: true)
        .start(afterDocument: snapshot)

        let keyOnlyRequest = try QueryCompiler(query: keyOnlyQuery).makeRunQueryRequest()
        let descendingRequest = try QueryCompiler(query: descendingQuery).makeRunQueryRequest()

        #expect(keyOnlyRequest.structuredQuery.orderBy.map(\.field.fieldPath) == ["__name__"])
        #expect(keyOnlyRequest.structuredQuery.orderBy.map(\.direction) == [.ascending])
        #expect(keyOnlyRequest.structuredQuery.startAt.values.map(\.referenceValue) == [
            "projects/test-project/databases/(default)/documents/users/user123"
        ])
        #expect(keyOnlyRequest.structuredQuery.startAt.before)

        #expect(descendingRequest.structuredQuery.orderBy.map(\.field.fieldPath) == ["score", "__name__"])
        #expect(descendingRequest.structuredQuery.orderBy.map(\.direction) == [.descending, .descending])
        #expect(descendingRequest.structuredQuery.startAt.values[0].integerValue == 42)
        #expect(descendingRequest.structuredQuery.startAt.values[1].referenceValue == "projects/test-project/databases/(default)/documents/users/user123")
        #expect(!descendingRequest.structuredQuery.startAt.before)
    }

    @Test("Document snapshot cursors validate ordered fields and database")
    func testDocumentSnapshotCursorsValidateOrderedFieldsAndDatabase() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let snapshot = DocumentSnapshot(
            fields: ["score": .integer(42)],
            documentReference: reference
        )
        let missingDocument = DocumentSnapshot(documentReference: reference)
        let otherReference = DocumentReference(
            Database(projectId: "other-project"),
            parentPath: "users",
            documentID: "user123"
        )
        let otherDatabaseSnapshot = QueryDocumentSnapshot(
            fields: ["score": .integer(42)],
            documentReference: otherReference
        )

        let baseQuery = Query(database, parentPath: nil, collectionID: "users", predicates: [])
        let orderedQuery = baseQuery.order(by: "score")
        let missingFieldQuery = baseQuery.order(by: "missing")

        var missingDocumentDidThrow = false
        do {
            _ = try orderedQuery.start(atDocument: missingDocument)
        } catch FirestoreError.invalidQuery(let message) {
            missingDocumentDidThrow = message.contains("existing document")
        } catch {
            missingDocumentDidThrow = false
        }

        var missingFieldDidThrow = false
        do {
            _ = try missingFieldQuery.start(atDocument: snapshot)
        } catch FirestoreError.invalidQuery(let message) {
            missingFieldDidThrow = message.contains("missing")
        } catch {
            missingFieldDidThrow = false
        }

        var databaseMismatchDidThrow = false
        do {
            _ = try orderedQuery.start(atDocument: otherDatabaseSnapshot)
        } catch FirestoreError.databaseMismatch(let expected, let actual) {
            databaseMismatchDidThrow =
                expected == "projects/test-project/databases/(default)" &&
                actual == "projects/other-project/databases/(default)"
        } catch {
            databaseMismatchDidThrow = false
        }

        #expect(missingDocumentDidThrow)
        #expect(missingFieldDidThrow)
        #expect(databaseMismatchDidThrow)
    }

    @Test("Query composite chaining preserves existing filters")
    func testQueryCompositeChainingPreservesExistingFilters() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: []
        )
        .whereField("active", isEqualTo: true)
        .or([
            .isEqualTo("role", "admin"),
            .isEqualTo("role", "owner")
        ])

        let request = try QueryCompiler(query: query).makeRunQueryRequest()
        let compositeFilter = request.structuredQuery.where.compositeFilter

        #expect(compositeFilter.op == .and)
        #expect(compositeFilter.filters.count == 2)
        #expect(compositeFilter.filters[0].fieldFilter.field.fieldPath == "active")
        #expect(compositeFilter.filters[1].compositeFilter.op == .or)
        #expect(compositeFilter.filters[1].compositeFilter.filters.count == 2)
    }

    @Test("SDK Filter facade compiles through QueryPredicate RPC compiler")
    func testSDKFilterFacadeCompilesThroughQueryPredicateRPCCompiler() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: []
        )
        .whereFilter(
            .orFilter(
                with: [
                    .filter(whereField: "role", isEqualTo: "admin"),
                    .filter(whereField: "score", isGreaterThanOrEqualTo: 90)
                ]
            )
        )
        .whereField("active", isEqualTo: true)

        let request = try QueryCompiler(query: query).makeRunQueryRequest()
        let rootFilter = request.structuredQuery.where.compositeFilter
        let orFilter = rootFilter.filters[0].compositeFilter
        let activeFilter = rootFilter.filters[1].fieldFilter

        #expect(rootFilter.op == .and)
        #expect(orFilter.op == .or)
        #expect(orFilter.filters[0].fieldFilter.field.fieldPath == "role")
        #expect(orFilter.filters[0].fieldFilter.op == .equal)
        #expect(orFilter.filters[1].fieldFilter.field.fieldPath == "score")
        #expect(orFilter.filters[1].fieldFilter.op == .greaterThanOrEqual)
        #expect(activeFilter.field.fieldPath == "active")
        #expect(activeFilter.value.booleanValue)
    }

    @Test("SDK Filter facade preserves nested composite query shape")
    func testSDKFilterFacadePreservesNestedCompositeQueryShape() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: []
        )
        .whereFilter(
            .andFilter(
                with: [
                    .orFilter(
                        with: [
                            .filter(whereField: "role", isEqualTo: "admin"),
                            .filter(whereField: "role", isEqualTo: "owner")
                        ]
                    ),
                    .orFilter(
                        with: [
                            .filter(whereField: "region", isEqualTo: "west"),
                            .filter(whereField: "score", isGreaterThanOrEqualTo: 90)
                        ]
                    )
                ]
            )
        )
        .whereField("active", isEqualTo: true)

        let request = try QueryCompiler(query: query).makeRunQueryRequest()
        let rootFilter = request.structuredQuery.where.compositeFilter
        let roleFilter = rootFilter.filters[0].compositeFilter
        let regionOrScoreFilter = rootFilter.filters[1].compositeFilter
        let activeFilter = rootFilter.filters[2].fieldFilter

        #expect(rootFilter.op == .and)
        #expect(rootFilter.filters.count == 3)
        #expect(roleFilter.op == .or)
        #expect(roleFilter.filters.map { $0.fieldFilter.field.fieldPath } == ["role", "role"])
        #expect(roleFilter.filters.map { $0.fieldFilter.value.stringValue } == ["admin", "owner"])
        #expect(regionOrScoreFilter.op == .or)
        #expect(regionOrScoreFilter.filters[0].fieldFilter.field.fieldPath == "region")
        #expect(regionOrScoreFilter.filters[0].fieldFilter.op == .equal)
        #expect(regionOrScoreFilter.filters[1].fieldFilter.field.fieldPath == "score")
        #expect(regionOrScoreFilter.filters[1].fieldFilter.op == .greaterThanOrEqual)
        #expect(activeFilter.field.fieldPath == "active")
        #expect(activeFilter.value.booleanValue)
    }

    @Test("SDK Filter facade supports FieldPath document ID filters")
    func testSDKFilterFacadeSupportsFieldPathDocumentIDFilters() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: "organizations/org123",
            collectionID: "users",
            predicates: []
        )
        .whereFilter(
            try .filter(
                whereFieldPath: .documentID(),
                in: ["user123", "user456"]
            )
        )

        let request = try QueryCompiler(query: query).makeRunQueryRequest()
        let filter = request.structuredQuery.where.fieldFilter
        let values = filter.value.arrayValue.values.map(\.referenceValue)

        #expect(filter.field.fieldPath == "__name__")
        #expect(filter.op == .in)
        #expect(values == [
            "projects/test-project/databases/(default)/documents/organizations/org123/users/user123",
            "projects/test-project/databases/(default)/documents/organizations/org123/users/user456"
        ])
    }

    @Test("QueryCompiler rejects collection document ID filters with document paths")
    func testQueryCompilerRejectsCollectionDocumentIDFiltersWithDocumentPaths() throws {
        let database = Database(projectId: "test-project")
        let query = try Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: []
        )
        .whereField(FieldPath.documentID(), isEqualTo: "organizations/org123/users/user123")

        do {
            _ = try QueryCompiler(query: query).makeRunQueryRequest()
            Issue.record("Expected invalid document ID filter error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("plain document ID"))
        }
    }

    @Test("QueryCompiler accepts collection group document ID filters with document paths")
    func testQueryCompilerAcceptsCollectionGroupDocumentIDFiltersWithDocumentPaths() throws {
        let database = Database(projectId: "test-project")
        let query = try CollectionGroup(
            database,
            groupID: "users"
        )
        .whereField(FieldPath.documentID(), isEqualTo: "organizations/org123/users/user123")

        let filter = try QueryCompiler(query: query).makeRunQueryRequest().structuredQuery.where.fieldFilter

        #expect(filter.field.fieldPath == "__name__")
        #expect(filter.value.referenceValue == "projects/test-project/databases/(default)/documents/organizations/org123/users/user123")
    }

    @Test("FirestoreQuerySource protocol preserves shared query builder behavior")
    func testFirestoreQuerySourceProtocolPreservesSharedQueryBuilderBehavior() throws {
        let database = Database(projectId: "test-project")
        let querySource: any FirestoreQuerySource = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: []
        )
        let collectionSource: any FirestoreQuerySource = CollectionReference(
            database,
            parentPath: nil,
            collectionID: "users"
        )
        let groupSource: any FirestoreQuerySource = CollectionGroup(
            database,
            groupID: "users"
        )

        for source in [querySource, collectionSource, groupSource] {
            let query = source
                .whereFilter(.filter(whereField: "active", isEqualTo: true))
                .whereField("score", isGreaterThanOrEqualTo: 90)
                .order(by: "score", descending: true)
                .limit(to: 5)
            let request = try QueryCompiler(query: query).makeRunQueryRequest()
            let filters = request.structuredQuery.where.compositeFilter.filters

            #expect(filters[0].fieldFilter.field.fieldPath == "active")
            #expect(filters[1].fieldFilter.field.fieldPath == "score")
            #expect(request.structuredQuery.orderBy.map(\.field.fieldPath) == ["score"])
            #expect(request.structuredQuery.limit.value == 5)
        }
    }

    @Test("QueryCompiler compiles NaN equality as unary filters")
    func testQueryCompilerCompilesNaNEqualityAsUnaryFilters() throws {
        let database = Database(projectId: "test-project")
        let equalQuery = Query(
            database,
            parentPath: nil,
            collectionID: "scores",
            predicates: [.isEqualTo("value", Double.nan)]
        )
        let notEqualQuery = Query(
            database,
            parentPath: nil,
            collectionID: "scores",
            predicates: [.isNotEqualTo("value", Float.nan)]
        )

        let equalFilter = try QueryCompiler(query: equalQuery).makeRunQueryRequest().structuredQuery.where
        let notEqualFilter = try QueryCompiler(query: notEqualQuery).makeRunQueryRequest().structuredQuery.where

        #expect(equalFilter.unaryFilter.field.fieldPath == "value")
        #expect(equalFilter.unaryFilter.op == .isNan)
        #expect(notEqualFilter.unaryFilter.field.fieldPath == "value")
        #expect(notEqualFilter.unaryFilter.op == .isNotNan)
    }

    @Test("QueryCompiler compiles limitToLast by reversing order")
    func testQueryCompilerCompilesLimitToLastByReversingOrder() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: [
                .orderBy("score", false),
                .limitToLast(3)
            ]
        )

        let plan = try QueryCompiler(query: query).makeRunQueryPlan()
        let structuredQuery = plan.request.structuredQuery

        #expect(plan.requiresResultOrderReversal)
        #expect(structuredQuery.limit.value == 3)
        #expect(structuredQuery.orderBy.count == 1)
        #expect(structuredQuery.orderBy[0].field.fieldPath == "score")
        #expect(structuredQuery.orderBy[0].direction == .descending)
    }

    @Test("QueryCompiler rejects limitToLast without order")
    func testQueryCompilerRejectsLimitToLastWithoutOrder() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: [.limitToLast(3)]
        )

        do {
            _ = try QueryCompiler(query: query).makeRunQueryPlan()
            Issue.record("Expected invalid query error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("limitToLast"))
        }
    }

    @Test("QueryCompiler rejects negative limit")
    func testQueryCompilerRejectsNegativeLimit() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: [.limitTo(-1)]
        )

        do {
            _ = try QueryCompiler(query: query).makeRunQueryPlan()
            Issue.record("Expected invalid query error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("greater than or equal to zero"))
        }
    }

    @Test("QueryCompiler allows zero limit")
    func testQueryCompilerAllowsZeroLimit() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: [.limitTo(0)]
        )

        let request = try QueryCompiler(query: query).makeRunQueryRequest()

        #expect(request.structuredQuery.limit.value == 0)
    }

    @Test("QueryCompiler builds count sum and average aggregations")
    func testQueryCompilerBuildsCountSumAndAverageAggregations() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "cities",
            predicates: [.isEqualTo("capital", true)]
        )

        let request = try QueryCompiler(query: query).makeRunAggregationQueryRequest(
            fields: [
                .count(),
                .sum("population"),
                .average("density", alias: "avg_density")
            ]
        )
        let aggregations = request.structuredAggregationQuery.aggregations

        #expect(request.parent == "projects/test-project/databases/(default)/documents")
        #expect(request.structuredAggregationQuery.structuredQuery.from.first?.collectionID == "cities")
        #expect(aggregations.count == 3)
        #expect(aggregations.map { $0.alias } == ["count", "sum_population", "avg_density"])
        if case .count = aggregations[0].operator {
            #expect(true)
        } else {
            Issue.record("Expected count aggregation")
        }
        #expect(aggregations[1].sum.field.fieldPath == "population")
        #expect(aggregations[2].avg.field.fieldPath == "density")
    }

    @Test("QueryCompiler normalizes aggregation field paths")
    func testQueryCompilerNormalizesAggregationFieldPaths() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "cities",
            predicates: []
        )

        let request = try QueryCompiler(query: query).makeRunAggregationQueryRequest(
            fields: [
                .sum("stats.population"),
                .average(FieldPath(["stats.density"]), alias: "avg_density")
            ]
        )
        let aggregations = request.structuredAggregationQuery.aggregations

        #expect(aggregations[0].sum.field.fieldPath == "stats.population")
        #expect(aggregations[1].avg.field.fieldPath == "`stats.density`")
    }

    @Test("QueryCompiler rejects invalid aggregation field paths")
    func testQueryCompilerRejectsInvalidAggregationFieldPaths() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "cities",
            predicates: []
        )

        do {
            _ = try QueryCompiler(query: query).makeRunAggregationQueryRequest(
                fields: [.sum("stats..population")]
            )
            Issue.record("Expected invalid aggregation field path error")
        } catch FirestoreError.invalidFieldPath(let message) {
            #expect(message.contains("Field name cannot be empty"))
        }
    }

    @Test("QueryCompiler rejects invalid aggregation aliases")
    func testQueryCompilerRejectsInvalidAggregationAliases() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "cities",
            predicates: []
        )

        do {
            _ = try QueryCompiler(query: query).makeRunAggregationQueryRequest(
                fields: [.count(alias: "__count__")]
            )
            Issue.record("Expected invalid aggregation alias error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("Aggregation alias"))
            #expect(message.contains("reserved Firestore field name"))
        }
    }

    @Test("QueryCompiler encodes explain options")
    func testQueryCompilerEncodesExplainOptions() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "cities",
            predicates: []
        )

        let queryRequest = try QueryCompiler(query: query).makeRunQueryRequest(
            explainOptions: .analyze
        )
        let aggregationRequest = try QueryCompiler(query: query).makeRunAggregationQueryRequest(
            fields: [.count()],
            explainOptions: .planOnly
        )

        #expect(queryRequest.hasExplainOptions)
        #expect(queryRequest.explainOptions.analyze)
        #expect(aggregationRequest.hasExplainOptions)
        #expect(!aggregationRequest.explainOptions.analyze)
    }

    @Test("QueryCompiler encodes vector findNearest")
    func testQueryCompilerEncodesVectorFindNearest() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "cities",
            predicates: []
        )
        .whereField("country", isEqualTo: "USA")
        .findNearest(
            vectorField: "embedding",
            queryVector: FirestoreVector([0.1, 0.2, 0.3]),
            limit: 7,
            distanceMeasure: .dotProduct,
            distanceResultField: "vectorDistance",
            distanceThreshold: 0.8
        )

        let request = try QueryCompiler(query: query).makeRunQueryRequest()
        let findNearest = request.structuredQuery.findNearest

        #expect(request.structuredQuery.hasFindNearest)
        #expect(request.structuredQuery.from.first?.collectionID == "cities")
        #expect(request.structuredQuery.where.fieldFilter.field.fieldPath == "country")
        #expect(findNearest.vectorField.fieldPath == "embedding")
        #expect(findNearest.queryVector.arrayValue.values.map(\.doubleValue) == [0.1, 0.2, 0.3])
        #expect(findNearest.distanceMeasure == .dotProduct)
        #expect(findNearest.limit.value == 7)
        #expect(findNearest.distanceResultField == "vectorDistance")
        #expect(findNearest.distanceThreshold.value == 0.8)
    }

    @Test("PartitionQueryCompiler builds collection group partition requests")
    func testPartitionQueryCompilerBuildsCollectionGroupPartitionRequests() throws {
        let database = Database(projectId: "test-project")
        let collectionGroup = CollectionGroup(database, groupID: "posts")
        let request = try PartitionQueryCompiler(collectionGroup: collectionGroup)
            .makePartitionQueryRequest(
                partitionPointCount: 3,
                pageSize: 2,
                pageToken: "next-page",
                readTime: Timestamp(seconds: 10, nanos: 20)
            )

        #expect(request.parent == "projects/test-project/databases/(default)/documents")
        #expect(request.partitionCount == 3)
        #expect(request.pageSize == 2)
        #expect(request.pageToken == "next-page")
        #expect(request.readTime.seconds == 10)
        #expect(request.readTime.nanos == 20)
        #expect(request.structuredQuery.from.first?.collectionID == "posts")
        #expect(request.structuredQuery.from.first?.allDescendants == true)
        #expect(request.structuredQuery.orderBy.map(\.field.fieldPath) == ["__name__"])
        #expect(request.structuredQuery.orderBy.map(\.direction) == [.ascending])
        #expect(!request.structuredQuery.hasWhere)
        #expect(!request.structuredQuery.hasLimit)
        #expect(!request.structuredQuery.hasStartAt)
        #expect(!request.structuredQuery.hasEndAt)
    }

    @Test("PartitionQueryCompiler rejects invalid partition options")
    func testPartitionQueryCompilerRejectsInvalidPartitionOptions() throws {
        let database = Database(projectId: "test-project")
        let compiler = PartitionQueryCompiler(collectionGroup: CollectionGroup(database, groupID: "posts"))

        do {
            _ = try compiler.makePartitionQueryRequest(partitionPointCount: 0)
            Issue.record("Expected invalid partitionPointCount error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("partitionPointCount"))
        }

        do {
            _ = try compiler.makePartitionQueryRequest(partitionPointCount: 1, pageSize: -1)
            Issue.record("Expected invalid pageSize error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("pageSize"))
        }
    }

    @Test("QueryCompiler rejects invalid vector distance result field names")
    func testQueryCompilerRejectsInvalidVectorDistanceResultFieldNames() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "cities",
            predicates: []
        )
        .findNearest(
            vectorField: "embedding",
            queryVector: FirestoreVector([0.1, 0.2, 0.3]),
            limit: 7,
            distanceMeasure: .euclidean,
            distanceResultField: "__distance__"
        )

        do {
            _ = try QueryCompiler(query: query).makeRunQueryRequest()
            Issue.record("Expected invalid distance result field error")
        } catch FirestoreError.invalidFieldPath(let message) {
            #expect(message.contains("reserved Firestore field name"))
        }
    }

    @Test("QueryCompiler rejects invalid vector findNearest combinations")
    func testQueryCompilerRejectsInvalidVectorFindNearestCombinations() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "cities",
            predicates: []
        )
        .findNearest(
            vectorField: "embedding",
            queryVector: FirestoreVector([0.1, 0.2]),
            limit: 3,
            distanceMeasure: .euclidean
        )
        .limit(to: 3)

        do {
            _ = try QueryCompiler(query: query).makeRunQueryRequest()
            Issue.record("Expected invalid query error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("findNearest"))
        }
    }

    @Test("QueryCompiler rejects unsupported aggregation field counts")
    func testQueryCompilerRejectsUnsupportedAggregationFieldCounts() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "cities",
            predicates: []
        )

        do {
            _ = try QueryCompiler(query: query).makeRunAggregationQueryRequest(fields: [])
            Issue.record("Expected empty aggregation error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("at least one"))
        }

        do {
            _ = try QueryCompiler(query: query).makeRunAggregationQueryRequest(
                fields: [
                    .count(alias: "a"),
                    .count(alias: "b"),
                    .count(alias: "c"),
                    .count(alias: "d"),
                    .count(alias: "e"),
                    .count(alias: "f")
                ]
            )
            Issue.record("Expected aggregation count limit error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("at most five"))
        }
    }

    @Test("PipelineCompiler encodes subquery pipeline values and variables")
    func testPipelineCompilerEncodesSubqueryPipelineValuesAndVariables() throws {
        let database = Database(projectId: "test-project")
        let subquery = FirestorePipeline()
            .collectionGroup("reviews")
            .where(.field("author").equal(.variable("reviewer_name")))
            .where(.field("rating").lessThan(2))
            .select([.field("review"), .field("rating")])
        let pipeline = FirestorePipeline()
            .collection("reviewers")
            .define([.field("__name__").as("reviewer_name")])
            .select([
                .field("__name__"),
                subquery.toArrayExpression().as("negative_reviews")
            ])

        let request = try PipelineCompiler(database: database).makeExecutePipelineRequest(pipeline: pipeline)
        let stages = request.structuredPipeline.pipeline.stages
        let arrayExpression = stages[2].args[1].functionValue.args[0].functionValue
        let subqueryStages = arrayExpression.args[0].pipelineValue.stages
        let whereExpression = subqueryStages[1].args[0].functionValue

        #expect(request.database == "projects/test-project/databases/(default)")
        #expect(stages.map { $0.name } == ["collection", "let", "select"])
        #expect(stages[0].args.first?.stringValue == "reviewers")
        #expect(stages[1].args.first?.functionValue.name == "as")
        #expect(stages[2].args[1].functionValue.name == "as")
        #expect(arrayExpression.name == "array")
        #expect(subqueryStages.map { $0.name } == ["collection_group", "where", "where", "select"])
        #expect(whereExpression.name == "equal")
        #expect(whereExpression.args[0].fieldReferenceValue == "author")
        #expect(whereExpression.args[1].variableReferenceValue == "reviewer_name")
        #expect(subqueryStages[2].args[0].functionValue.name == "less_than")
    }

    @Test("PipelineCompiler allows subcollection only inside subquery expressions")
    func testPipelineCompilerAllowsSubcollectionOnlyInsideSubqueryExpressions() throws {
        let database = Database(projectId: "test-project")
        let compiler = PipelineCompiler(database: database)
        let subquery = FirestorePipeline()
            .subcollection("reviews")
            .where(.field("rating").greaterThanOrEqual(4))
            .sort([.field("rating").descending()])
            .limit(3)
        let pipeline = FirestorePipeline()
            .collection("restaurants")
            .addFields([
                subquery.toArrayExpression().as("top_reviews")
            ])

        let request = try compiler.makeExecutePipelineRequest(pipeline: pipeline)
        let stages = request.structuredPipeline.pipeline.stages
        let arrayExpression = stages[1].args[0].functionValue.args[0].functionValue
        let subqueryStages = arrayExpression.args[0].pipelineValue.stages

        #expect(stages.map(\.name) == ["collection", "add_fields"])
        #expect(arrayExpression.name == "array")
        #expect(subqueryStages.map(\.name) == ["subcollection", "where", "sort", "limit"])
        #expect(subqueryStages[0].args[0].stringValue == "reviews")

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline().subcollection("reviews")
            )
            Issue.record("Expected top-level subcollection stage error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("subquery"))
        }

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline()
                    .collection("restaurants")
                    .union(with: FirestorePipeline().subcollection("reviews"))
            )
            Issue.record("Expected non-subquery subcollection stage error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("subquery"))
        }
    }

    @Test("PipelineCompiler encodes Pipeline DML output stages")
    func testPipelineCompilerEncodesPipelineDMLOutputStages() throws {
        let database = Database(projectId: "test-project")
        let updatePipeline = FirestorePipeline()
            .collection("cities")
            .where(.field("population").greaterThan(10_000))
            .update([
                .field("population").add(1).as("population")
            ])
        let deletePipeline = FirestorePipeline()
            .collection("cities")
            .where(.field("archived").equal(true))
            .delete()

        let updateRequest = try PipelineCompiler(database: database).makeExecutePipelineRequest(
            pipeline: updatePipeline
        )
        let deleteRequest = try PipelineCompiler(database: database).makeExecutePipelineRequest(
            pipeline: deletePipeline
        )
        let updateStages = updateRequest.structuredPipeline.pipeline.stages
        let deleteStages = deleteRequest.structuredPipeline.pipeline.stages
        let updateAssignment = updateStages[2].args[0].functionValue
        let updateExpression = updateAssignment.args[0].functionValue

        #expect(updateRequest.database == "projects/test-project/databases/(default)")
        #expect(updateStages.map(\.name) == ["collection", "where", "update"])
        #expect(updateAssignment.name == "as")
        #expect(updateExpression.name == "add")
        #expect(updateAssignment.args[1].stringValue == "population")
        #expect(deleteStages.map(\.name) == ["collection", "where", "delete"])
        #expect(deleteStages[2].args.isEmpty)
        #expect(deleteStages[2].options.isEmpty)
    }

    @Test("PipelineCompiler encodes Pipeline Search stage")
    func testPipelineCompilerEncodesPipelineSearchStage() throws {
        let database = Database(projectId: "test-project")
        let center = GeoPoint(latitude: 37.7749, longitude: -122.4194)
        let pipeline = FirestorePipeline()
            .collection("restaurants")
            .search(
                query: .field("location").geoDistance(to: center).lessThanOrEqual(1_000),
                sort: [.score().descending()],
                addFields: [.score().as("searchScore")]
            )
            .limit(3)

        let request = try PipelineCompiler(database: database).makeExecutePipelineRequest(pipeline: pipeline)
        let stages = request.structuredPipeline.pipeline.stages
        let searchOptions = stages[1].options
        let query = try #require(searchOptions["query"]?.functionValue)
        let geoDistance = try #require(query.args.first?.functionValue)
        let centerValue = try #require(geoDistance.args.last)
        let sortValues = try #require(searchOptions["sort"]?.arrayValue.values)
        let addFields = try #require(searchOptions["add_fields"]?.arrayValue.values)
        let descending = sortValues[0].functionValue
        let searchScore = addFields[0].functionValue

        #expect(stages.map(\.name) == ["collection", "search", "limit"])
        #expect(query.name == "less_than_or_equal")
        #expect(query.args.last?.integerValue == 1_000)
        #expect(geoDistance.name == "geo_distance")
        #expect(geoDistance.args.first?.fieldReferenceValue == "location")
        #expect(centerValue.geoPointValue.latitude == 37.7749)
        #expect(centerValue.geoPointValue.longitude == -122.4194)
        #expect(descending.name == "descending")
        #expect(descending.args[0].functionValue.name == "score")
        #expect(searchScore.name == "as")
        #expect(searchScore.args[0].functionValue.name == "score")
        #expect(searchScore.args[1].stringValue == "searchScore")
    }

    @Test("PipelineCompiler validates known transformation stage shapes")
    func testPipelineCompilerValidatesKnownTransformationStageShapes() throws {
        let compiler = PipelineCompiler(database: Database(projectId: "test-project"))

        func expectInvalidQuery(_ pipeline: FirestorePipeline, contains expectedMessage: String) throws {
            do {
                _ = try compiler.makeExecutePipelineRequest(pipeline: pipeline)
                Issue.record("Expected invalid Pipeline query error")
            } catch FirestoreError.invalidQuery(let message) {
                #expect(message.contains(expectedMessage))
            }
        }

        try expectInvalidQuery(
            FirestorePipeline().stage("literals"),
            contains: "literals stage requires at least one literal document"
        )
        try expectInvalidQuery(
            FirestorePipeline().stage("literals", arguments: [.string("not-a-document")]),
            contains: "literals stage accepts only map arguments"
        )
        try expectInvalidQuery(
            FirestorePipeline().collection("books").stage("where", arguments: [.bool(true), .bool(false)]),
            contains: "where stage requires exactly one filter expression"
        )
        try expectInvalidQuery(
            FirestorePipeline().collection("books").select([]),
            contains: "select stage requires at least one projection expression"
        )
        try expectInvalidQuery(
            FirestorePipeline().collection("books").addFields([]),
            contains: "add_fields stage requires at least one field assignment"
        )
        try expectInvalidQuery(
            FirestorePipeline().collection("books").stage("remove_fields", arguments: [.int(1)]),
            contains: "remove_fields stage accepts only field name strings"
        )
        try expectInvalidQuery(
            FirestorePipeline().collection("books").aggregate([]),
            contains: "aggregate stage requires at least one accumulator expression"
        )
        try expectInvalidQuery(
            FirestorePipeline()
                .collection("books")
                .stage("aggregate", arguments: [.field("rating").sum()], options: ["groups": .string("genre")]),
            contains: "aggregate stage groups option must be an array"
        )
        try expectInvalidQuery(
            FirestorePipeline().collection("books").stage("replace_with", arguments: [.field("profile")]),
            contains: "replace_with stage requires value and mode arguments"
        )
        try expectInvalidQuery(
            FirestorePipeline()
                .collection("books")
                .stage("replace_with", arguments: [.field("profile"), .string("unsupported")]),
            contains: "replace_with stage mode is unsupported"
        )
        try expectInvalidQuery(
            FirestorePipeline().collection("books").stage("sample"),
            contains: "sample stage requires count or percentage"
        )
        try expectInvalidQuery(
            FirestorePipeline().collection("books").stage("sample", arguments: [.int(0)]),
            contains: "sample stage count must be greater than zero"
        )
        try expectInvalidQuery(
            FirestorePipeline().collection("books").stage("sample", options: ["percentage": .string("10")]),
            contains: "sample stage percentage must be a double"
        )
        try expectInvalidQuery(
            FirestorePipeline().collection("books").stage("unnest"),
            contains: "unnest stage requires exactly one array expression"
        )
        try expectInvalidQuery(
            FirestorePipeline().collection("books").stage(
                "unnest",
                arguments: [.field("tags")],
                options: ["index_field": .int(1)]
            ),
            contains: "unnest stage index_field option must be a string"
        )
        try expectInvalidQuery(
            FirestorePipeline().collection("books").stage("union", arguments: [.string("books")]),
            contains: "union stage accepts only pipeline arguments"
        )
        try expectInvalidQuery(
            FirestorePipeline()
                .collection("books")
                .stage("find_nearest", options: ["field": .field("embedding"), "unknown": .bool(true)]),
            contains: "find_nearest stage does not support unknown option"
        )
        try expectInvalidQuery(
            FirestorePipeline().collection("books").stage(
                "find_nearest",
                options: [
                    "field": .string("embedding"),
                    "vector_value": .vector([1.0, 2.0]),
                    "distance_measure": .string("cosine")
                ]
            ),
            contains: "find_nearest field option must be a field reference"
        )
        try expectInvalidQuery(
            FirestorePipeline().collection("books").stage(
                "find_nearest",
                options: [
                    "field": .field("embedding"),
                    "vector_value": .string("not-a-vector"),
                    "distance_measure": .string("cosine")
                ]
            ),
            contains: "find_nearest.vector_value must be an array"
        )
        try expectInvalidQuery(
            FirestorePipeline().collection("books").stage(
                "find_nearest",
                options: [
                    "field": .field("embedding"),
                    "vector_value": .vector([1.0, 2.0]),
                    "distance_measure": .int(1)
                ]
            ),
            contains: "find_nearest distance_measure must be a string"
        )
        try expectInvalidQuery(
            FirestorePipeline()
                .collection("books")
                .select([.function("path", [.field("documentPath")]).as("pathValue")]),
            contains: "path function argument must be a string"
        )
        try expectInvalidQuery(
            FirestorePipeline()
                .collection("books")
                .select([.function("vector", [.double(1.0), .double(2.0)]).as("vectorValue")]),
            contains: "vector function requires exactly one array argument"
        )
    }

    @Test("PipelineCompiler validates typed source stages before RPC encoding")
    func testPipelineCompilerValidatesTypedSourceStagesBeforeRPCEncoding() throws {
        let compiler = PipelineCompiler(database: Database(projectId: "test-project"))

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline().collection("users/user123")
            )
            Issue.record("Expected invalid collection path error")
        } catch FirestoreError.invalidPath(let message) {
            #expect(message.contains("collection"))
        }

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline().collectionGroup("users/posts")
            )
            Issue.record("Expected invalid collection group ID error")
        } catch FirestoreError.invalidPath(let message) {
            #expect(message.contains("Collection group ID"))
        }

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline()
                    .collection("restaurants")
                    .addFields([
                        FirestorePipeline()
                            .subcollection("reviews/drafts")
                            .toArrayExpression()
                            .as("reviews")
                    ])
            )
            Issue.record("Expected invalid subcollection ID error")
        } catch FirestoreError.invalidPath(let message) {
            #expect(message.contains("Collection group ID"))
        }

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline()
                    .stage("where", arguments: [.bool(true)])
                    .collection("users")
            )
            Issue.record("Expected non-leading input stage error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("collection stage must be the first Pipeline stage"))
        }

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline().documents([])
            )
            Issue.record("Expected empty documents stage error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("at least one document reference"))
        }

        do {
            let otherDatabaseReference = DocumentReference(
                Database(projectId: "other-project"),
                parentPath: "users",
                documentID: "user123"
            )
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline().documents([otherDatabaseReference])
            )
            Issue.record("Expected documents stage database mismatch error")
        } catch FirestoreError.databaseMismatch(let expected, let actual) {
            #expect(expected == "projects/test-project/databases/(default)")
            #expect(actual == "projects/other-project/databases/(default)")
        }

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline().stage(
                    "documents",
                    arguments: [
                        .reference("projects/other-project/databases/(default)/documents/users/user123")
                    ]
                )
            )
            Issue.record("Expected raw documents stage database mismatch error")
        } catch FirestoreError.databaseMismatch(let expected, let actual) {
            #expect(expected == "projects/test-project/databases/(default)")
            #expect(actual == "projects/other-project/databases/(default)")
        }

        do {
            let otherDatabaseReference = DocumentReference(
                Database(projectId: "other-project"),
                parentPath: "users",
                documentID: "user123"
            )
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline()
                    .collection("users")
                    .select([PipelineValue.reference(otherDatabaseReference).documentID().as("foreignID")])
            )
            Issue.record("Expected Pipeline reference database mismatch error")
        } catch FirestoreError.databaseMismatch(let expected, let actual) {
            #expect(expected == "projects/test-project/databases/(default)")
            #expect(actual == "projects/other-project/databases/(default)")
        }

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline()
                    .collection("users")
                    .select([PipelineValue.reference("users/user123").documentID().as("rawID")])
            )
            Issue.record("Expected raw Pipeline reference resource name error")
        } catch FirestoreError.invalidPath(let message) {
            #expect(message.contains("document resource name"))
        }

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline().stage("database", arguments: [.string("unexpected")])
            )
            Issue.record("Expected database stage argument error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("does not accept positional arguments"))
        }

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline().collection("users").limit(0)
            )
            Issue.record("Expected invalid limit count error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("greater than zero"))
        }

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline().collection("users").delete().limit(1)
            )
            Issue.record("Expected non-terminal delete stage error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("delete stage must be the final Pipeline stage"))
        }

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline().collection("users").update().limit(1)
            )
            Issue.record("Expected non-terminal update stage error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("update stage must be the final Pipeline stage"))
        }

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline()
                    .collection("users")
                    .stage("delete", arguments: [.string("unexpected")])
            )
            Issue.record("Expected delete stage argument error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("delete stage does not accept positional arguments"))
        }

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline()
                    .collection("users")
                    .stage("update", options: ["merge": .bool(true)])
            )
            Issue.record("Expected update stage option error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("update stage does not accept options"))
        }

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline()
                    .collection("restaurants")
                    .where(.field("active").equal(true))
                    .search(query: .documentMatches("waffles"))
            )
            Issue.record("Expected non-leading search stage error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("first non-input Pipeline stage"))
        }

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline()
                    .collection("restaurants")
                    .stage("search", arguments: [.string("waffles")])
            )
            Issue.record("Expected search stage argument error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("search stage uses options"))
        }

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline()
                    .collection("restaurants")
                    .stage("search")
            )
            Issue.record("Expected search stage query option error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("requires a query option"))
        }

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline()
                    .collection("restaurants")
                    .stage(
                        "search",
                        options: [
                            "query": .documentMatches("waffles"),
                            "sort": .string("score")
                        ]
                    )
            )
            Issue.record("Expected search stage sort option error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("sort option must be an array"))
        }

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline()
                    .collection("restaurants")
                    .stage(
                        "search",
                        options: [
                            "query": .documentMatches("waffles"),
                            "add_fields": .string("score")
                        ]
                    )
            )
            Issue.record("Expected search stage add_fields option error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("add_fields option must be an array"))
        }
    }

    @Test("PipelineCompiler validates option variable and lambda names")
    func testPipelineCompilerValidatesOptionVariableAndLambdaNames() throws {
        let compiler = PipelineCompiler(database: Database(projectId: "test-project"))

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline().stage(
                    "custom_stage",
                    options: ["BadOption": .bool(true)]
                )
            )
            Issue.record("Expected invalid Pipeline stage option name error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("Pipeline stage option"))
        }

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline().collection("books").where(.variable("BadVariable"))
            )
            Issue.record("Expected invalid Pipeline variable name error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("Pipeline variable"))
        }

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline().collection("books").where(
                    .function("custom_function", options: ["BadOption": .bool(true)])
                )
            )
            Issue.record("Expected invalid Pipeline function option name error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("Pipeline function option"))
        }

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline().collection("books").where(
                    .function("lambda", [.array([.string("BadParameter")]), .bool(true)])
                )
            )
            Issue.record("Expected invalid Pipeline lambda parameter name error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("Pipeline lambda parameter"))
        }

        do {
            _ = try compiler.makeExecutePipelineRequest(
                pipeline: FirestorePipeline().collection("restaurants").where(
                    .function("geo_distance", [.field("location")])
                )
            )
            Issue.record("Expected invalid Pipeline geo_distance argument count error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("geo_distance function requires exactly two arguments"))
        }
    }

    @Test("PipelineCompiler encodes explain options")
    func testPipelineCompilerEncodesExplainOptions() throws {
        let database = Database(projectId: "test-project")
        let pipeline = FirestorePipeline().collection("books").limit(10)

        let request = try PipelineCompiler(database: database).makeExecutePipelineRequest(
            pipeline: pipeline,
            explainOptions: .analyzeJSON
        )
        let explainOptions = try #require(request.structuredPipeline.options["explain_options"]?.mapValue.fields)

        #expect(explainOptions["mode"]?.stringValue == "analyze")
        #expect(explainOptions["output_format"]?.stringValue == "JSON")
    }

    @Test("PipelineCompiler encodes vector nearest stage and functions")
    func testPipelineCompilerEncodesVectorNearestStageAndFunctions() throws {
        let database = Database(projectId: "test-project")
        let sampleVector = FirestoreVector([1.5, 2.345])
        let pipeline = FirestorePipeline()
            .collection("cities")
            .findNearest(
                field: "embedding",
                vectorValue: sampleVector,
                distanceMeasure: .euclidean,
                limit: 10,
                distanceField: "computedDistance"
            )
            .select([
                .field("embedding").cosineDistance(sampleVector).as("cosineDistance"),
                .field("embedding").dotProduct(sampleVector).as("dotProduct"),
                .field("embedding").euclideanDistance(sampleVector).as("euclideanDistance"),
                .field("embedding").manhattanDistance(sampleVector).as("manhattanDistance"),
                .field("embedding").vectorLength().as("vectorLength")
            ])

        let request = try PipelineCompiler(database: database).makeExecutePipelineRequest(pipeline: pipeline)
        let stages = request.structuredPipeline.pipeline.stages
        let findNearestOptions = stages[1].options
        let selectFunctions = stages[2].args.map { $0.functionValue.args[0].functionValue.name }

        #expect(stages.map(\.name) == ["collection", "find_nearest", "select"])
        #expect(findNearestOptions["field"]?.fieldReferenceValue == "embedding")
        #expect(findNearestOptions["vector_value"]?.arrayValue.values.map(\.doubleValue) == sampleVector.values)
        #expect(findNearestOptions["distance_measure"]?.stringValue == "euclidean")
        #expect(findNearestOptions["limit"]?.integerValue == 10)
        #expect(findNearestOptions["distance_field"]?.stringValue == "computedDistance")
        #expect(selectFunctions == [
            "cosine_distance",
            "dot_product",
            "euclidean_distance",
            "manhattan_distance",
            "vector_length"
        ])
    }

    @Test("PipelineCompiler normalizes field references")
    func testPipelineCompilerNormalizesFieldReferences() throws {
        let database = Database(projectId: "test-project")
        let pipeline = try FirestorePipeline()
            .collection("books")
            .findNearest(
                field: FieldPath(["embedding.vector"]),
                vectorValue: FirestoreVector([1.0, 2.0]),
                distanceMeasure: .cosine
            )
            .select([
                .field("profile.name").as("profileName"),
                PipelineValue.field(FieldPath(["profile.name"])).as("literalProfileName")
            ])

        let request = try PipelineCompiler(database: database).makeExecutePipelineRequest(pipeline: pipeline)
        let stages = request.structuredPipeline.pipeline.stages
        let findNearestOptions = stages[1].options
        let selections = try Dictionary(uniqueKeysWithValues: stages[2].args.map { value -> (String, String) in
            let function = value.functionValue
            let expression = try #require(function.args.first)
            let alias = try #require(function.args.last?.stringValue)
            return (alias, expression.fieldReferenceValue)
        })

        #expect(findNearestOptions["field"]?.fieldReferenceValue == "`embedding.vector`")
        #expect(selections["profileName"] == "profile.name")
        #expect(selections["literalProfileName"] == "`profile.name`")
    }

    @Test("PipelineCompiler rejects invalid field references")
    func testPipelineCompilerRejectsInvalidFieldReferences() throws {
        let database = Database(projectId: "test-project")
        let pipeline = FirestorePipeline()
            .collection("books")
            .select([
                .field("profile..name").as("brokenProfileName")
            ])

        do {
            _ = try PipelineCompiler(database: database).makeExecutePipelineRequest(pipeline: pipeline)
            Issue.record("Expected invalid Pipeline field reference error")
        } catch FirestoreError.invalidFieldPath(let message) {
            #expect(message.contains("Field name cannot be empty"))
        }
    }

    @Test("PipelineCompiler encodes map string timestamp type and reference functions")
    func testPipelineCompilerEncodesMapStringTimestampTypeAndReferenceFunctions() throws {
        let database = Database(projectId: "test-project")
        let author = DocumentReference(database, parentPath: "authors", documentID: "ada")
        let pipeline = FirestorePipeline()
            .collection("books")
            .select([
                PipelineValue.currentContext().mapKeys().as("fieldNames"),
                PipelineValue.mapExpression([("title", .field("title")), ("score", .int(1))])
                    .mapEntries()
                    .as("titleEntries"),
                .field("awards").mapGet("pulitzer").as("hasPulitzer"),
                .field("awards").mapSet([("nobel", .bool(true))]).as("updatedAwards"),
                .field("awards").mapRemove(["old"]).as("cleanAwards"),
                PipelineValue.mapMerge([.field("profile"), .mapExpression([("active", .bool(true))])])
                    .as("mergedProfile"),
                .field("title").byteLength().as("titleBytes"),
                .field("title").charLength().as("titleChars"),
                .field("title").toLower().startsWith("swift").as("startsWithSwift"),
                .field("title").endsWith("guide").as("endsWithGuide"),
                .field("genre").like("%Fiction").as("fictionGenre"),
                .field("title").regexContains("Fire").as("regexContainsFire"),
                .field("code").regexMatch("^[A-Z]+$").as("regexMatchesCode"),
                PipelineValue.stringConcat([.field("first"), .string(" "), .field("last")]).as("fullName"),
                .field("title").stringContains("Swift").as("containsSwift"),
                .field("title").stringIndexOf("Swift").as("swiftIndex"),
                .field("title").toUpper().as("upperTitle"),
                .field("title").substring(position: 1, length: 3).as("titleSubstring"),
                .field("title").reverse().as("reversedTitle"),
                .field("title").stringRepeat(2).as("repeatedTitle"),
                .field("title").stringReplaceAll(find: " ", replacement: "_").as("slug"),
                .field("title").stringReplaceOne(find: "old", replacement: "new").as("renamedTitle"),
                .field("title").trim().as("trimmedTitle"),
                .field("title").leftTrim(" ").as("leftTrimmedTitle"),
                .field("title").rightTrim(" ").as("rightTrimmedTitle"),
                .field("tags").split(delimiter: ",").as("splitTags"),
                PipelineValue.currentTimestamp().timestampTrunc(.day).as("currentDay"),
                PipelineValue.currentTimestamp()
                    .timestampTrunc(.week(startingOn: "monday"))
                    .as("currentWeek"),
                .field("createdAtMicros").unixMicrosToTimestamp().as("createdAtFromMicros"),
                .field("createdAtMillis").unixMillisToTimestamp().as("createdAtFromMillis"),
                .field("createdAtSeconds").unixSecondsToTimestamp().as("createdAtFromSeconds"),
                .field("createdAt").timestampAdd(3653, .day).as("expiresAt"),
                .field("createdAt").timestampAdd(.field("extensionDays"), .day).as("dynamicExpiresAt"),
                .field("expiresAt").timestampSubtract(14, .day).as("warningAt"),
                .field("expiresAt").timestampSubtract(.field("graceDays"), .day).as("dynamicWarningAt"),
                .field("createdAt").timestampToUnixMicros().as("createdAtMicros"),
                .field("createdAt").timestampToUnixMillis().as("createdAtMillis"),
                .field("createdAt").timestampToUnixSeconds().as("createdAtSeconds"),
                .field("expiresAt").timestampDiff(from: .field("createdAt"), unit: .day).as("daysAlive"),
                .field("createdAt").timestampExtract(.year, timeZone: "UTC").as("createdYear"),
                .field("createdAt")
                    .timestampExtract(.week(startingOn: "monday"), timeZone: "UTC")
                    .as("createdWeek"),
                PipelineValue.constant(Timestamp(seconds: 1, nanos: 2)).as("literalTimestamp"),
                .field("createdAt").typeName().as("createdAtType"),
                .field("createdAt").isType("timestamp").as("isTimestamp"),
                PipelineValue.path("books/ada").as("pathValue"),
                PipelineValue.vector(.double(1.0), .field("score")).as("vectorValue"),
                PipelineValue.reference(author).collectionID().as("authorCollection"),
                PipelineValue.reference(author).documentID().as("authorID"),
                PipelineValue.reference(author).parentReference().as("authorParent"),
                PipelineValue.reference(author).referenceSlice(offset: 0, length: 1).as("authorRoot"),
                PipelineValue.reference(author)
                    .referenceSlice(offset: .field("offset"), length: .field("length"))
                    .as("dynamicAuthorSlice")
            ])

        let request = try PipelineCompiler(database: database).makeExecutePipelineRequest(pipeline: pipeline)
        let stages = request.structuredPipeline.pipeline.stages
        let selections = try Dictionary(uniqueKeysWithValues: stages[1].args.map { value -> (String, Google_Firestore_V1_Value) in
            let function = value.functionValue
            #expect(function.name == "as")
            let expression = try #require(function.args.first)
            let alias = try #require(function.args.last?.stringValue)
            return (alias, expression)
        })

        func function(_ alias: String) throws -> Google_Firestore_V1_Function {
            let value = try #require(selections[alias])
            return value.functionValue
        }

        #expect(stages.map(\.name) == ["collection", "select"])
        #expect(try function("fieldNames").name == "map_keys")
        #expect(try function("fieldNames").args[0].functionValue.name == "current_context")
        #expect(try function("titleEntries").name == "map_entries")
        #expect(try function("titleEntries").args[0].functionValue.name == "map")
        #expect(try function("hasPulitzer").name == "map_get")
        #expect(try function("updatedAwards").name == "map_set")
        #expect(try function("cleanAwards").name == "map_remove")
        #expect(try function("mergedProfile").name == "map_merge")
        #expect(try function("titleBytes").name == "byte_length")
        #expect(try function("titleChars").name == "char_length")
        #expect(try function("startsWithSwift").name == "starts_with")
        #expect(try function("startsWithSwift").args[0].functionValue.name == "to_lower")
        #expect(try function("endsWithGuide").name == "ends_with")
        #expect(try function("fictionGenre").name == "like")
        #expect(try function("regexContainsFire").name == "regex_contains")
        #expect(try function("regexMatchesCode").name == "regex_match")
        #expect(try function("fullName").name == "string_concat")
        #expect(try function("containsSwift").name == "string_contains")
        #expect(try function("swiftIndex").name == "string_index_of")
        #expect(try function("upperTitle").name == "to_upper")
        #expect(try function("titleSubstring").name == "substring")
        #expect(try function("reversedTitle").name == "string_reverse")
        #expect(try function("repeatedTitle").name == "string_repeat")
        #expect(try function("slug").name == "string_replace_all")
        #expect(try function("renamedTitle").name == "string_replace_one")
        #expect(try function("trimmedTitle").name == "trim")
        #expect(try function("leftTrimmedTitle").name == "ltrim")
        #expect(try function("rightTrimmedTitle").name == "rtrim")
        #expect(try function("splitTags").name == "split")
        #expect(try function("currentDay").name == "timestamp_trunc")
        #expect(try function("currentDay").args[0].functionValue.name == "current_timestamp")
        #expect(try function("currentWeek").name == "timestamp_trunc")
        #expect(try function("currentWeek").args[1].stringValue == "week(monday)")
        #expect(try function("createdAtFromMicros").name == "unix_micros_to_timestamp")
        #expect(try function("createdAtFromMillis").name == "unix_millis_to_timestamp")
        #expect(try function("createdAtFromSeconds").name == "unix_seconds_to_timestamp")
        #expect(try function("expiresAt").name == "timestamp_add")
        #expect(try function("expiresAt").args[1].stringValue == "day")
        #expect(try function("expiresAt").args[2].integerValue == 3653)
        #expect(try function("dynamicExpiresAt").name == "timestamp_add")
        #expect(try function("dynamicExpiresAt").args[2].fieldReferenceValue == "extensionDays")
        #expect(try function("warningAt").name == "timestamp_sub")
        #expect(try function("dynamicWarningAt").name == "timestamp_sub")
        #expect(try function("dynamicWarningAt").args[2].fieldReferenceValue == "graceDays")
        #expect(try function("createdAtMicros").name == "timestamp_to_unix_micros")
        #expect(try function("createdAtMillis").name == "timestamp_to_unix_millis")
        #expect(try function("createdAtSeconds").name == "timestamp_to_unix_seconds")
        #expect(try function("daysAlive").name == "timestamp_diff")
        #expect(try function("createdYear").name == "timestamp_extract")
        #expect(try function("createdYear").args[1].stringValue == "year")
        #expect(try function("createdYear").args[2].stringValue == "UTC")
        #expect(try function("createdWeek").name == "timestamp_extract")
        #expect(try function("createdWeek").args[1].stringValue == "week(monday)")
        #expect(try function("createdWeek").args[2].stringValue == "UTC")
        #expect(selections["literalTimestamp"]?.timestampValue.seconds == 1)
        #expect(selections["literalTimestamp"]?.timestampValue.nanos == 2)
        #expect(try function("createdAtType").name == "type")
        #expect(try function("isTimestamp").name == "is_type")
        #expect(try function("pathValue").name == "path")
        #expect(try function("pathValue").args[0].stringValue == "books/ada")
        #expect(try function("vectorValue").name == "vector")
        #expect(try function("vectorValue").args.count == 1)
        #expect(try function("vectorValue").args[0].arrayValue.values[0].doubleValue == 1.0)
        #expect(try function("vectorValue").args[0].arrayValue.values[1].fieldReferenceValue == "score")
        #expect(try function("authorCollection").name == "collection_id")
        #expect(try function("authorID").name == "document_id")
        #expect(try function("authorParent").name == "parent")
        #expect(try function("authorRoot").name == "reference_slice")
        #expect(try function("authorRoot").args[1].integerValue == 0)
        #expect(try function("authorRoot").args[2].integerValue == 1)
        #expect(try function("dynamicAuthorSlice").name == "reference_slice")
        #expect(try function("dynamicAuthorSlice").args[1].fieldReferenceValue == "offset")
        #expect(try function("dynamicAuthorSlice").args[2].fieldReferenceValue == "length")
    }

    @Test("PipelineCompiler encodes lambda control debugging and generic helpers")
    func testPipelineCompilerEncodesLambdaControlDebuggingAndGenericHelpers() throws {
        let database = Database(projectId: "test-project")
        let pipeline = FirestorePipeline()
            .collection("books")
            .select([
                .field("scores").arrayFilter { score in
                    score.greaterThan(1)
                }.as("passingScores"),
                .field("scores").arrayTransform { score in
                    score.multiply(2)
                }.as("doubledScores"),
                .field("scores").arrayTransform(element: "score", index: "index") { score, index in
                    score.add(index)
                }.as("indexedScores"),
                PipelineValue.switchOn(
                    [
                        PipelineSwitchCase(.field("rating").greaterThan(4), then: .string("high")),
                        PipelineSwitchCase(.field("rating").lessThan(2), then: .string("low"))
                    ],
                    default: .string("mid")
                ).as("ratingBand"),
                .field("rating").exists().as("hasRating"),
                .field("missing").isAbsent().as("missingAbsent"),
                .field("missing").ifAbsent(.string("fallback")).as("fallbackValue"),
                PipelineValue.error("forced").isError().as("isForcedError"),
                PipelineValue.error("forced").ifError(.string("caught")).as("caughtError"),
                PipelineValue.currentDocument().length().as("documentFieldCount"),
                PipelineValue.concat([.string("Author ID: "), .field("authorId")]).as("authorLabel"),
                .field("tags").length().as("tagCount"),
                .field("tags").genericReverse().as("reversedTags"),
                .field("ratings").maximum(3).as("topRatings"),
                .field("ratings").minimum(2).as("bottomRatings"),
                .field("rating").logicalMaximum([.int(1)]).as("flooredRating"),
                .field("rating").logicalMinimum([.int(5)]).as("cappedRating")
            ])

        let request = try PipelineCompiler(database: database).makeExecutePipelineRequest(pipeline: pipeline)
        let stages = request.structuredPipeline.pipeline.stages
        let selections = try Dictionary(uniqueKeysWithValues: stages[1].args.map { value -> (String, Google_Firestore_V1_Value) in
            let function = value.functionValue
            #expect(function.name == "as")
            let expression = try #require(function.args.first)
            let alias = try #require(function.args.last?.stringValue)
            return (alias, expression)
        })

        func function(_ alias: String) throws -> Google_Firestore_V1_Function {
            let value = try #require(selections[alias])
            return value.functionValue
        }

        let passingFilter = try function("passingScores")
        let passingLambda = passingFilter.args[1].functionValue
        let passingBody = passingLambda.args[1].functionValue
        let doubledTransform = try function("doubledScores")
        let indexedTransform = try function("indexedScores")
        let indexedLambda = indexedTransform.args[1].functionValue
        let switchFunction = try function("ratingBand")

        #expect(stages.map(\.name) == ["collection", "select"])
        #expect(passingFilter.name == "array_filter")
        #expect(passingLambda.name == "lambda")
        #expect(passingLambda.args[0].arrayValue.values.map(\.stringValue) == ["element"])
        #expect(passingBody.name == "greater_than")
        #expect(passingBody.args[0].variableReferenceValue == "element")
        #expect(doubledTransform.name == "array_transform")
        #expect(doubledTransform.args[1].functionValue.args[0].arrayValue.values.map(\.stringValue) == ["element"])
        #expect(indexedTransform.name == "array_transform")
        #expect(indexedLambda.args[0].arrayValue.values.map(\.stringValue) == ["score", "index"])
        #expect(indexedLambda.args[1].functionValue.name == "add")
        #expect(indexedLambda.args[1].functionValue.args[1].variableReferenceValue == "index")
        #expect(switchFunction.name == "switch_on")
        #expect(switchFunction.args.count == 5)
        #expect(switchFunction.args[0].functionValue.name == "greater_than")
        #expect(switchFunction.args[1].stringValue == "high")
        #expect(switchFunction.args[4].stringValue == "mid")
        #expect(try function("hasRating").name == "exists")
        #expect(try function("missingAbsent").name == "is_absent")
        #expect(try function("fallbackValue").name == "if_absent")
        #expect(try function("isForcedError").name == "is_error")
        #expect(try function("isForcedError").args[0].functionValue.name == "error")
        #expect(try function("caughtError").name == "if_error")
        #expect(try function("caughtError").args[0].functionValue.name == "error")
        #expect(try function("documentFieldCount").name == "length")
        #expect(try function("documentFieldCount").args[0].functionValue.name == "current_document")
        #expect(try function("authorLabel").name == "concat")
        #expect(try function("tagCount").name == "length")
        #expect(try function("reversedTags").name == "reverse")
        #expect(try function("topRatings").name == "maximum_n")
        #expect(try function("topRatings").args[1].integerValue == 3)
        #expect(try function("bottomRatings").name == "minimum_n")
        #expect(try function("bottomRatings").args[1].integerValue == 2)
        #expect(try function("flooredRating").name == "maximum")
        #expect(try function("cappedRating").name == "minimum")
    }

    @Test("PipelineCompiler encodes typed array helpers")
    func testPipelineCompilerEncodesTypedArrayHelpers() throws {
        let database = Database(projectId: "test-project")
        let pipeline = FirestorePipeline()
            .collection("books")
            .select([
                PipelineValue.arrayExpression([.field("title"), .field("subtitle")]).as("titleParts"),
                .field("tags").arrayConcat([.field("moreTags")]).as("allTags"),
                .field("tags").arrayContains(.string("swift")).as("hasSwiftTag"),
                .field("tags").arrayContainsAll([.string("swift"), .string("server")]).as("hasRequiredTags"),
                .field("tags").arrayContainsAny([.string("ios"), .string("admin")]).as("hasAnyTag"),
                .field("scores").arrayFirst().as("firstScore"),
                .field("scores").arrayFirst(.field("topCount")).as("topScores"),
                .field("scores").arrayGet(.field("index")).as("scoreAtIndex"),
                .field("scores").arrayIndex(of: .int(10)).as("scoreIndex"),
                .field("scores").arrayIndexes(of: .int(10)).as("scoreIndexes"),
                .field("scores").arrayLength().as("scoreCount"),
                .field("scores").arrayLast().as("lastScore"),
                .field("scores").arrayLast(.field("bottomCount")).as("bottomScores"),
                .field("scores").arrayReverse().as("reversedScores"),
                .field("scores").arraySlice(start: .field("windowStart"), end: .field("windowEnd")).as("scoreWindow"),
                .field("names").join(delimiter: ",", nullText: "unknown").as("namesText"),
                .field("ratings").maximum(.field("ratingLimit")).as("topRatings"),
                .field("ratings").minimum(.field("ratingLimit")).as("bottomRatings"),
                .field("scores").sum().as("scoreSum")
            ])

        let request = try PipelineCompiler(database: database).makeExecutePipelineRequest(pipeline: pipeline)
        let stages = request.structuredPipeline.pipeline.stages
        let selections = try Dictionary(uniqueKeysWithValues: stages[1].args.map { value -> (String, Google_Firestore_V1_Value) in
            let function = value.functionValue
            #expect(function.name == "as")
            let expression = try #require(function.args.first)
            let alias = try #require(function.args.last?.stringValue)
            return (alias, expression)
        })

        func function(_ alias: String) throws -> Google_Firestore_V1_Function {
            let value = try #require(selections[alias])
            return value.functionValue
        }

        #expect(stages.map(\.name) == ["collection", "select"])
        #expect(try function("titleParts").name == "array")
        #expect(try function("allTags").name == "array_concat")
        #expect(try function("hasSwiftTag").name == "array_contains")
        #expect(try function("hasRequiredTags").name == "array_contains_all")
        #expect(try function("hasAnyTag").name == "array_contains_any")
        #expect(try function("firstScore").name == "array_first")
        #expect(try function("topScores").name == "array_first_n")
        #expect(try function("topScores").args[1].fieldReferenceValue == "topCount")
        #expect(try function("scoreAtIndex").name == "array_get")
        #expect(try function("scoreAtIndex").args[1].fieldReferenceValue == "index")
        #expect(try function("scoreIndex").name == "array_index_of")
        #expect(try function("scoreIndexes").name == "array_index_of_all")
        #expect(try function("scoreCount").name == "array_length")
        #expect(try function("lastScore").name == "array_last")
        #expect(try function("bottomScores").name == "array_last_n")
        #expect(try function("bottomScores").args[1].fieldReferenceValue == "bottomCount")
        #expect(try function("reversedScores").name == "array_reverse")
        #expect(try function("scoreWindow").name == "array_slice")
        #expect(try function("scoreWindow").args[1].fieldReferenceValue == "windowStart")
        #expect(try function("scoreWindow").args[2].fieldReferenceValue == "windowEnd")
        #expect(try function("namesText").name == "join")
        #expect(try function("namesText").args[1].stringValue == ",")
        #expect(try function("namesText").args[2].stringValue == "unknown")
        #expect(try function("topRatings").name == "maximum_n")
        #expect(try function("topRatings").args[1].fieldReferenceValue == "ratingLimit")
        #expect(try function("bottomRatings").name == "minimum_n")
        #expect(try function("bottomRatings").args[1].fieldReferenceValue == "ratingLimit")
        #expect(try function("scoreSum").name == "sum")
    }

    @Test("PipelineResponseMapper maps pipeline explain stats")
    func testPipelineResponseMapperMapsPipelineExplainStats() throws {
        var stats = Google_Firestore_V1_ExplainStats()
        stats.data = try Google_Protobuf_Any(
            message: Google_Protobuf_StringValue.with {
                $0.value = #"{"indexes":["idx"]}"#
            }
        )
        let response = Google_Firestore_V1_ExecutePipelineResponse.with {
            $0.explainStats = stats
        }

        let result = try PipelineResponseMapper().makeExplainResult(
            from: [response],
            options: .explainJSON
        )

        #expect(result.snapshot == nil)
        #expect(result.stats.outputFormat == .json)
        #expect(result.stats.json == #"{"indexes":["idx"]}"#)
        #expect(result.stats.text == nil)
        #expect(result.stats.rawTypeURL?.contains("google.protobuf.StringValue") == true)
    }

    @Test("PipelineResponseMapper preserves result document metadata")
    func testPipelineResponseMapperPreservesResultDocumentMetadata() throws {
        let response = Google_Firestore_V1_ExecutePipelineResponse.with {
            $0.results = [
                Google_Firestore_V1_Document.with {
                    $0.name = "projects/test-project/databases/(default)/documents/reviewers/alice"
                    $0.fields["name"] = Google_Firestore_V1_Value.with {
                        $0.stringValue = "Alice"
                    }
                    $0.createTime = Google_Protobuf_Timestamp.with {
                        $0.seconds = 10
                        $0.nanos = 20
                    }
                    $0.updateTime = Google_Protobuf_Timestamp.with {
                        $0.seconds = 30
                        $0.nanos = 40
                    }
                }
            ]
        }

        let snapshot = try PipelineResponseMapper().makeSnapshot(from: [response])
        let row = try #require(snapshot.resultRows.first)
        let documentReference = try #require(row.documentReference)

        #expect(snapshot.rows.first?["name"] as? String == "Alice")
        #expect(row.data["name"] as? String == "Alice")
        #expect(documentReference.path == "reviewers/alice")
        #expect(row.createTime == Timestamp(seconds: 10, nanos: 20))
        #expect(row.updateTime == Timestamp(seconds: 30, nanos: 40))
    }

    @Test("PipelineResponseMapper rejects response document names outside runtime database")
    func testPipelineResponseMapperRejectsResponseDocumentNamesOutsideRuntimeDatabase() throws {
        let database = Database(projectId: "test-project")
        let runtime = ReadResponseMapperRuntime(database: database)
        let mapper = PipelineResponseMapper(runtime: runtime)
        let response = Google_Firestore_V1_ExecutePipelineResponse.with {
            $0.results = [
                Google_Firestore_V1_Document.with {
                    $0.name = "projects/other-project/databases/(default)/documents/reviewers/alice"
                }
            ]
        }

        do {
            _ = try mapper.makeSnapshot(from: [response])
            Issue.record("Expected Pipeline response database mismatch to throw.")
        } catch FirestoreError.databaseMismatch(let expected, let actual) {
            #expect(expected == "projects/test-project/databases/(default)")
            #expect(actual == "projects/other-project/databases/(default)")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("PipelineCompiler encodes typed aggregate and sort stages")
    func testPipelineCompilerEncodesTypedAggregateAndSortStages() throws {
        let database = Database(projectId: "test-project")
        let pipeline = FirestorePipeline()
            .collection("books")
            .where(.field("published").lessThan(1900))
            .sort([.field("published").descending()])
            .aggregate(
                [
                    .countAll().as("total"),
                    .field("rating").count().as("rated_books"),
                    .field("rating").greaterThan(4).countIf().as("highly_rated_books"),
                    .field("author").countDistinct().as("unique_authors"),
                    .field("rating").average().as("avg_rating"),
                    .field("price").sum().as("total_price"),
                    .field("price").minimum().as("min_price"),
                    .field("price").maximum().as("max_price"),
                    .field("title").first().as("first_title"),
                    .field("title").last().as("last_title"),
                    .field("tag").arrayAgg().as("tags"),
                    .field("tag").arrayAggDistinct().as("unique_tags")
                ],
                groups: [.field("genre").as("genre")]
            )

        let request = try PipelineCompiler(database: database).makeExecutePipelineRequest(pipeline: pipeline)
        let stages = request.structuredPipeline.pipeline.stages
        let sortOrdering = stages[2].args[0].functionValue
        let aggregateStage = stages[3]
        let aggregateOptions = aggregateStage.options["groups"]?.arrayValue.values ?? []

        #expect(stages.map(\.name) == ["collection", "where", "sort", "aggregate"])
        #expect(stages[1].args[0].functionValue.name == "less_than")
        #expect(sortOrdering.name == "descending")
        #expect(sortOrdering.args[0].fieldReferenceValue == "published")
        #expect(aggregateStage.args.map { $0.functionValue.name } == Array(repeating: "as", count: 12))
        #expect(aggregateStage.args.map { $0.functionValue.args[0].functionValue.name } == [
            "count",
            "count",
            "count_if",
            "count_distinct",
            "average",
            "sum",
            "minimum",
            "maximum",
            "first",
            "last",
            "array_agg",
            "array_agg_distinct"
        ])
        #expect(aggregateOptions.first?.functionValue.name == "as")
        #expect(aggregateOptions.first?.functionValue.args[0].fieldReferenceValue == "genre")
    }

    @Test("PipelineCompiler encodes typed document stages and expression helpers")
    func testPipelineCompilerEncodesTypedDocumentStagesAndExpressionHelpers() throws {
        let database = Database(projectId: "test-project")
        let sf = DocumentReference(database, parentPath: "cities", documentID: "SF")
        let ny = DocumentReference(database, parentPath: "cities", documentID: "NY")
        let unionPipeline = FirestorePipeline()
            .collection("archive")
            .where(.field("active").equal(true))
        let pipeline = FirestorePipeline()
            .documents([sf, ny])
            .addFields([
                .field("soldBooks").add(.field("unsoldBooks")).multiply(2).as("weightedInventory"),
                (.field("rating").greaterThan(4) && .field("price").lessThan(10)).as("recommended"),
                .field("genre").arrayContains(.string("mystery")).as("isMystery"),
                .field("genres").arrayContainsAll([.string("mystery"), .string("classic")]).as("hasRequiredGenres"),
                .field("genres").arrayContainsAny([.string("fiction"), .string("history")]).as("hasAnyGenre"),
                .field("genres").arrayLength().as("genreCount"),
                PipelineValue.conditional(
                    condition: .field("price").lessThan(10),
                    then: .string("cheap"),
                    else: .string("expensive")
                ).as("priceBand")
            ])
            .offset(2)
            .replaceWith(.map(["summary": .field("weightedInventory")]), mode: .mergeOverwriteExisting)
            .sample(count: 3)
            .unnest(.field("genres").as("genre"), indexField: "genreIndex")
            .union(with: unionPipeline)

        let request = try PipelineCompiler(database: database).makeExecutePipelineRequest(pipeline: pipeline)
        let stages = request.structuredPipeline.pipeline.stages
        let addFieldFunctions = stages[1].args.map { $0.functionValue.args[0].functionValue.name }
        let unionStages = stages[6].args[0].pipelineValue.stages

        #expect(stages.map(\.name) == [
            "documents",
            "add_fields",
            "offset",
            "replace_with",
            "sample",
            "unnest",
            "union"
        ])
        #expect(stages[0].args.map(\.referenceValue) == [
            "projects/test-project/databases/(default)/documents/cities/SF",
            "projects/test-project/databases/(default)/documents/cities/NY"
        ])
        #expect(addFieldFunctions == [
            "multiply",
            "and",
            "array_contains",
            "array_contains_all",
            "array_contains_any",
            "array_length",
            "conditional"
        ])
        #expect(stages[2].args.first?.integerValue == 2)
        #expect(stages[3].args[1].stringValue == "merge_overwrite_existing")
        #expect(stages[4].args.first?.integerValue == 3)
        #expect(stages[5].options["index_field"]?.stringValue == "genreIndex")
        #expect(unionStages.map(\.name) == ["collection", "where"])
    }

    @Test("PipelineCompiler encodes literal and percentage sample stages")
    func testPipelineCompilerEncodesLiteralAndPercentageSampleStages() throws {
        let database = Database(projectId: "test-project")
        let pipeline = FirestorePipeline()
            .literals([
                [
                    "rounded": .field("score").round(),
                    "roundedDynamic": .field("score").round(places: .field("precision")),
                    "truncatedDynamic": .field("score").trunc(places: .field("precision")),
                    "logBase": .field("score").log(base: 2),
                    "random": .rand()
                ]
            ])
            .sample(percentage: 0.5)

        let request = try PipelineCompiler(database: database).makeExecutePipelineRequest(pipeline: pipeline)
        let stages = request.structuredPipeline.pipeline.stages
        let literalFields = stages[0].args[0].mapValue.fields

        #expect(stages.map(\.name) == ["literals", "sample"])
        #expect(literalFields["rounded"]?.functionValue.name == "round")
        #expect(literalFields["roundedDynamic"]?.functionValue.name == "round")
        #expect(literalFields["roundedDynamic"]?.functionValue.args[1].fieldReferenceValue == "precision")
        #expect(literalFields["truncatedDynamic"]?.functionValue.name == "trunc")
        #expect(literalFields["truncatedDynamic"]?.functionValue.args[1].fieldReferenceValue == "precision")
        #expect(literalFields["logBase"]?.functionValue.name == "log")
        #expect(literalFields["logBase"]?.functionValue.args[1].integerValue == 2)
        #expect(literalFields["random"]?.functionValue.name == "rand")
        #expect(stages[1].options["percentage"]?.doubleValue == 0.5)
    }

    @Test("QueryCompiler compiles inclusive cursors")
    func testQueryCompilerCompilesInclusiveCursors() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "places",
            predicates: [
                .orderBy("geohash", false),
                .startAt(["9q9hv"]),
                .endAt(["9q9hw"])
            ]
        )

        let request = try QueryCompiler(query: query).makeRunQueryRequest()
        let structuredQuery = request.structuredQuery

        #expect(structuredQuery.hasStartAt)
        #expect(structuredQuery.hasEndAt)
        #expect(structuredQuery.startAt.values.first?.stringValue == "9q9hv")
        #expect(structuredQuery.startAt.before)
        #expect(structuredQuery.endAt.values.first?.stringValue == "9q9hw")
        #expect(!structuredQuery.endAt.before)
    }

    @Test("QueryCompiler compiles exclusive cursors")
    func testQueryCompilerCompilesExclusiveCursors() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "places",
            predicates: [
                .orderBy("geohash", false),
                .startAfter(["9q9hv"]),
                .endBefore(["9q9hw"])
            ]
        )

        let request = try QueryCompiler(query: query).makeRunQueryRequest()
        let structuredQuery = request.structuredQuery

        #expect(structuredQuery.startAt.values.first?.stringValue == "9q9hv")
        #expect(!structuredQuery.startAt.before)
        #expect(structuredQuery.endAt.values.first?.stringValue == "9q9hw")
        #expect(structuredQuery.endAt.before)
    }

    @Test("QueryCompiler rejects cursor without order")
    func testQueryCompilerRejectsCursorWithoutOrder() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "places",
            predicates: [.startAt(["9q9hv"])]
        )

        do {
            _ = try QueryCompiler(query: query).makeRunQueryRequest()
            Issue.record("Expected invalid query error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("orderBy"))
        }
    }

    @Test("QueryCompiler rejects cursor value overflow")
    func testQueryCompilerRejectsCursorValueOverflow() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "places",
            predicates: [
                .orderBy("geohash", false),
                .startAt(["9q9hv", "extra"])
            ]
        )

        do {
            _ = try QueryCompiler(query: query).makeRunQueryRequest()
            Issue.record("Expected invalid query error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("more values"))
        }
    }

    @Test("QueryCompiler compiles cursors with limitToLast by swapping bounds")
    func testQueryCompilerCompilesCursorsWithLimitToLastBySwappingBounds() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "places",
            predicates: [
                .orderBy("geohash", false),
                .startAt(["9q9hv"]),
                .endBefore(["9q9hw"]),
                .limitToLast(3)
            ]
        )

        let plan = try QueryCompiler(query: query).makeRunQueryPlan()
        let structuredQuery = plan.request.structuredQuery

        #expect(plan.requiresResultOrderReversal)
        #expect(structuredQuery.orderBy.map(\.field.fieldPath) == ["geohash"])
        #expect(structuredQuery.orderBy.map(\.direction) == [.descending])
        #expect(structuredQuery.limit.value == 3)
        #expect(structuredQuery.startAt.values.map(\.stringValue) == ["9q9hw"])
        #expect(!structuredQuery.startAt.before)
        #expect(structuredQuery.endAt.values.map(\.stringValue) == ["9q9hv"])
        #expect(!structuredQuery.endAt.before)
    }

    @Test("QueryCompiler rejects DNF disjunction overflow")
    func testQueryCompilerRejectsDNFDisjunctionOverflow() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: [
                .and([
                    .isIn("region", [1, 2, 3, 4, 5]),
                    .isIn("tier", [1, 2, 3, 4, 5, 6, 7])
                ])
            ]
        )

        do {
            _ = try QueryCompiler(query: query).makeRunQueryRequest()
            Issue.record("Expected invalid query error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("30"))
        }
    }

    @Test("QueryCompiler rejects empty disjunctive array filters")
    func testQueryCompilerRejectsEmptyDisjunctiveArrayFilters() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: [.isIn("region", [])]
        )

        do {
            _ = try QueryCompiler(query: query).makeRunQueryRequest()
            Issue.record("Expected invalid query error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("non-empty"))
        }
    }

    @Test("QueryCompiler rejects invalid notIn combinations")
    func testQueryCompilerRejectsInvalidNotInCombinations() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: [
                .isNotIn("region", [1, 2]),
                .isIn("tier", [1, 2])
            ]
        )

        do {
            _ = try QueryCompiler(query: query).makeRunQueryRequest()
            Issue.record("Expected invalid query error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("notIn"))
            #expect(message.contains("in"))
        }
    }

    @Test("QueryCompiler rejects oversized notIn values")
    func testQueryCompilerRejectsOversizedNotInValues() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: [.isNotIn("region", [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])]
        )

        do {
            _ = try QueryCompiler(query: query).makeRunQueryRequest()
            Issue.record("Expected invalid query error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("10"))
        }
    }

    @Test("QueryCompiler rejects multiple negative filters")
    func testQueryCompilerRejectsMultipleNegativeFilters() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: [
                .isNotEqualTo("status", "archived"),
                .isNotIn("region", [1, 2])
            ]
        )

        do {
            _ = try QueryCompiler(query: query).makeRunQueryRequest()
            Issue.record("Expected invalid query error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("single"))
        }
    }

    @Test("QueryCompiler rejects multiple array contains filters in one disjunction")
    func testQueryCompilerRejectsMultipleArrayContainsFiltersInOneDisjunction() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: [
                .and([
                    .arrayContains("regions", "west"),
                    .arrayContains("roles", "admin")
                ])
            ]
        )

        do {
            _ = try QueryCompiler(query: query).makeRunQueryRequest()
            Issue.record("Expected invalid query error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("arrayContains"))
        }
    }

    @Test("QueryCompiler allows array contains filters in separate OR disjunctions")
    func testQueryCompilerAllowsArrayContainsFiltersInSeparateOrDisjunctions() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: [
                .or([
                    .arrayContains("regions", "west"),
                    .arrayContains("roles", "admin")
                ])
            ]
        )

        let request = try QueryCompiler(query: query).makeRunQueryRequest()

        #expect(request.structuredQuery.where.compositeFilter.op == .or)
        #expect(request.structuredQuery.where.compositeFilter.filters.count == 2)
    }

    @Test("QueryCompiler rejects array membership conflicts inside nested disjunctions")
    func testQueryCompilerRejectsArrayMembershipConflictsInsideNestedDisjunctions() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: [
                .or([
                    .and([
                        .arrayContains("regions", "west"),
                        .arrayContainsAny("roles", ["admin", "owner"])
                    ]),
                    .isEqualTo("active", true)
                ])
            ]
        )

        do {
            _ = try QueryCompiler(query: query).makeRunQueryRequest()
            Issue.record("Expected invalid query error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("arrayContains"))
            #expect(message.contains("arrayContainsAny"))
        }
    }

    @Test("QueryCompiler rejects notIn inside explicit OR filters")
    func testQueryCompilerRejectsNotInInsideExplicitORFilters() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: [
                .or([
                    .isNotIn("region", ["north", "south"]),
                    .isEqualTo("active", true)
                ])
            ]
        )

        do {
            _ = try QueryCompiler(query: query).makeRunQueryRequest()
            Issue.record("Expected invalid query error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("notIn"))
            #expect(message.contains("OR"))
        }
    }

    @Test("QueryCompiler rejects first order mismatch for inequality filters")
    func testQueryCompilerRejectsFirstOrderMismatchForInequalityFilters() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: [
                .isGreaterThan("age", 18),
                .orderBy("name", false)
            ]
        )

        do {
            _ = try QueryCompiler(query: query).makeRunQueryRequest()
            Issue.record("Expected invalid query error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("first orderBy"))
        }
    }

    @Test("QueryCompiler allows implied inequality order")
    func testQueryCompilerAllowsImpliedInequalityOrder() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: [.isGreaterThan("age", 18)]
        )

        let request = try QueryCompiler(query: query).makeRunQueryRequest()

        #expect(request.structuredQuery.where.fieldFilter.field.fieldPath == "age")
        #expect(request.structuredQuery.orderBy.isEmpty)
    }

    @Test("QueryCompiler rejects too many inequality fields")
    func testQueryCompilerRejectsTooManyInequalityFields() throws {
        let database = Database(projectId: "test-project")
        let predicates = (0..<11).map { index in
            QueryPredicate.isGreaterThan("field\(index)", index)
        }
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: predicates
        )

        do {
            _ = try QueryCompiler(query: query).makeRunQueryRequest()
            Issue.record("Expected invalid query error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("10"))
        }
    }

    @Test("QueryCompiler rejects filter sort and path component overflow")
    func testQueryCompilerRejectsFilterSortAndPathComponentOverflow() throws {
        let database = Database(projectId: "test-project")
        var predicates = (0..<99).map { index in
            QueryPredicate.isEqualTo("field\(index)", index)
        }
        predicates.append(.orderBy("name", false))
        predicates.append(.orderBy("createdAt", false))
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: predicates
        )

        do {
            _ = try QueryCompiler(query: query).makeRunQueryRequest()
            Issue.record("Expected invalid query error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("100"))
        }
    }

    @Test("FieldPath encodes and parses quoted segments")
    func testFieldPathEncodesAndParsesQuotedSegments() throws {
        let encodedFieldPath = try FieldPath(["profile.name", "bak`tik", #"a\b"#]).rpcFieldPath()

        #expect(encodedFieldPath == #"`profile.name`.`bak\`tik`.`a\\b`"#)
        #expect(try FirestoreFieldPath.split(encodedFieldPath) == ["profile.name", "bak`tik", #"a\b"#])
    }

    @Test("QueryCompiler encodes typed FieldPath field names")
    func testQueryCompilerEncodesTypedFieldPathFieldNames() throws {
        let database = Database(projectId: "test-project")
        let query = try Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: []
        )
        .whereField(FieldPath(["profile.name"]), isEqualTo: "Ada")

        let request = try QueryCompiler(query: query).makeRunQueryRequest()

        #expect(request.structuredQuery.where.fieldFilter.field.fieldPath == "`profile.name`")
        #expect(request.structuredQuery.where.fieldFilter.value.stringValue == "Ada")
    }

    @Test("QueryCompiler maps FieldPath documentID to reference values")
    func testQueryCompilerMapsFieldPathDocumentIDToReferenceValues() throws {
        let database = Database(projectId: "test-project")
        let query = try Query(
            database,
            parentPath: "organizations/org123",
            collectionID: "users",
            predicates: []
        )
        .whereField(FieldPath.documentID(), isEqualTo: "user123")

        let request = try QueryCompiler(query: query).makeRunQueryRequest()
        let filter = request.structuredQuery.where.fieldFilter

        #expect(filter.field.fieldPath == "__name__")
        #expect(filter.value.referenceValue == "projects/test-project/databases/(default)/documents/organizations/org123/users/user123")
    }

    @Test("QueryPredicateFilterCompiler builds document ID reference filters")
    func testQueryPredicateFilterCompilerBuildsDocumentIDReferenceFilters() throws {
        let database = Database(projectId: "test-project")
        let compiler = QueryPredicateFilterCompiler(
            database: database,
            parentPath: nil,
            collectionID: "reviews",
            allDescendants: true
        )

        let filter = try #require(
            try compiler.makeFilter(
                from: .isInDocumentID([
                    "organizations/org123/reviews/review123",
                    "organizations/org456/reviews/review456"
                ])
            )
        )
        let valueReferences = filter.fieldFilter.value.arrayValue.values.map(\.referenceValue)

        #expect(filter.fieldFilter.field.fieldPath == "__name__")
        #expect(filter.fieldFilter.op == .in)
        #expect(valueReferences == [
            "projects/test-project/databases/(default)/documents/organizations/org123/reviews/review123",
            "projects/test-project/databases/(default)/documents/organizations/org456/reviews/review456"
        ])
        #expect(try compiler.makeFilter(from: .orderBy("name", false)) == nil)
    }

    @Test("DocumentRequestCompiler builds document read requests")
    func testDocumentRequestCompilerBuildsDocumentReadRequests() throws {
        let database = Database(projectId: "test-project")
        let compiler = DocumentRequestCompiler(database: database)
        let firstReference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let secondReference = DocumentReference(database, parentPath: "users", documentID: "missing")

        let getRequest = try compiler.makeGetDocumentRequest(for: firstReference)
        let batchGetRequest = try compiler.makeBatchGetDocumentsRequest(
            for: [firstReference, secondReference],
            transactionID: Data([1, 2, 3])
        )
        let listCollectionIdsRequest = try compiler.makeListCollectionIdsRequest(
            parent: firstReference,
            pageToken: "next-page"
        )
        let nestedCollection = CollectionReference(
            database,
            parentPath: "organizations/org123",
            collectionID: "users"
        )
        let listDocumentsRequest = try compiler.makeListDocumentsRequest(
            in: nestedCollection,
            pageSize: 25,
            pageToken: "documents-page",
            readTime: Timestamp(seconds: 123, nanos: 456)
        )

        #expect(getRequest.name == "projects/test-project/databases/(default)/documents/users/user123")
        #expect(batchGetRequest.database == "projects/test-project/databases/(default)")
        #expect(batchGetRequest.documents == [
            "projects/test-project/databases/(default)/documents/users/user123",
            "projects/test-project/databases/(default)/documents/users/missing"
        ])
        #expect(batchGetRequest.transaction == Data([1, 2, 3]))
        #expect(listCollectionIdsRequest.parent == "projects/test-project/databases/(default)/documents/users/user123")
        #expect(listCollectionIdsRequest.pageToken == "next-page")
        #expect(listDocumentsRequest.parent == "projects/test-project/databases/(default)/documents/organizations/org123")
        #expect(listDocumentsRequest.collectionID == "users")
        #expect(listDocumentsRequest.pageSize == 25)
        #expect(listDocumentsRequest.pageToken == "documents-page")
        #expect(listDocumentsRequest.showMissing)
        #expect(listDocumentsRequest.readTime.seconds == 123)
        #expect(listDocumentsRequest.readTime.nanos == 456)
    }

    @Test("DocumentRequestCompiler rejects references outside its database")
    func testDocumentRequestCompilerRejectsReferencesOutsideItsDatabase() throws {
        let expectedDatabase = Database(projectId: "expected-project")
        let actualDatabase = Database(projectId: "actual-project")
        let compiler = DocumentRequestCompiler(database: expectedDatabase)
        let expectedReference = DocumentReference(expectedDatabase, parentPath: "users", documentID: "user123")
        let actualReference = DocumentReference(actualDatabase, parentPath: "users", documentID: "user456")

        var batchGetDidThrow = false
        do {
            _ = try compiler.makeBatchGetDocumentsRequest(for: [expectedReference, actualReference])
        } catch FirestoreError.databaseMismatch(let expected, let actual) {
            batchGetDidThrow = expected == expectedDatabase.database
                && actual == actualDatabase.database
        } catch {
            batchGetDidThrow = false
        }

        #expect(throws: FirestoreError.self) {
            _ = try compiler.makeGetDocumentRequest(for: actualReference)
        }
        #expect(throws: FirestoreError.self) {
            _ = try compiler.makeListCollectionIdsRequest(parent: actualReference)
        }
        #expect(throws: FirestoreError.self) {
            _ = try compiler.makeListDocumentsRequest(
                in: CollectionReference(actualDatabase, parentPath: nil, collectionID: "users")
            )
        }
        #expect(batchGetDidThrow)
    }

    @Test("DocumentRequestCompiler rejects invalid ListDocuments page size")
    func testDocumentRequestCompilerRejectsInvalidListDocumentsPageSize() throws {
        let database = Database(projectId: "test-project")
        let collection = CollectionReference(database, parentPath: nil, collectionID: "users")
        let compiler = DocumentRequestCompiler(database: database)

        do {
            _ = try compiler.makeListDocumentsRequest(in: collection, pageSize: -1)
            Issue.record("Expected invalid page size error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("pageSize"))
        }

        do {
            _ = try compiler.makeListDocumentsRequest(in: collection, pageSize: Int(Int32.max) + 1)
            Issue.record("Expected Int32 range error")
        } catch FirestoreError.invalidQuery(let message) {
            #expect(message.contains("Int32"))
        }
    }

    @Test("TransactionRequestCompiler builds begin and rollback requests")
    func testTransactionRequestCompilerBuildsBeginAndRollbackRequests() throws {
        let database = Database(projectId: "test-project")
        let compiler = TransactionRequestCompiler(database: database)

        let readWriteRequest = compiler.makeBeginTransactionRequest(
            readOnly: false,
            readTime: nil,
            retryTransactionID: Data([9, 8])
        )
        let readOnlyRequest = compiler.makeBeginTransactionRequest(
            readOnly: true,
            readTime: Timestamp(seconds: 123, nanos: 456),
            retryTransactionID: Data([7, 6])
        )
        let rollbackRequest = compiler.makeRollbackRequest(transactionID: Data([5, 4]))

        #expect(readWriteRequest.database == "projects/test-project/databases/(default)")
        #expect(readWriteRequest.options.readWrite.retryTransaction == Data([9, 8]))
        #expect(readWriteRequest.options.readWrite.concurrencyMode == .optimistic)
        #expect(readOnlyRequest.database == "projects/test-project/databases/(default)")
        #expect(readOnlyRequest.options.readOnly.readTime.seconds == 123)
        #expect(readOnlyRequest.options.readOnly.readTime.nanos == 456)
        #expect(readOnlyRequest.options.readWrite.retryTransaction.isEmpty)
        #expect(rollbackRequest.database == "projects/test-project/databases/(default)")
        #expect(rollbackRequest.transaction == Data([5, 4]))
    }

    @Test("WriteCompiler builds update mask and precondition")
    func testWriteCompilerBuildsUpdateMaskAndPrecondition() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: ["name": "Ada", "age": 37],
            merge: true,
            exist: true
        )

        let request = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
        let write = request.writes[0]

        #expect(request.database == "projects/test-project/databases/(default)")
        #expect(write.update.name == "projects/test-project/databases/(default)/documents/users/user123")
        #expect(write.updateMask.fieldPaths.sorted() == ["age", "name"])
        #expect(write.currentDocument.exists == true)
    }

    @Test("BatchWriteCompiler builds non-atomic write requests")
    func testBatchWriteCompilerBuildsNonAtomicWriteRequests() throws {
        let database = Database(projectId: "test-project")
        let firstReference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let secondReference = DocumentReference(database, parentPath: "users", documentID: "user456")
        let request = try BatchWriteCompiler(database: database).makeBatchWriteRequest(
            writes: [
                WriteData(
                    documentReference: firstReference,
                    data: ["name": "Ada"],
                    merge: false,
                    mergeFields: nil,
                    exist: false
                ),
                WriteData(
                    documentReference: secondReference,
                    data: nil,
                    merge: false,
                    mergeFields: nil,
                    exist: nil
                )
            ],
            labels: ["job": "backfill"]
        )

        #expect(request.database == "projects/test-project/databases/(default)")
        #expect(request.labels == ["job": "backfill"])
        #expect(request.writes.count == 2)
        #expect(request.writes[0].update.name == "projects/test-project/databases/(default)/documents/users/user123")
        #expect(request.writes[0].currentDocument.exists == false)
        #expect(request.writes[1].delete == "projects/test-project/databases/(default)/documents/users/user456")
    }

    @Test("BatchWriteCompiler rejects duplicate document writes")
    func testBatchWriteCompilerRejectsDuplicateDocumentWrites() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let write = WriteData(
            documentReference: reference,
            data: ["name": "Ada"],
            merge: false,
            mergeFields: nil,
            exist: nil
        )

        do {
            _ = try BatchWriteCompiler(database: database).makeBatchWriteRequest(writes: [write, write])
            Issue.record("Expected duplicate document error")
        } catch FirestoreError.invalidOperation(let message) {
            #expect(message.contains("same document"))
        }
    }

    @Test("BatchWriteResponseMapper returns per-write statuses")
    func testBatchWriteResponseMapperReturnsPerWriteStatuses() throws {
        let database = Database(projectId: "test-project")
        let firstReference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let secondReference = DocumentReference(database, parentPath: "users", documentID: "user456")
        let writes = [
            WriteData(
                documentReference: firstReference,
                data: ["name": "Ada"],
                merge: false,
                mergeFields: nil,
                exist: nil
            ),
            WriteData(
                documentReference: secondReference,
                data: ["name": "Grace"],
                merge: false,
                mergeFields: nil,
                exist: nil
            )
        ]
        let response = Google_Firestore_V1_BatchWriteResponse.with {
            $0.writeResults = [
                Google_Firestore_V1_WriteResult.with {
                    $0.updateTime = Google_Protobuf_Timestamp.with {
                        $0.seconds = 123
                        $0.nanos = 456
                    }
                },
                Google_Firestore_V1_WriteResult()
            ]
            $0.status = [
                Google_Rpc_Status(),
                Google_Rpc_Status.with {
                    $0.code = Int32(FirestoreErrorCode.permissionDenied.rawValue)
                    $0.message = "denied"
                }
            ]
        }

        let result = try BatchWriteResponseMapper().makeResult(
            documentReferences: writes.map(\.documentReference),
            response: response
        )

        #expect(result.results.count == 2)
        #expect(result.succeeded.map(\.document) == [firstReference])
        #expect(result.failed.map(\.document) == [secondReference])
        #expect(result.results[0].updateTime == Timestamp(seconds: 123, nanos: 456))
        #expect(result.results[0].error == nil)
        #expect(result.results[1].updateTime == nil)
        #expect(result.results[1].error?.code == .permissionDenied)
        #expect(result.results[1].error?.message == "denied")
    }

    @Test("WriteCompiler builds create precondition")
    func testWriteCompilerBuildsCreatePrecondition() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: ["name": "Ada"],
            merge: false,
            exist: false
        )

        let request = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
        let write = request.writes[0]

        #expect(write.update.name == "projects/test-project/databases/(default)/documents/users/user123")
        #expect(write.update.fields["name"]?.stringValue == "Ada")
        #expect(write.currentDocument.exists == false)
        #expect(!write.hasUpdateMask)
    }

    @Test("WriteCompiler excludes transforms from update masks")
    func testWriteCompilerExcludesTransformsFromUpdateMasks() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: [
                "count": FieldValue.increment(1),
                "name": "Ada",
                "removed": FieldValue.delete,
                "tags": FieldValue.arrayUnion(["admin"]),
                "updatedAt": FieldValue.serverTimestamp
            ],
            merge: true,
            exist: true
        )

        let request = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
        let write = request.writes[0]

        #expect(write.update.fields["count"] == nil)
        #expect(write.update.fields["tags"] == nil)
        #expect(write.update.fields["updatedAt"] == nil)
        #expect(write.update.fields["name"]?.stringValue == "Ada")
        #expect(write.updateMask.fieldPaths.sorted() == ["name", "removed"])
        #expect(write.updateTransforms.map(\.fieldPath).sorted() == ["count", "tags", "updatedAt"])
    }

    @Test("WriteCompiler preserves integer and double increment value types")
    func testWriteCompilerPreservesIncrementValueTypes() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: [
                "loginCount": FieldValue.increment(1),
                "score": FieldValue.increment(1.5)
            ],
            merge: true,
            exist: true
        )

        let request = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
        let transforms = Dictionary(uniqueKeysWithValues: request.writes[0].updateTransforms.map { transform in
            (transform.fieldPath, transform.increment)
        })

        #expect(transforms["loginCount"]?.integerValue == 1)
        #expect(transforms["score"]?.doubleValue == 1.5)
    }

    @Test("WriteCompiler encodes Codable server timestamp wrapper")
    func testWriteCompilerEncodesCodableServerTimestampWrapper() throws {
        struct User: Codable {
            @ServerTimestamp var updatedAt: Timestamp?
        }

        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: try FirestoreEncoder().encode(User()),
            merge: true
        )

        let request = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
        let write = request.writes[0]

        #expect(write.update.fields["updatedAt"] == nil)
        #expect(write.updateMask.fieldPaths.isEmpty)
        #expect(write.updateTransforms.first?.fieldPath == "updatedAt")
        #expect(write.updateTransforms.first?.setToServerValue == .requestTime)
    }

    @Test("WriteCompiler excludes explicit merge transform fields from update masks")
    func testWriteCompilerExcludesExplicitMergeTransformFieldsFromUpdateMasks() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: [
                "count": FieldValue.increment(1),
                "name": "Ada"
            ],
            merge: true,
            mergeFields: ["count", "name"]
        )

        let request = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
        let write = request.writes[0]

        #expect(write.updateMask.fieldPaths == ["name"])
        #expect(write.updateTransforms.map(\.fieldPath) == ["count"])
    }

    @Test("WriteCompiler ignores transforms outside explicit merge fields")
    func testWriteCompilerIgnoresTransformsOutsideExplicitMergeFields() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: [
                "count": FieldValue.increment(1),
                "name": "Ada"
            ],
            merge: true,
            mergeFields: ["name"]
        )

        let request = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
        let write = request.writes[0]

        #expect(write.updateMask.fieldPaths == ["name"])
        #expect(write.updateTransforms.isEmpty)
    }

    @Test("WriteCompiler keeps transforms under explicit parent merge fields")
    func testWriteCompilerKeepsTransformsUnderExplicitParentMergeFields() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: [
                "profile": [
                    "name": "Ada",
                    "updatedAt": FieldValue.serverTimestamp
                ]
            ],
            merge: true,
            mergeFields: ["profile"]
        )

        let request = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
        let write = request.writes[0]

        #expect(write.updateMask.fieldPaths == ["profile"])
        #expect(write.update.fields["profile"]?.mapValue.fields["name"]?.stringValue == "Ada")
        #expect(write.update.fields["profile"]?.mapValue.fields["updatedAt"] == nil)
        #expect(write.updateTransforms.map(\.fieldPath) == ["profile.updatedAt"])
    }

    @Test("WriteCompiler rejects explicit merge fields without data values")
    func testWriteCompilerRejectsExplicitMergeFieldsWithoutDataValues() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: ["name": "Ada"],
            merge: true,
            mergeFields: ["profile.name"]
        )

        do {
            _ = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
            Issue.record("Expected missing merge field value error")
        } catch FirestoreError.invalidFieldPath(let message) {
            #expect(message.contains("without a corresponding value"))
        }
    }

    @Test("WriteCompiler encodes FirestoreVector fields")
    func testWriteCompilerEncodesFirestoreVectorFields() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "cities", documentID: "SF")
        let writeData = WriteData(
            documentReference: reference,
            data: ["embedding": FirestoreVector([1.0, 2.0, 3.0])],
            merge: false
        )

        let request = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
        let embedding = try #require(request.writes.first?.update.fields["embedding"])

        #expect(embedding.arrayValue.values.map(\.doubleValue) == [1.0, 2.0, 3.0])
    }

    @Test("WriteCompiler encodes FieldValue vector helper fields")
    func testWriteCompilerEncodesFieldValueVectorHelperFields() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "cities", documentID: "SF")
        let writeData = WriteData(
            documentReference: reference,
            data: ["embedding": FieldValue.vector([1.0, 2.0, 3.0])],
            merge: false
        )

        let request = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
        let embedding = try #require(request.writes.first?.update.fields["embedding"])

        #expect(embedding.arrayValue.values.map(\.doubleValue) == [1.0, 2.0, 3.0])
    }

    @Test("WriteCompiler builds delete write")
    func testWriteCompilerBuildsDeleteWrite() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: nil,
            merge: false
        )

        let request = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])

        #expect(request.writes[0].delete == "projects/test-project/databases/(default)/documents/users/user123")
    }

    @Test("WriteCompiler builds recursive merge mask")
    func testWriteCompilerBuildsRecursiveMergeMask() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: [
                "active": true,
                "profile": [
                    "name": "Ada",
                    "age": FieldValue.delete
                ]
            ],
            merge: true
        )

        let request = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
        let write = request.writes[0]

        #expect(write.update.fields["active"]?.booleanValue == true)
        #expect(write.update.fields["profile"]?.mapValue.fields["name"]?.stringValue == "Ada")
        #expect(write.update.fields["profile"]?.mapValue.fields["age"] == nil)
        #expect(write.updateMask.fieldPaths == ["active", "profile.age", "profile.name"])
    }

    @Test("WriteCompiler interprets updateData keys as field paths")
    func testWriteCompilerInterpretsUpdateDataKeysAsFieldPaths() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: [
                "profile.name": "Ada",
                "profile.rank": 1
            ],
            merge: true,
            exist: true
        )

        let request = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
        let write = request.writes[0]

        #expect(write.update.fields["profile"]?.mapValue.fields["name"]?.stringValue == "Ada")
        #expect(write.update.fields["profile"]?.mapValue.fields["rank"]?.integerValue == 1)
        #expect(write.updateMask.fieldPaths == ["profile.name", "profile.rank"])
        #expect(write.currentDocument.exists == true)
    }

    @Test("WriteCompiler interprets typed FieldPath update keys as literal field names")
    func testWriteCompilerInterpretsTypedFieldPathUpdateKeysAsLiteralFieldNames() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: try FirestoreFieldPath.encodeFieldPathDictionary([
                FieldPath(["profile.name"]): "Ada"
            ]),
            merge: true,
            exist: true
        )

        let request = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
        let write = request.writes[0]

        #expect(write.update.fields["profile.name"]?.stringValue == "Ada")
        #expect(write.updateMask.fieldPaths == ["`profile.name`"])
    }

    @Test("WriteCompiler encodes merge mask for literal dotted field names")
    func testWriteCompilerEncodesMergeMaskForLiteralDottedFieldNames() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: ["profile.name": "Ada"],
            merge: true
        )

        let request = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
        let write = request.writes[0]

        #expect(write.update.fields["profile.name"]?.stringValue == "Ada")
        #expect(write.updateMask.fieldPaths == ["`profile.name`"])
    }

    @Test("WriteCompiler rejects invalid field path keys")
    func testWriteCompilerRejectsInvalidFieldPathKeys() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: ["`unterminated": "Ada"],
            merge: true,
            exist: true
        )

        do {
            _ = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
            Issue.record("Expected invalid field path error")
        } catch FirestoreError.invalidFieldPath(let message) {
            #expect(message.contains("not closed"))
        }
    }

    @Test("WriteCompiler rejects conflicting update field paths")
    func testWriteCompilerRejectsConflictingUpdateFieldPaths() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: [
                "profile": ["rank": 1],
                "profile.name": "Ada"
            ],
            merge: true,
            exist: true
        )

        do {
            _ = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
            Issue.record("Expected conflicting update field path error")
        } catch FirestoreError.invalidFieldPath(let message) {
            #expect(message.contains("conflicting field paths"))
        }
    }

    @Test("WriteCompiler rejects duplicate normalized update field paths")
    func testWriteCompilerRejectsDuplicateNormalizedUpdateFieldPaths() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: [
                "profile.name": "Ada",
                "profile.`name`": "Grace"
            ],
            merge: true,
            exist: true
        )

        do {
            _ = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
            Issue.record("Expected duplicate update field path error")
        } catch FirestoreError.invalidFieldPath(let message) {
            #expect(message.contains("duplicate field path"))
        }
    }

    @Test("WriteCompiler rejects reserved update field path keys")
    func testWriteCompilerRejectsReservedUpdateFieldPathKeys() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: ["__name__": "users/user123"],
            merge: true,
            exist: true
        )

        do {
            _ = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
            Issue.record("Expected reserved field path error")
        } catch FirestoreError.invalidFieldPath(let message) {
            #expect(message.contains("reserved Firestore field name"))
        }
    }

    @Test("WriteCompiler rejects reserved merge field paths")
    func testWriteCompilerRejectsReservedMergeFieldPaths() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: ["name": "Ada"],
            merge: true,
            mergeFields: ["__name__"]
        )

        do {
            _ = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
            Issue.record("Expected reserved merge field path error")
        } catch FirestoreError.invalidFieldPath(let message) {
            #expect(message.contains("reserved Firestore field name"))
        }
    }

    @Test("WriteCompiler rejects conflicting merge field paths")
    func testWriteCompilerRejectsConflictingMergeFieldPaths() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: [
                "profile": [
                    "name": "Ada",
                    "rank": 1
                ]
            ],
            merge: true,
            mergeFields: ["profile", "profile.name"]
        )

        do {
            _ = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
            Issue.record("Expected conflicting merge field path error")
        } catch FirestoreError.invalidFieldPath(let message) {
            #expect(message.contains("conflicting field paths"))
        }
    }

    @Test("WriteCompiler preserves explicit merge fields")
    func testWriteCompilerPreservesExplicitMergeFields() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: [
                "profile": [
                    "name": "Ada",
                    "rank": 1
                ]
            ],
            merge: true,
            mergeFields: ["profile.name"]
        )

        let request = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])

        #expect(request.writes[0].updateMask.fieldPaths == ["profile.name"])
    }

    @Test("WriteCompiler rejects delete sentinel without merge or update")
    func testWriteCompilerRejectsDeleteSentinelWithoutMergeOrUpdate() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: ["name": "Ada", "removed": FieldValue.delete],
            merge: false
        )

        do {
            _ = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
            Issue.record("Expected invalid field value error")
        } catch FirestoreError.invalidFieldValue(let message) {
            #expect(message.contains("FieldValue.delete"))
        }
    }

    @Test("WriteCompiler rejects sentinel inside array field")
    func testWriteCompilerRejectsSentinelInsideArrayField() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: ["values": ["swift", FieldValue.serverTimestamp]],
            merge: true
        )

        do {
            _ = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
            Issue.record("Expected invalid field value error")
        } catch FirestoreError.invalidFieldValue(let message) {
            #expect(message.contains("inside arrays"))
        }
    }

    @Test("WriteCompiler rejects sentinel nested inside array map")
    func testWriteCompilerRejectsSentinelNestedInsideArrayMap() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: ["values": [["updatedAt": FieldValue.serverTimestamp]]],
            merge: true
        )

        do {
            _ = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
            Issue.record("Expected invalid field value error")
        } catch FirestoreError.invalidFieldValue(let message) {
            #expect(message.contains("inside arrays"))
        }
    }

    @Test("WriteCompiler rejects sentinel inside array transform elements")
    func testWriteCompilerRejectsSentinelInsideArrayTransformElements() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: ["values": FieldValue.arrayUnion([["updatedAt": FieldValue.serverTimestamp]])],
            merge: true
        )

        do {
            _ = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
            Issue.record("Expected invalid field value error")
        } catch FirestoreError.invalidFieldValue(let message) {
            #expect(message.contains("inside arrays"))
        }
    }

    @Test("WriteCompiler rejects directly nested array field")
    func testWriteCompilerRejectsDirectlyNestedArrayField() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: ["values": [["nested"]]],
            merge: true
        )

        do {
            _ = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
            Issue.record("Expected invalid field value error")
        } catch FirestoreError.invalidFieldValue(let message) {
            #expect(message.contains("directly contain arrays"))
        }
    }

    @Test("WriteCompiler allows arrays inside maps inside arrays")
    func testWriteCompilerAllowsArraysInsideMapsInsideArrays() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: ["values": [["nested": ["swift", "server"]]]],
            merge: true
        )

        let request = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
        let nestedValues = request.writes[0]
            .update
            .fields["values"]?
            .arrayValue
            .values
            .first?
            .mapValue
            .fields["nested"]?
            .arrayValue
            .values
            .map(\.stringValue)

        #expect(nestedValues == ["swift", "server"])
    }

    @Test("WriteCompiler rejects unsupported field value type")
    func testWriteCompilerRejectsUnsupportedFieldValueType() throws {
        struct UnsupportedValue {}
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let writeData = WriteData(
            documentReference: reference,
            data: ["unsupported": UnsupportedValue()],
            merge: true
        )

        do {
            _ = try WriteCompiler(database: database).makeCommitRequest(writes: [writeData])
            Issue.record("Expected invalid field value error")
        } catch FirestoreError.invalidFieldValue(let message) {
            #expect(message.contains("Unsupported Firestore value type"))
        }
    }

    @Test("QueryCompiler rejects unsupported predicate value type")
    func testQueryCompilerRejectsUnsupportedPredicateValueType() throws {
        struct UnsupportedValue {}
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: [.isEqualTo("profile", UnsupportedValue())]
        )

        do {
            _ = try QueryCompiler(query: query).makeRunQueryRequest()
            Issue.record("Expected invalid field value error")
        } catch FirestoreError.invalidFieldValue(let message) {
            #expect(message.contains("Unsupported Firestore value type"))
        }
    }

    @Test("QueryCompiler rejects sentinel predicate value")
    func testQueryCompilerRejectsSentinelPredicateValue() throws {
        let database = Database(projectId: "test-project")
        let query = Query(
            database,
            parentPath: nil,
            collectionID: "users",
            predicates: [.isEqualTo("updatedAt", FieldValue.serverTimestamp)]
        )

        do {
            _ = try QueryCompiler(query: query).makeRunQueryRequest()
            Issue.record("Expected invalid field value error")
        } catch FirestoreError.invalidFieldValue(let message) {
            #expect(message.contains("FieldValue sentinels"))
        }
    }

    @Test("ListenTargetBuilder uses supplied target ID")
    func testListenTargetBuilderUsesSuppliedTargetID() throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let query = Query(database, parentPath: nil, collectionID: "users", predicates: [])
        let builder = ListenTargetBuilder()

        let documentTarget = builder.makeDocumentTarget(for: reference, targetID: 41)
        let queryTarget = try builder.makeQueryTarget(for: query, targetID: 42)

        #expect(documentTarget.targetID == 41)
        #expect(documentTarget.documents.documents == ["projects/test-project/databases/(default)/documents/users/user123"])
        #expect(queryTarget.targetID == 42)
        #expect(queryTarget.query.parent == "projects/test-project/databases/(default)/documents")
        #expect(queryTarget.query.structuredQuery.from.first?.collectionID == "users")
    }

    @Test("ListenRequestBuilder builds add and remove target requests")
    func testListenRequestBuilderBuildsAddAndRemoveTargetRequests() {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let target = ListenTargetBuilder().makeDocumentTarget(for: reference, targetID: 7)
        let builder = ListenRequestBuilder(database: database)

        let addRequest = builder.makeAddTargetRequest(target)
        let removeRequest = builder.makeRemoveTargetRequest(targetID: 7)

        #expect(addRequest.database == "projects/test-project/databases/(default)")
        #expect(addRequest.addTarget.targetID == 7)
        #expect(addRequest.addTarget.documents.documents == ["projects/test-project/databases/(default)/documents/users/user123"])
        #expect(removeRequest.database == "projects/test-project/databases/(default)")
        #expect(removeRequest.removeTarget == 7)
    }

    @Test("ListenRequestStreamController emits add then remove target requests")
    func testListenRequestStreamControllerEmitsAddThenRemoveTargetRequests() async {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let target = ListenTargetBuilder().makeDocumentTarget(for: reference, targetID: 7)
        let controller = ListenRequestStreamController(database: database, target: target)

        await controller.openTarget()
        let requestStream = await controller.makeRequestStream()
        var iterator = requestStream.makeAsyncIterator()

        let addRequest = await iterator.next()
        await controller.closeTarget()
        let removeRequest = await iterator.next()
        let endOfStream = await iterator.next()

        #expect(addRequest?.database == "projects/test-project/databases/(default)")
        #expect(addRequest?.addTarget.targetID == 7)
        #expect(removeRequest?.database == "projects/test-project/databases/(default)")
        #expect(removeRequest?.removeTarget == 7)
        #expect(endOfStream == nil)
    }

    @Test("ReadResponseMapper maps document and query snapshots")
    func testReadResponseMapperMapsDocumentAndQuerySnapshots() throws {
        let database = Database(projectId: "test-project")
        let runtime = ReadResponseMapperRuntime(database: database)
        let mapper = ReadResponseMapper(runtime: runtime)

        let batchResponses = [
            Google_Firestore_V1_BatchGetDocumentsResponse.with {
                $0.found = Google_Firestore_V1_Document.with {
                    $0.name = "projects/test-project/databases/(default)/documents/users/user123"
                    $0.fields["name"] = Google_Firestore_V1_Value.with {
                        $0.stringValue = "Ada"
                    }
                }
            },
            Google_Firestore_V1_BatchGetDocumentsResponse.with {
                $0.missing = "projects/test-project/databases/(default)/documents/users/missing"
            }
        ]

        let snapshots = try mapper.makeDocumentSnapshots(from: batchResponses)

        #expect(snapshots.count == 2)
        #expect(snapshots[0].exists)
        #expect(snapshots[0].documentReference.path == "users/user123")
        #expect(snapshots[0].data()?["name"] as? String == "Ada")
        #expect(!snapshots[1].exists)
        #expect(snapshots[1].documentReference.path == "users/missing")
        #expect(snapshots[0].documentReference.runtime != nil)

        let querySnapshot = try mapper.makeQuerySnapshot(
            from: [
                Google_Firestore_V1_RunQueryResponse.with {
                    $0.document = Google_Firestore_V1_Document.with {
                        $0.name = "projects/test-project/databases/(default)/documents/users/a"
                    }
                },
                Google_Firestore_V1_RunQueryResponse.with {
                    $0.document = Google_Firestore_V1_Document.with {
                        $0.name = "projects/test-project/databases/(default)/documents/users/b"
                    }
                }
            ],
            requiresResultOrderReversal: true
        )

        #expect(querySnapshot.documents.map(\.documentReference.path) == ["users/b", "users/a"])
        #expect(querySnapshot.documents.allSatisfy { $0.documentReference.runtime != nil })
    }

    @Test("ReadResponseMapper binds decoded reference fields for its runtime database")
    func testReadResponseMapperBindsDecodedReferenceFieldsForRuntimeDatabase() throws {
        struct DecodedReferences: Decodable {
            let sameDatabaseReference: DocumentReference
            let otherDatabaseReference: DocumentReference
        }

        let database = Database(projectId: "test-project")
        let runtime = ReadResponseMapperRuntime(database: database)
        let mapper = ReadResponseMapper(runtime: runtime)
        let document = Google_Firestore_V1_Document.with {
            $0.name = "projects/test-project/databases/(default)/documents/users/user123"
            $0.fields["sameDatabaseReference"] = Google_Firestore_V1_Value.with {
                $0.referenceValue = "projects/test-project/databases/(default)/documents/users/friend"
            }
            $0.fields["otherDatabaseReference"] = Google_Firestore_V1_Value.with {
                $0.referenceValue = "projects/other-project/databases/(default)/documents/users/foreign"
            }
        }
        let response = Google_Firestore_V1_BatchGetDocumentsResponse.with {
            $0.found = document
        }
        let queryResponse = Google_Firestore_V1_RunQueryResponse.with {
            $0.document = document
        }

        let snapshot = try #require(try mapper.makeDocumentSnapshots(from: [response]).first)
        let data = try #require(snapshot.data())
        let sameDatabaseReference = try #require(data["sameDatabaseReference"] as? DocumentReference)
        let otherDatabaseReference = try #require(data["otherDatabaseReference"] as? DocumentReference)
        let decodedSnapshot = try #require(try snapshot.data(as: DecodedReferences.self))
        let querySnapshot = try mapper.makeQuerySnapshot(
            from: [queryResponse],
            requiresResultOrderReversal: false
        )
        let queryDocument = try #require(querySnapshot.documents.first)
        let decodedQueryDocument = try queryDocument.data(as: DecodedReferences.self)
        let decodedQueryDocuments = try querySnapshot.documents(as: DecodedReferences.self)
        let decodedQuerySnapshotDocument = try #require(decodedQueryDocuments.first)

        #expect(sameDatabaseReference.path == "users/friend")
        #expect(sameDatabaseReference.runtime != nil)
        #expect(otherDatabaseReference.path == "users/foreign")
        #expect(otherDatabaseReference.runtime == nil)
        #expect(decodedSnapshot.sameDatabaseReference.runtime != nil)
        #expect(decodedSnapshot.otherDatabaseReference.runtime == nil)
        #expect(decodedQueryDocument.sameDatabaseReference.runtime != nil)
        #expect(decodedQueryDocument.otherDatabaseReference.runtime == nil)
        #expect(decodedQueryDocuments.count == 1)
        #expect(decodedQuerySnapshotDocument.sameDatabaseReference.runtime != nil)
        #expect(decodedQuerySnapshotDocument.otherDatabaseReference.runtime == nil)
    }

    @Test("ReadResponseMapper validates response document names")
    func testReadResponseMapperValidatesResponseDocumentNames() throws {
        let database = Database(projectId: "test-project")
        let runtime = ReadResponseMapperRuntime(database: database)
        let mapper = ReadResponseMapper(runtime: runtime)
        let requestedReference = DocumentReference(
            database,
            parentPath: "users",
            documentID: "requested",
            runtime: runtime
        )
        let mismatchedPathDocument = Google_Firestore_V1_Document.with {
            $0.name = "projects/test-project/databases/(default)/documents/users/actual"
        }

        do {
            _ = try mapper.makeDocumentSnapshot(
                from: mismatchedPathDocument,
                requestedReference: requestedReference
            )
            Issue.record("Expected response path mismatch to throw.")
        } catch FirestoreError.invalidPath(let message) {
            #expect(message.contains("requested document reference"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        let otherDatabaseBatchResponse = [
            Google_Firestore_V1_BatchGetDocumentsResponse.with {
                $0.found = Google_Firestore_V1_Document.with {
                    $0.name = "projects/other-project/databases/(default)/documents/users/user123"
                }
            }
        ]

        do {
            _ = try mapper.makeDocumentSnapshots(from: otherDatabaseBatchResponse)
            Issue.record("Expected batch response database mismatch to throw.")
        } catch FirestoreError.databaseMismatch(let expected, let actual) {
            #expect(expected == "projects/test-project/databases/(default)")
            #expect(actual == "projects/other-project/databases/(default)")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        let otherDatabaseQueryResponse = [
            Google_Firestore_V1_RunQueryResponse.with {
                $0.document = Google_Firestore_V1_Document.with {
                    $0.name = "projects/other-project/databases/(default)/documents/users/user123"
                }
            }
        ]

        do {
            _ = try mapper.makeQuerySnapshot(
                from: otherDatabaseQueryResponse,
                requiresResultOrderReversal: false
            )
            Issue.record("Expected query response database mismatch to throw.")
        } catch FirestoreError.databaseMismatch(let expected, let actual) {
            #expect(expected == "projects/test-project/databases/(default)")
            #expect(actual == "projects/other-project/databases/(default)")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("ReadResponseMapper rejects malformed document resource names")
    func testReadResponseMapperRejectsMalformedDocumentResourceNames() throws {
        let database = Database(projectId: "test-project")
        let runtime = ReadResponseMapperRuntime(database: database)
        let mapper = ReadResponseMapper(runtime: runtime)
        let responses = [
            Google_Firestore_V1_BatchGetDocumentsResponse.with {
                $0.found = Google_Firestore_V1_Document.with {
                    $0.name = "projects/test-project/databases/(default)/documents/users"
                }
            }
        ]

        do {
            _ = try mapper.makeDocumentSnapshots(from: responses)
            Issue.record("Expected malformed resource name to throw.")
        } catch FirestoreError.invalidPath(let message) {
            #expect(message.contains("document"))
        }
    }

    @Test("FirestoreDocumentDataDecoder rejects malformed reference values")
    func testFirestoreDocumentDataDecoderRejectsMalformedReferenceValues() throws {
        let fields = [
            "author": Google_Firestore_V1_Value.with {
                $0.referenceValue = "projects/test-project/databases/(default)/documents/users"
            }
        ]

        do {
            _ = try FirestoreDocumentDataDecoder().decode(fields: fields)
            Issue.record("Expected malformed reference value to throw.")
        } catch FirestoreError.invalidPath(let message) {
            #expect(message.contains("document"))
        }
    }

    @Test("FirestoreDocumentDataDecoder maps bytes and vector arrays")
    func testFirestoreDocumentDataDecoderMapsBytesAndVectorArrays() throws {
        let fields = [
            "blob": Google_Firestore_V1_Value.with {
                $0.bytesValue = Data([1, 2, 3])
            },
            "embedding": Google_Firestore_V1_Value.with {
                $0.arrayValue = Google_Firestore_V1_ArrayValue.with {
                    $0.values = [
                        Google_Firestore_V1_Value.with { $0.doubleValue = 1.0 },
                        Google_Firestore_V1_Value.with { $0.doubleValue = 2.0 },
                        Google_Firestore_V1_Value.with { $0.doubleValue = 3.0 }
                    ]
                }
            }
        ]

        let data = try FirestoreDocumentDataDecoder().decode(fields: fields).mapValues(\.anyValue)
        let embedding = data["embedding"] as? [Any]

        #expect(data["blob"] as? Data == Data([1, 2, 3]))
        #expect(embedding?.count == 3)
        #expect(embedding?[0] as? Double == 1.0)
        #expect(embedding?[1] as? Double == 2.0)
        #expect(embedding?[2] as? Double == 3.0)
    }

    @Test("ReadResponseMapper maps child collection references")
    func testReadResponseMapperMapsChildCollectionReferences() {
        let database = Database(projectId: "test-project")
        let runtime = ReadResponseMapperRuntime(database: database)
        let mapper = ReadResponseMapper(runtime: runtime)
        let parent = DocumentReference(
            database,
            parentPath: "users",
            documentID: "user123",
            runtime: runtime
        )

        let collections = mapper.makeCollectionReferences(
            from: ["posts", "comments"],
            parentDocument: parent
        )

        #expect(collections.map(\.path) == ["users/user123/posts", "users/user123/comments"])
        #expect(collections.map(\.parent?.path) == ["users/user123", "users/user123"])
        #expect(collections.allSatisfy { $0.runtime != nil })
    }

    @Test("ReadResponseMapper maps aggregation responses to snapshots")
    func testReadResponseMapperMapsAggregationResponsesToSnapshots() throws {
        let database = Database(projectId: "test-project")
        let runtime = ReadResponseMapperRuntime(database: database)
        let mapper = ReadResponseMapper(runtime: runtime)
        let count = AggregateField.count(alias: "count")

        let snapshot = try mapper.makeAggregateSnapshot(
            from: [
                Google_Firestore_V1_RunAggregationQueryResponse(),
                Google_Firestore_V1_RunAggregationQueryResponse.with {
                    $0.result = Google_Firestore_V1_AggregationResult.with {
                        $0.aggregateFields["count"] = Google_Firestore_V1_Value.with {
                            $0.integerValue = 7
                        }
                    }
                }
            ]
        )

        #expect(snapshot.get("count")?.intValue == 7)
        #expect(try snapshot.requireInteger(count) == 7)

        do {
            _ = try mapper.makeAggregateSnapshot(from: [])
            Issue.record("Expected no result error")
        } catch FirestoreError.noResult {
            #expect(true)
        }
    }

    @Test("ReadResponseMapper maps query explain metrics")
    func testReadResponseMapperMapsQueryExplainMetrics() throws {
        let database = Database(projectId: "test-project")
        let runtime = ReadResponseMapperRuntime(database: database)
        let mapper = ReadResponseMapper(runtime: runtime)

        let result = try mapper.makeQueryExplainResult(
            from: [
                Google_Firestore_V1_RunQueryResponse.with {
                    $0.document = Google_Firestore_V1_Document.with {
                        $0.name = "projects/test-project/databases/(default)/documents/cities/SF"
                        $0.fields["name"] = Google_Firestore_V1_Value.with {
                            $0.stringValue = "San Francisco"
                        }
                    }
                },
                Google_Firestore_V1_RunQueryResponse.with {
                    $0.explainMetrics = Self.makeExplainMetrics()
                }
            ],
            requiresResultOrderReversal: false
        )

        #expect(result.snapshot?.documents.count == 1)
        #expect(result.metrics.planSummary.indexesUsed.first?["query_scope"] == .string("Collection"))
        #expect(result.metrics.executionStats?.resultsReturned == 1)
        #expect(result.metrics.executionStats?.executionDurationSeconds == 1.25)
        #expect(result.metrics.executionStats?.readOperations == 3)
        #expect(result.metrics.executionStats?.debugStats["documents_scanned"] == .string("1"))
    }

    @Test("ReadResponseMapper distinguishes plan-only and empty analyzed query explain snapshots")
    func testReadResponseMapperDistinguishesPlanOnlyAndEmptyAnalyzedQueryExplainSnapshots() throws {
        let database = Database(projectId: "test-project")
        let runtime = ReadResponseMapperRuntime(database: database)
        let mapper = ReadResponseMapper(runtime: runtime)

        let planOnly = try mapper.makeQueryExplainResult(
            from: [
                Google_Firestore_V1_RunQueryResponse.with {
                    $0.explainMetrics = Self.makePlanOnlyExplainMetrics()
                }
            ],
            requiresResultOrderReversal: false
        )
        let analyzedEmpty = try mapper.makeQueryExplainResult(
            from: [
                Google_Firestore_V1_RunQueryResponse.with {
                    $0.readTime = Google_Protobuf_Timestamp.with {
                        $0.seconds = 1
                    }
                },
                Google_Firestore_V1_RunQueryResponse.with {
                    $0.explainMetrics = Self.makeExplainMetrics(resultsReturned: 0)
                }
            ],
            requiresResultOrderReversal: false
        )

        #expect(planOnly.snapshot == nil)
        #expect(planOnly.metrics.executionStats == nil)
        #expect(analyzedEmpty.snapshot?.documents.isEmpty == true)
        #expect(analyzedEmpty.metrics.executionStats?.resultsReturned == 0)
    }

    @Test("ReadResponseMapper maps aggregation explain metrics")
    func testReadResponseMapperMapsAggregationExplainMetrics() throws {
        let database = Database(projectId: "test-project")
        let runtime = ReadResponseMapperRuntime(database: database)
        let mapper = ReadResponseMapper(runtime: runtime)

        let result = try mapper.makeAggregateExplainResult(
            from: [
                Google_Firestore_V1_RunAggregationQueryResponse.with {
                    $0.result = Google_Firestore_V1_AggregationResult.with {
                        $0.aggregateFields["count"] = Google_Firestore_V1_Value.with {
                            $0.integerValue = 2
                        }
                    }
                },
                Google_Firestore_V1_RunAggregationQueryResponse.with {
                    $0.explainMetrics = Self.makeExplainMetrics()
                }
            ]
        )

        #expect(result.snapshot?.data["count"]?.int64Value == 2)
        #expect(result.metrics.planSummary.indexesUsed.first?["properties"] == .string("(__name__ ASC)"))
        #expect(result.metrics.executionStats?.debugStats["documents_scanned"] == .string("1"))
    }

    @Test("ReadResponseMapper distinguishes plan-only and empty analyzed aggregation explain snapshots")
    func testReadResponseMapperDistinguishesPlanOnlyAndEmptyAnalyzedAggregationExplainSnapshots() throws {
        let database = Database(projectId: "test-project")
        let runtime = ReadResponseMapperRuntime(database: database)
        let mapper = ReadResponseMapper(runtime: runtime)

        let planOnly = try mapper.makeAggregateExplainResult(
            from: [
                Google_Firestore_V1_RunAggregationQueryResponse.with {
                    $0.explainMetrics = Self.makePlanOnlyExplainMetrics()
                }
            ]
        )
        let analyzedEmpty = try mapper.makeAggregateExplainResult(
            from: [
                Google_Firestore_V1_RunAggregationQueryResponse.with {
                    $0.readTime = Google_Protobuf_Timestamp.with {
                        $0.seconds = 1
                    }
                },
                Google_Firestore_V1_RunAggregationQueryResponse.with {
                    $0.explainMetrics = Self.makeExplainMetrics(resultsReturned: 0)
                }
            ]
        )

        #expect(planOnly.snapshot == nil)
        #expect(planOnly.metrics.executionStats == nil)
        #expect(analyzedEmpty.snapshot?.data.isEmpty == true)
        #expect(analyzedEmpty.metrics.executionStats?.resultsReturned == 0)
    }

    private static func makeExplainMetrics(resultsReturned: Int64 = 1) -> Google_Firestore_V1_ExplainMetrics {
        Google_Firestore_V1_ExplainMetrics.with {
            $0.planSummary = Google_Firestore_V1_PlanSummary.with {
                $0.indexesUsed = [
                    Google_Protobuf_Struct.with {
                        $0.fields["query_scope"] = Google_Protobuf_Value.with {
                            $0.stringValue = "Collection"
                        }
                        $0.fields["properties"] = Google_Protobuf_Value.with {
                            $0.stringValue = "(__name__ ASC)"
                        }
                    }
                ]
            }
            $0.executionStats = Google_Firestore_V1_ExecutionStats.with {
                $0.resultsReturned = resultsReturned
                $0.executionDuration = Google_Protobuf_Duration.with {
                    $0.seconds = 1
                    $0.nanos = 250_000_000
                }
                $0.readOperations = 3
                $0.debugStats = Google_Protobuf_Struct.with {
                    $0.fields["documents_scanned"] = Google_Protobuf_Value.with {
                        $0.stringValue = "1"
                    }
                }
            }
        }
    }

    private static func makePlanOnlyExplainMetrics() -> Google_Firestore_V1_ExplainMetrics {
        Google_Firestore_V1_ExplainMetrics.with {
            $0.planSummary = Google_Firestore_V1_PlanSummary.with {
                $0.indexesUsed = [
                    Google_Protobuf_Struct.with {
                        $0.fields["query_scope"] = Google_Protobuf_Value.with {
                            $0.stringValue = "Collection"
                        }
                    }
                ]
            }
        }
    }

    @Test("ListenTargetIDGenerator increments target IDs")
    func testListenTargetIDGeneratorIncrementsTargetIDs() {
        let generator = ListenTargetIDGenerator()

        #expect(generator.next() == 1)
        #expect(generator.next() == 2)
        #expect(generator.next() == 3)
    }
}

private final class ReadResponseMapperRuntime: FirestoreRuntime {
    let runtimeDatabase: Database

    init(database: Database) {
        self.runtimeDatabase = database
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
        QuerySnapshot(documents: [])
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
