enum FirestoreEmbeddedPath {
    static func validateDocumentPath(_ path: String) throws(FirestoreEmbeddedError) {
        let components = path.firestoreEmbeddedPathComponents()
        guard !components.isEmpty, components.count.isMultiple(of: 2) else {
            throw FirestoreEmbeddedError.invalidPath("Document path must contain an even number of path components.")
        }
    }

    static func validateCollectionPath(_ path: String) throws(FirestoreEmbeddedError) {
        let components = path.firestoreEmbeddedPathComponents()
        guard !components.isEmpty, !components.count.isMultiple(of: 2) else {
            throw FirestoreEmbeddedError.invalidPath("Collection path must contain an odd number of path components.")
        }
    }
}

extension String {
    func firestoreEmbeddedTrimmedSlashes() -> String {
        var value = self
        while value.first == "/" {
            value.removeFirst()
        }
        while value.last == "/" {
            value.removeLast()
        }
        return value
    }

    func firestoreEmbeddedNormalizedPath() -> String {
        firestoreEmbeddedPathComponents().joined(separator: "/")
    }

    func firestoreEmbeddedPathComponents() -> [String] {
        split(separator: "/", omittingEmptySubsequences: true).map(String.init)
    }

    func firestoreEmbeddedLastPathComponent() -> String {
        firestoreEmbeddedPathComponents().last ?? ""
    }
}
