//
//  QueryListenState.swift
//
//
//  Created on 2026/06/25.
//

import Foundation
import FirestoreCore
import FirestoreProtobuf
import FirestoreRPCSupport

package struct QueryListenState {
    let targetID: Int32
    let runtime: (any FirestoreQueryRuntime)?
    let sortOrders: [QuerySortOrder]
    var documents: [QueryDocumentSnapshot] = []
    var rpcDocuments: [Google_Firestore_V1_Document] = []
    var documentNames: [String] = []
    var indexesByName: [String: Int] = [:]
    var pendingChanges: [DocumentChange] = []
    var hasEmittedInitialSnapshot = false
    package private(set) var resumeToken: Data?

    package init(
        targetID: Int32,
        runtime: (any FirestoreQueryRuntime)?,
        sortOrders: [QuerySortOrder] = []
    ) {
        self.targetID = targetID
        self.runtime = runtime
        self.sortOrders = sortOrders
    }

    package mutating func apply(_ response: Google_Firestore_V1_ListenResponse) throws -> QuerySnapshot? {
        guard let responseType = response.responseType else {
            return nil
        }

        switch responseType {
        case .documentChange(let change):
            try applyDocumentChange(change)
            return flushPendingChangesAfterInitialSnapshot()

        case .documentDelete(let deleteInfo):
            try applyDocumentDelete(deleteInfo)
            return flushPendingChangesAfterInitialSnapshot()

        case .documentRemove(let removeInfo):
            try applyDocumentRemove(removeInfo)
            return flushPendingChangesAfterInitialSnapshot()

        case .targetChange(let targetChange):
            return try applyTargetChange(targetChange)

        case .filter(let filter):
            try validateExistenceFilter(filter)
            return nil
        }
    }

    private mutating func applyDocumentChange(_ change: Google_Firestore_V1_DocumentChange) throws {
        guard change.hasDocument else {
            return
        }

        if appliesToTarget(change.targetIds) {
            appendPendingChange(try upsert(change.document))
        } else if appliesToTarget(change.removedTargetIds) {
            appendPendingChange(removeDocument(named: change.document.name))
        }
    }

    private mutating func applyDocumentDelete(_ deleteInfo: Google_Firestore_V1_DocumentDelete) throws {
        guard appliesToTarget(deleteInfo.removedTargetIds) else {
            return
        }
        try validateDocumentName(deleteInfo.document)
        appendPendingChange(removeDocument(named: deleteInfo.document))
    }

    private mutating func applyDocumentRemove(_ removeInfo: Google_Firestore_V1_DocumentRemove) throws {
        guard appliesToTarget(removeInfo.removedTargetIds) else {
            return
        }
        try validateDocumentName(removeInfo.document)
        appendPendingChange(removeDocument(named: removeInfo.document))
    }

    private mutating func applyTargetChange(
        _ targetChange: Google_Firestore_V1_TargetChange
    ) throws -> QuerySnapshot? {
        guard appliesToTargetChange(targetChange.targetIds) else {
            return nil
        }

        if !targetChange.resumeToken.isEmpty {
            resumeToken = targetChange.resumeToken
        }

        switch targetChange.targetChangeType {
        case .current:
            guard !hasEmittedInitialSnapshot else {
                return nil
            }
            hasEmittedInitialSnapshot = true
            pendingChanges.removeAll()
            return makeSnapshot(documentChanges: initialDocumentChanges())

        case .reset:
            reset()
            return nil

        case .remove:
            if targetChange.hasCause {
                let code = FirestoreErrorCode(rawValue: Int(targetChange.cause.code)) ?? .unknown
                throw FirestoreError.rpcError(
                    FirestoreRemoteError(
                        code: code,
                        message: targetChange.cause.message
                    )
                )
            }
            return nil

        case .add, .noChange, .UNRECOGNIZED(_):
            return nil
        }
    }

    private func appliesToTarget(_ targetIds: [Int32]) -> Bool {
        targetIds.contains(targetID)
    }

    private func appliesToTargetChange(_ targetIds: [Int32]) -> Bool {
        targetIds.isEmpty || targetIds.contains(targetID)
    }
}
