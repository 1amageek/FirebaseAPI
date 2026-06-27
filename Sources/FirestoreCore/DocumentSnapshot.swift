//
//  DocumentSnapshot.swift
//
//
//  Created by Norikazu Muramoto on 2023/04/09.
//

import Foundation

/**
 A struct that represents a snapshot of a Firestore document.

 The `DocumentSnapshot` struct provides methods for retrieving data and metadata for a specific Firestore document.
 */
public struct DocumentSnapshot: Identifiable, Sendable {

    public let metadata: SnapshotMetadata

    /// The ID of the Firestore document.
    public var id: String { documentID }

    /// The ID of the Firestore document.
    public var documentID: String { documentReference.documentID }

    /// A boolean value indicating whether the container holds any data.
    ///
    /// If the data in the container is `nil`, the container is considered empty.
    public var exists: Bool { fields != nil }

    /// The path of the Firestore document.
    package var path: String { documentReference.path }

    /// The `DocumentReference` instance associated with the Firestore document.
    public let documentReference: DocumentReference

    /// The `DocumentReference` instance associated with the Firestore document.
    public var reference: DocumentReference { documentReference }

    private let fields: [String: FirestoreDocumentValue]?

    package init(
        fields: [String: FirestoreDocumentValue]? = nil,
        documentReference: DocumentReference,
        metadata: SnapshotMetadata = .serverSynchronized
    ) {
        self.metadata = metadata
        self.fields = fields
        self.documentReference = documentReference
    }

    public init(
        data: [String: Any],
        documentReference: DocumentReference,
        metadata: SnapshotMetadata = .serverSynchronized
    ) throws {
        self.init(
            fields: try FirestoreDocumentValue.fields(from: data),
            documentReference: documentReference,
            metadata: metadata
        )
    }

    public static func missing(
        reference: DocumentReference,
        metadata: SnapshotMetadata = .serverSynchronized
    ) -> DocumentSnapshot {
        DocumentSnapshot(documentReference: reference, metadata: metadata)
    }

    /**
     Returns a dictionary representing the data in the Firestore document.

     - Returns: A dictionary representing the data in the Firestore document.
     - Note: If a field has a value of `null`, it will be represented in the dictionary as `NSNull()`.
     */
    public func data() -> [String: Any]? {
        fields?.mapValues(\.anyValue)
    }

    public func data(with serverTimestampBehavior: ServerTimestampBehavior) -> [String: Any]? {
        data()
    }

    public func get(_ field: String) -> Any? {
        get(field, serverTimestampBehavior: .none)
    }

    public func get(
        _ field: String,
        serverTimestampBehavior: ServerTimestampBehavior
    ) -> Any? {
        do {
            return try FirestoreDocumentValue.anyValue(
                in: fields,
                fieldPath: field,
                serverTimestampBehavior: serverTimestampBehavior
            )
        } catch {
            return nil
        }
    }

    public func get(_ fieldPath: FieldPath) -> Any? {
        get(fieldPath, serverTimestampBehavior: .none)
    }

    public func get(
        _ fieldPath: FieldPath,
        serverTimestampBehavior: ServerTimestampBehavior
    ) -> Any? {
        do {
            return try FirestoreDocumentValue.anyValue(
                in: fields,
                fieldPath: fieldPath,
                serverTimestampBehavior: serverTimestampBehavior
            )
        } catch {
            return nil
        }
    }

    public subscript(_ field: String) -> Any? {
        get {
            get(field)
        }
    }

    public subscript(_ fieldPath: FieldPath) -> Any? {
        get {
            get(fieldPath)
        }
    }

}
