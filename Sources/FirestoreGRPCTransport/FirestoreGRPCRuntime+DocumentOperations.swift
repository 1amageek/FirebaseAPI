import Foundation
import FirestoreCore
import FirestoreRPC
import FirestoreGRPCStubs
import FirestoreProtobuf
import GRPCCore

extension FirestoreGRPCRuntime {

    func executeGetDocument(_ reference: DocumentReference) async throws -> DocumentSnapshot {
        let client = Google_Firestore_V1_Firestore.Client(wrapping: grpcClient)
        let responseMapper = ReadResponseMapper(runtime: self)
        let requestMessage = try DocumentRequestCompiler(database: database).makeGetDocumentRequest(
            for: reference
        )

        do {
            return try await executeFiniteRPC(message: requestMessage) { request in
                let document = try await client.getDocument(
                    request: request,
                    options: self.callOptions
                ) { response in
                    try response.message
                }
                return try responseMapper.makeDocumentSnapshot(
                    from: document,
                    requestedReference: reference
                )
            }
        } catch FirestoreError.rpcError(let error) {
            if error.code == .notFound {
                return responseMapper.makeMissingDocumentSnapshot(for: reference)
            }
            throw FirestoreError.rpcError(error)
        } catch {
            throw error
        }
    }

    func executeSetData(
        _ documentData: [String: Any],
        merge: Bool = false,
        for reference: DocumentReference
    ) async throws {
        _ = try await executeCommit(
            writes: [
                WriteData(
                    documentReference: reference,
                    data: documentData,
                    merge: merge
                )
            ]
        )
    }

    func executeSetData(
        _ documentData: [String: Any],
        mergeFields: [String],
        for reference: DocumentReference
    ) async throws {
        _ = try await executeCommit(
            writes: [
                WriteData(
                    documentReference: reference,
                    data: documentData,
                    merge: true,
                    mergeFields: mergeFields
                )
            ]
        )
    }

    func executeUpdateData(
        _ fields: [String: Any],
        for reference: DocumentReference
    ) async throws {
        _ = try await executeCommit(
            writes: [
                WriteData(
                    documentReference: reference,
                    data: fields,
                    merge: true,
                    exist: true
                )
            ]
        )
    }

    func executeDeleteDocument(_ reference: DocumentReference) async throws {
        _ = try await executeCommit(
            writes: [
                WriteData(documentReference: reference, data: nil, merge: false)
            ]
        )
    }

    func executeListen(to reference: DocumentReference) async throws -> AsyncThrowingStream<DocumentSnapshot, Error> {
        let targetTemplate = ListenTargetBuilder().makeDocumentTarget(
            for: reference,
            targetID: 0
        )

        return ListenStreamCoordinator<DocumentListenState, DocumentSnapshot>(
            targetTemplate: targetTemplate,
            maxRetryAttempts: settings.maxRetryAttempts,
            retryStrategy: settings.retryStrategy,
            nextTargetID: { self.nextListenTargetID() },
            makeState: { targetID in
                DocumentListenState(targetID: targetID, reference: reference)
            },
            reduceResponse: { state, response in
                try state.apply(response)
            },
            resumeToken: { state in
                state.resumeToken
            },
            openStream: { target in
                try await self.listen(target: target)
            }
        ).makeStream()
    }
}
