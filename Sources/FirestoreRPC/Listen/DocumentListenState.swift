//
//  DocumentListenState.swift
//
//
//  Created on 2026/06/25.
//

import Foundation
import FirestoreCore
import FirestoreProtobuf
import FirestoreRPCSupport

package struct DocumentListenState {
    private let targetID: Int32
    private let reference: DocumentReference
    private var document: Google_Firestore_V1_Document?
    private var hasEmittedInitialSnapshot = false
    package private(set) var resumeToken: Data?

    package init(targetID: Int32, reference: DocumentReference) {
        self.targetID = targetID
        self.reference = reference
    }

    package mutating func apply(_ response: Google_Firestore_V1_ListenResponse) throws -> DocumentSnapshot? {
        guard let responseType = response.responseType else {
            return nil
        }

        switch responseType {
        case .documentChange(let change):
            try applyDocumentChange(change)
            return try snapshotAfterInitialIfNeeded()

        case .documentDelete(let deleteInfo):
            try applyDocumentDelete(deleteInfo)
            return try snapshotAfterInitialIfNeeded()

        case .documentRemove(let removeInfo):
            try applyDocumentRemove(removeInfo)
            return try snapshotAfterInitialIfNeeded()

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

        let isTargetChange = appliesToTarget(change.targetIds)
        let isTargetRemoval = appliesToTarget(change.removedTargetIds)
        guard isTargetChange || isTargetRemoval else {
            return
        }

        try validateDocumentName(change.document.name)

        if isTargetChange {
            document = change.document
        } else if isTargetRemoval {
            document = nil
        }
    }

    private mutating func applyDocumentDelete(_ deleteInfo: Google_Firestore_V1_DocumentDelete) throws {
        guard appliesToTarget(deleteInfo.removedTargetIds) else {
            return
        }
        try validateDocumentName(deleteInfo.document)
        document = nil
    }

    private mutating func applyDocumentRemove(_ removeInfo: Google_Firestore_V1_DocumentRemove) throws {
        guard appliesToTarget(removeInfo.removedTargetIds) else {
            return
        }
        try validateDocumentName(removeInfo.document)
        document = nil
    }

    private mutating func applyTargetChange(
        _ targetChange: Google_Firestore_V1_TargetChange
    ) throws -> DocumentSnapshot? {
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
            return try makeSnapshot()

        case .reset:
            document = nil
            hasEmittedInitialSnapshot = false
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

    private func snapshotAfterInitialIfNeeded() throws -> DocumentSnapshot? {
        guard hasEmittedInitialSnapshot else {
            return nil
        }
        return try makeSnapshot()
    }

    private func makeSnapshot() throws -> DocumentSnapshot {
        DocumentSnapshot(
            fields: try FirestoreDocumentDataDecoder(runtime: reference.runtime).decode(document: document),
            documentReference: reference,
            metadata: .serverSynchronized
        )
    }

    private func validateDocumentName(_ documentName: String) throws {
        let responseReference = try DocumentReference(name: documentName, runtime: reference.runtime)
        guard responseReference.database == reference.database else {
            throw FirestoreError.databaseMismatch(
                expected: reference.database.database,
                actual: responseReference.database.database
            )
        }
        guard responseReference.path == reference.path else {
            throw FirestoreError.invalidPath(
                "Listen document response name must match the target document reference."
            )
        }
    }

    private func validateExistenceFilter(_ filter: Google_Firestore_V1_ExistenceFilter) throws {
        guard filter.targetID == targetID else {
            return
        }

        let expectedCount = document == nil ? 0 : 1
        if Int(filter.count) != expectedCount {
            throw ListenResyncRequired(
                targetID: targetID,
                expectedCount: expectedCount,
                actualCount: Int(filter.count)
            )
        }
    }
}
