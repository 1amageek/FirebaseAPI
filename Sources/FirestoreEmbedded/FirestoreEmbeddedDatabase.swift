public struct FirestoreEmbeddedDatabase: Equatable, Hashable, Sendable {
    public let projectID: String
    public let databaseID: String

    public init(projectID: String, databaseID: String = "(default)") throws(FirestoreEmbeddedError) {
        let normalizedProjectID = projectID.firestoreEmbeddedTrimmedSlashes()
        let normalizedDatabaseID = databaseID.firestoreEmbeddedTrimmedSlashes()
        guard !normalizedProjectID.isEmpty else {
            throw FirestoreEmbeddedError.invalidPath("Project ID must not be empty.")
        }
        guard !normalizedDatabaseID.isEmpty else {
            throw FirestoreEmbeddedError.invalidPath("Database ID must not be empty.")
        }
        self.projectID = normalizedProjectID
        self.databaseID = normalizedDatabaseID
    }

    public var resourcePath: String {
        "projects/\(projectID)/databases/\(databaseID)"
    }
}
