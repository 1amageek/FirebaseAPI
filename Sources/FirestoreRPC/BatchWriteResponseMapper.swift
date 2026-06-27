import Foundation
import FirestoreCore
import FirestoreProtobuf

package struct BatchWriteResponseMapper {
    package init() {}

    package func makeResult(
        documentReferences: [DocumentReference],
        response: Google_Firestore_V1_BatchWriteResponse
    ) throws -> FirestoreBulkWriteResult {
        guard response.status.count == documentReferences.count else {
            throw FirestoreError.invalidOperation("BatchWrite response status count does not match request write count.")
        }

        if !response.writeResults.isEmpty && response.writeResults.count != documentReferences.count {
            throw FirestoreError.invalidOperation("BatchWrite response write result count does not match request write count.")
        }

        let results = documentReferences.indices.map { index in
            makeOperationResult(
                index: index,
                documentReference: documentReferences[index],
                status: response.status[index],
                writeResult: response.writeResults.indices.contains(index) ? response.writeResults[index] : nil
            )
        }
        return FirestoreBulkWriteResult(results: results)
    }

    private func makeOperationResult(
        index: Int,
        documentReference: DocumentReference,
        status: Google_Rpc_Status,
        writeResult: Google_Firestore_V1_WriteResult?
    ) -> FirestoreBulkWriteOperationResult {
        let error: FirestoreRemoteError?
        if status.code == 0 {
            error = nil
        } else {
            error = FirestoreRemoteError(
                code: FirestoreErrorCode(rawValue: Int(status.code)) ?? .unknown,
                message: status.message
            )
        }

        return FirestoreBulkWriteOperationResult(
            index: index,
            document: documentReference,
            updateTime: writeResult.flatMap(makeUpdateTime),
            error: error
        )
    }

    private func makeUpdateTime(_ writeResult: Google_Firestore_V1_WriteResult) -> Timestamp? {
        guard writeResult.hasUpdateTime else {
            return nil
        }
        return Timestamp(
            seconds: writeResult.updateTime.seconds,
            nanos: writeResult.updateTime.nanos
        )
    }
}
