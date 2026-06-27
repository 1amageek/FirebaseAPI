//
//  QuerySnapshot.swift
//
//
//  Created by Norikazu Muramoto on 2023/04/09.
//

import Foundation

public struct QuerySnapshot: Sendable {

    public let metadata: SnapshotMetadata

    public let documents: [QueryDocumentSnapshot]

    public let documentChanges: [DocumentChange]

    public var count: Int { documents.count }

    public var isEmpty: Bool { documents.isEmpty }

    public init(
        documents: [QueryDocumentSnapshot],
        metadata: SnapshotMetadata = .serverSynchronized,
        documentChanges: [DocumentChange]? = nil
    ) {
        self.metadata = metadata
        self.documents = documents
        self.documentChanges = documentChanges ?? documents.enumerated().map { index, document in
            DocumentChange(
                type: .added,
                document: document,
                oldIndex: DocumentChange.notFoundIndex,
                newIndex: index
            )
        }
    }
}
