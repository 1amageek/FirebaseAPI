import Foundation
import FirestoreCore
import FirestoreProtobuf

package struct WriteCompiler {
    package let database: Database

    package init(database: Database) {
        self.database = database
    }

    package func makeCommitRequest(
        writes: [WriteData],
        transactionID: Data? = nil
    ) throws -> Google_Firestore_V1_CommitRequest {
        var request = Google_Firestore_V1_CommitRequest()
        request.database = database.database
        if let transactionID {
            request.transaction = transactionID
        }
        request.writes = try makeWrites(writes)
        return request
    }

    package func makeWrites(_ writes: [WriteData]) throws -> [Google_Firestore_V1_Write] {
        try writes.map(makeWrite)
    }

    package func makeWrite(_ write: WriteData) throws -> Google_Firestore_V1_Write {
        guard let data = write.data else {
            return Google_Firestore_V1_Write.with {
                $0.delete = write.documentReference.name
            }
        }

        let documentData = DocumentData(data: data, interpretsFieldPathKeys: write.exist == true)
        let allowsDelete = write.merge || write.exist == true
        let explicitMergeFieldPaths = try normalizedExplicitMergeFieldPaths(for: write, documentData: documentData)
        let fields = try documentData.getFields(allowsDelete: allowsDelete)
        let transforms = try documentData.getFieldTransforms(
            documentPath: write.documentReference.name,
            allowsDelete: allowsDelete,
            allowedFieldPaths: explicitMergeFieldPaths.map { Set($0) }
        )
        let updateMaskFieldPaths = write.merge
            ? try updateMaskFieldPaths(
                for: write,
                documentData: documentData,
                explicitMergeFieldPaths: explicitMergeFieldPaths
            )
            : []

        return Google_Firestore_V1_Write.with {
            $0.update = Google_Firestore_V1_Document.with {
                $0.name = write.documentReference.name
                $0.fields = fields
            }
            if let exists = write.exist {
                $0.currentDocument = Google_Firestore_V1_Precondition.with {
                    $0.exists = exists
                }
            }
            if write.merge {
                $0.updateMask = Google_Firestore_V1_DocumentMask.with {
                    $0.fieldPaths = updateMaskFieldPaths
                }
            }
            if !transforms.isEmpty {
                $0.updateTransforms = transforms
            }
        }
    }

    private func normalizedExplicitMergeFieldPaths(
        for write: WriteData,
        documentData: DocumentData
    ) throws -> [String]? {
        guard let mergeFields = write.mergeFields else {
            return nil
        }
        let fieldPaths = try mergeFields.map(FirestoreFieldPath.normalizeDocumentFieldPath)
        try documentData.validateExplicitMergeFieldPaths(fieldPaths)
        return fieldPaths
    }

    private func updateMaskFieldPaths(
        for write: WriteData,
        documentData: DocumentData,
        explicitMergeFieldPaths: [String]?
    ) throws -> [String] {
        if let explicitMergeFieldPaths {
            let transformFieldPaths = try documentData.transformFieldPathsExcludedFromUpdateMask()
            return explicitMergeFieldPaths
                .filter { !transformFieldPaths.contains($0) }
        }
        if write.exist == true {
            return try documentData.updateFieldPaths()
        }
        return try documentData.mergeFieldPaths()
    }
}
