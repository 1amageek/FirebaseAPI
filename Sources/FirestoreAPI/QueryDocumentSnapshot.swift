//
//  QueryDocumentSnapshot.swift
//  
//
//  Created by Norikazu Muramoto on 2023/04/09.
//

import Foundation

/**
 A struct that represents a snapshot of a Firestore document returned by a query.

 The `QueryDocumentSnapshot` struct provides methods for retrieving data and metadata for a specific Firestore document returned by a query. It conforms to the `Identifiable` protocol and requires a `DocumentReference` instance and a `Google_Firestore_V1_Document` instance to be initialized.
 */
public struct QueryDocumentSnapshot: Identifiable, Sendable {

    /// The ID of the Firestore document.
    public var id: String { documentReference.documentID }

    /// A boolean value indicating whether the container holds any data.
    ///
    /// If the data in the container is `nil`, the container is considered empty.
    public var exists: Bool { document != nil }

    /// The path of the Firestore document.
    var path: String { documentReference.path }

    /// The `DocumentReference` instance associated with the Firestore document.
    public var documentReference: DocumentReference

    /// The `Google_Firestore_V1_Document` instance associated with the Firestore document.
    private var document: Google_Firestore_V1_Document?

    /**
     Initializes a `QueryDocumentSnapshot` instance with the specified `Google_Firestore_V1_Document` and `DocumentReference` instances.

     - Parameters:
        - document: The `Google_Firestore_V1_Document` instance associated with the Firestore document.
        - documentReference: The `DocumentReference` instance associated with the Firestore document.
     */
    init(document: Google_Firestore_V1_Document?, documentReference: DocumentReference) {
        self.document = document
        self.documentReference = documentReference
    }

    /**
     Returns a dictionary representing the data in the Firestore document.

     - Returns: A dictionary representing the data in the Firestore document.
     - Note: If a field has a value of `null`, it will be represented in the dictionary as `NSNull()`.
     */
    public func data() -> [String: Any]? {
        guard let fields = document?.fields else { return nil }
        var visitor = DocumentDataVisitor()
        var data: [String: Any] = [:]
        for (key, value) in fields {
            try! value.traverse(visitor: &visitor)
            data[key] = visitor.value
        }
        return data
    }
}
