import Foundation
import FirestoreCore
import FirestorePipeline
import FirestoreRuntimeConfig
import FirestoreRuntimeSupport

public final class Firestore: Sendable {
    let database: Database
    let referenceRuntime: any FirestoreReferenceRuntime
    let collectionGroupRuntime: any FirestoreCollectionGroupRuntime
    let batchWriteRuntime: any FirestoreBatchWriteRuntime
    let pipelineRuntime: any FirestorePipelineRuntime
    let transactionRuntime: any FirestoreTransactionRuntime
    private let makeBatchHandler: @Sendable () -> FirestoreAdminWriteBatch
    private let setLogLevelHandler: @Sendable (FirestoreLogLevel) -> Void
    private let shutdownHandler: @Sendable () async -> Void

    package init(
        database: Database,
        referenceRuntime: any FirestoreReferenceRuntime,
        collectionGroupRuntime: any FirestoreCollectionGroupRuntime,
        batchWriteRuntime: any FirestoreBatchWriteRuntime,
        pipelineRuntime: any FirestorePipelineRuntime,
        transactionRuntime: any FirestoreTransactionRuntime,
        makeBatchHandler: @escaping @Sendable () -> FirestoreAdminWriteBatch,
        setLogLevelHandler: @escaping @Sendable (FirestoreLogLevel) -> Void,
        shutdownHandler: @escaping @Sendable () async -> Void
    ) {
        self.database = database
        self.referenceRuntime = referenceRuntime
        self.collectionGroupRuntime = collectionGroupRuntime
        self.batchWriteRuntime = batchWriteRuntime
        self.pipelineRuntime = pipelineRuntime
        self.transactionRuntime = transactionRuntime
        self.makeBatchHandler = makeBatchHandler
        self.setLogLevelHandler = setLogLevelHandler
        self.shutdownHandler = shutdownHandler
    }

    public func collectionGroup(_ groupID: String) throws -> CollectionGroup {
        let groupID = try FirestorePathValidator.collectionGroupID(groupID)
        return CollectionGroup(database, groupID: groupID, runtime: collectionGroupRuntime)
    }

    public func collection(_ collectionPath: String) throws -> CollectionReference {
        let (parentPath, collectionID) = try FirestorePathValidator.collectionPath(collectionPath)
        return CollectionReference(database, parentPath: parentPath, collectionID: collectionID, runtime: referenceRuntime)
    }

    public func document(_ documentPath: String) throws -> DocumentReference {
        let (parentPath, documentID) = try FirestorePathValidator.documentPath(documentPath)
        return DocumentReference(database, parentPath: parentPath, documentID: documentID, runtime: referenceRuntime)
    }

    public func batch() -> FirestoreAdminWriteBatch {
        makeBatchHandler()
    }

    public func bulkWriter() -> FirestoreAdminBulkWriter {
        FirestoreAdminBulkWriter(database: database) { [batchWriteRuntime] writes, labels in
            try await batchWriteRuntime.batchWrite(writes, labels: labels)
        }
    }

    public func pipeline() -> FirestorePipeline {
        FirestorePipeline()
    }

    public func execute(_ pipeline: FirestorePipeline) async throws -> PipelineQuerySnapshot {
        try await pipelineRuntime.executePipeline(pipeline)
    }

    public func explain(
        _ pipeline: FirestorePipeline,
        options: PipelineExplainOptions = .explainText
    ) async throws -> PipelineExplainResult {
        try await pipelineRuntime.explainPipeline(pipeline, options: options)
    }

    public func setLogLevel(_ level: FirestoreLogLevel) {
        setLogLevelHandler(level)
    }

    public func shutdown() async {
        await shutdownHandler()
    }
}
