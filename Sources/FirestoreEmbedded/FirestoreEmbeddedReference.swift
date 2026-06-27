public struct FirestoreEmbeddedReference: Equatable, Hashable, Sendable {
    public let database: FirestoreEmbeddedDatabase
    public let documentPath: String

    public init(database: FirestoreEmbeddedDatabase, documentPath: String) throws(FirestoreEmbeddedError) {
        let normalizedPath = documentPath.firestoreEmbeddedNormalizedPath()
        try FirestoreEmbeddedPath.validateDocumentPath(normalizedPath)
        self.database = database
        self.documentPath = normalizedPath
    }

    public var documentID: String {
        documentPath.firestoreEmbeddedLastPathComponent()
    }

    public var resourcePath: String {
        "\(database.resourcePath)/documents/\(documentPath)"
    }
}
