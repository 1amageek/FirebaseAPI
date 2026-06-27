import Foundation

package enum FirestorePathValidator {
    package static func collectionGroupID(_ groupID: String) throws -> String {
        guard !groupID.isEmpty else {
            throw FirestoreError.invalidPath("Collection group ID cannot be empty.")
        }
        guard !groupID.contains("/") else {
            throw FirestoreError.invalidPath("Collection group ID must not contain '/'.")
        }
        return groupID
    }

    package static func collectionPath(_ path: String) throws -> (parentPath: String?, collectionID: String) {
        let components = try pathComponents(path, emptyMessage: "Collection path cannot be empty.")
        guard !components.count.isMultiple(of: 2) else {
            throw FirestoreError.invalidPath("Collection path must point to a collection.")
        }
        guard let collectionID = components.last else {
            throw FirestoreError.invalidPath("Collection path cannot be empty.")
        }
        let parentPath = joinedParentPath(components.dropLast())
        return (parentPath, collectionID)
    }

    package static func documentPath(_ path: String) throws -> (parentPath: String, documentID: String) {
        let components = try pathComponents(path, emptyMessage: "Document path cannot be empty.")
        guard components.count.isMultiple(of: 2) else {
            throw FirestoreError.invalidPath("Document path must point to a document.")
        }
        guard let documentID = components.last else {
            throw FirestoreError.invalidPath("Document path cannot be empty.")
        }
        return (components.dropLast().joined(separator: "/"), documentID)
    }

    package static func childCollectionPath(
        _ path: String,
        parentDocumentPath: String
    ) throws -> (parentPath: String, collectionID: String) {
        let components = try pathComponents(path, emptyMessage: "Collection path cannot be empty.")
        guard !components.count.isMultiple(of: 2) else {
            throw FirestoreError.invalidPath("Collection path must point to a collection.")
        }
        let relativeParentPath = components.dropLast().joined(separator: "/")
        let parentPath = [parentDocumentPath, relativeParentPath]
            .filter { !$0.isEmpty }
            .joined(separator: "/")
        guard let collectionID = components.last else {
            throw FirestoreError.invalidPath("Collection path cannot be empty.")
        }
        return (parentPath, collectionID)
    }

    package static func childDocumentPath(
        _ path: String,
        parentCollectionPath: String
    ) throws -> (parentPath: String, documentID: String) {
        let components = try pathComponents(path, emptyMessage: "Document path cannot be empty.")
        guard !components.count.isMultiple(of: 2) else {
            throw FirestoreError.invalidPath("Document path must point to a document.")
        }
        let relativeParentPath = components.dropLast().joined(separator: "/")
        let parentPath = [parentCollectionPath, relativeParentPath]
            .filter { !$0.isEmpty }
            .joined(separator: "/")
        guard let documentID = components.last else {
            throw FirestoreError.invalidPath("Document path cannot be empty.")
        }
        return (parentPath, documentID)
    }

    private static func pathComponents(_ path: String, emptyMessage: String) throws -> [String] {
        let components = path
            .split(separator: "/", omittingEmptySubsequences: false)
            .map(String.init)
        guard !components.isEmpty else {
            throw FirestoreError.invalidPath(emptyMessage)
        }
        guard components.allSatisfy({ !$0.isEmpty }) else {
            throw FirestoreError.invalidPath("Path must not contain empty segments.")
        }
        return components
    }

    private static func joinedParentPath(_ components: ArraySlice<String>) -> String? {
        let parentPath = components.joined(separator: "/")
        return parentPath.isEmpty ? nil : parentPath
    }
}
