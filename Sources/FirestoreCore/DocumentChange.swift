//
//  DocumentChange.swift
//
//
//  Created on 2026/06/25.
//

import Foundation

public enum DocumentChangeType: Int, Sendable {
    case added = 0
    case modified = 1
    case removed = 2
}

public struct DocumentChange: Sendable {
    public static let notFoundIndex = NSNotFound

    public let type: DocumentChangeType
    public let document: QueryDocumentSnapshot
    public let oldIndex: Int
    public let newIndex: Int

    public init(
        type: DocumentChangeType,
        document: QueryDocumentSnapshot,
        oldIndex: Int,
        newIndex: Int
    ) {
        self.type = type
        self.document = document
        self.oldIndex = oldIndex
        self.newIndex = newIndex
    }
}
