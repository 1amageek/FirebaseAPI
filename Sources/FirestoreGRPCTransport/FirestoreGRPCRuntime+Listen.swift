import Foundation
import FirestoreGRPCStubs
import FirestoreProtobuf
import GRPCCore

extension FirestoreGRPCRuntime {
    internal func listen(
        target: Google_Firestore_V1_Target
    ) async throws -> AsyncThrowingStream<Google_Firestore_V1_ListenResponse, Error> {
        let client = Google_Firestore_V1_Firestore.Client(wrapping: self.grpcClient)
        return await FirestoreListenStreamExecutor(database: database).makeResponseStream(
            target: target,
            metadata: try await authorizedMetadata()
        ) { request, handleResponse in
            try await client.listen(
                request: request,
                onResponse: handleResponse
            )
        }
    }
}
