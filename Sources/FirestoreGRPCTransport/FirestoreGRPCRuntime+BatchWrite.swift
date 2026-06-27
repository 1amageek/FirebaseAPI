import Foundation
import FirestoreCore
import FirestoreRPC
import FirestoreGRPCStubs
import FirestoreProtobuf
import GRPCCore

extension FirestoreGRPCRuntime {
    internal func executeBatchWrite(
        writes: [WriteData],
        labels: [String: String]
    ) async throws -> FirestoreBulkWriteResult {
        let client = Google_Firestore_V1_Firestore.Client(wrapping: self.grpcClient)
        let requestMessage = try BatchWriteCompiler(database: database).makeBatchWriteRequest(
            writes: writes,
            labels: labels
        )
        let documentReferences = writes.map(\.documentReference)

        return try await executeFiniteRPC(message: requestMessage) { request in
            try await client.batchWrite(
                request: request,
                options: self.callOptions
            ) { response in
                try BatchWriteResponseMapper().makeResult(
                    documentReferences: documentReferences,
                    response: response.message
                )
            }
        }
    }
}
