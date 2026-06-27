public struct FirestoreEmbeddedQuery: Equatable, Sendable {
    public let database: FirestoreEmbeddedDatabase
    public let collectionPath: String
    public let filter: FirestoreEmbeddedFilter?
    public let orderBy: [FirestoreEmbeddedOrder]
    public let limit: Int?

    public init(
        database: FirestoreEmbeddedDatabase,
        collectionPath: String,
        filter: FirestoreEmbeddedFilter? = nil,
        orderBy: [FirestoreEmbeddedOrder] = [],
        limit: Int? = nil
    ) throws(FirestoreEmbeddedError) {
        let normalizedPath = collectionPath.firestoreEmbeddedNormalizedPath()
        try FirestoreEmbeddedPath.validateCollectionPath(normalizedPath)
        if let limit, limit <= 0 {
            throw FirestoreEmbeddedError.invalidValue("Limit must be greater than zero.")
        }
        self.database = database
        self.collectionPath = normalizedPath
        self.filter = filter
        self.orderBy = orderBy
        self.limit = limit
    }

    public var parentResourcePath: String {
        let components = collectionPath.firestoreEmbeddedPathComponents()
        guard components.count > 1 else {
            return "\(database.resourcePath)/documents"
        }
        let parentPath = components.dropLast().joined(separator: "/")
        return "\(database.resourcePath)/documents/\(parentPath)"
    }

    public var collectionID: String {
        collectionPath.firestoreEmbeddedLastPathComponent()
    }

    public func `where`(_ filter: FirestoreEmbeddedFilter) -> FirestoreEmbeddedQuery {
        let resolvedFilter: FirestoreEmbeddedFilter
        if let existingFilter = self.filter {
            resolvedFilter = .and([existingFilter, filter])
        } else {
            resolvedFilter = filter
        }
        return FirestoreEmbeddedQuery(
            uncheckedDatabase: database,
            collectionPath: collectionPath,
            filter: resolvedFilter,
            orderBy: orderBy,
            limit: limit
        )
    }

    public func order(by fieldPath: String, descending: Bool = false) throws(FirestoreEmbeddedError) -> FirestoreEmbeddedQuery {
        let order = try FirestoreEmbeddedOrder(fieldPath: fieldPath, descending: descending)
        return FirestoreEmbeddedQuery(
            uncheckedDatabase: database,
            collectionPath: collectionPath,
            filter: filter,
            orderBy: orderBy + [order],
            limit: limit
        )
    }

    public func limit(to limit: Int) throws(FirestoreEmbeddedError) -> FirestoreEmbeddedQuery {
        try FirestoreEmbeddedQuery(
            database: database,
            collectionPath: collectionPath,
            filter: filter,
            orderBy: orderBy,
            limit: limit
        )
    }

    private init(
        uncheckedDatabase database: FirestoreEmbeddedDatabase,
        collectionPath: String,
        filter: FirestoreEmbeddedFilter?,
        orderBy: [FirestoreEmbeddedOrder],
        limit: Int?
    ) {
        self.database = database
        self.collectionPath = collectionPath
        self.filter = filter
        self.orderBy = orderBy
        self.limit = limit
    }
}

public struct FirestoreEmbeddedOrder: Equatable, Sendable {
    public let fieldPath: String
    public let descending: Bool

    public init(fieldPath: String, descending: Bool = false) throws(FirestoreEmbeddedError) {
        let normalizedPath = fieldPath.firestoreEmbeddedTrimmedSlashes()
        guard !normalizedPath.isEmpty else {
            throw FirestoreEmbeddedError.invalidValue("Order field path must not be empty.")
        }
        self.fieldPath = normalizedPath
        self.descending = descending
    }
}
