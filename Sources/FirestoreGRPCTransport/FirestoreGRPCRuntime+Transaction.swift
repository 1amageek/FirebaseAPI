import Foundation
import FirestoreCore
import FirestoreRPC
import FirestoreRuntimeSupport
import FirestoreGRPCStubs
import FirestoreProtobuf
import GRPCCore

extension FirestoreGRPCRuntime {
    package func beginTransaction(
        readOnly: Bool,
        readTime: Timestamp?,
        retryTransactionID: Data? = nil
    ) async throws -> Google_Firestore_V1_BeginTransactionResponse {
        let client = Google_Firestore_V1_Firestore.Client(wrapping: self.grpcClient)
        let requestMessage = TransactionRequestCompiler(database: database).makeBeginTransactionRequest(
            readOnly: readOnly,
            readTime: readTime,
            retryTransactionID: retryTransactionID
        )

        return try await executeFiniteRPC(message: requestMessage) { request in
            try await client.beginTransaction(
                request: request,
                options: self.callOptions
            ) { response in
                try response.message
            }
        }
    }

    internal func executeCommit(
        writes: [WriteData],
        transactionID: Data? = nil
    ) async throws -> Google_Firestore_V1_CommitResponse {
        let client = Google_Firestore_V1_Firestore.Client(wrapping: self.grpcClient)

        let requestMessage = try WriteCompiler(database: self.database).makeCommitRequest(
            writes: writes,
            transactionID: transactionID
        )

        return try await executeFiniteRPCWithoutAutomaticRetry(message: requestMessage) { request in
            try await client.commit(
                request: request,
                options: self.callOptions
            ) { response in
                try response.message
            }
        }
    }

    internal func rollbackTransaction(transactionID: Data) async throws {
        let client = Google_Firestore_V1_Firestore.Client(wrapping: self.grpcClient)
        let requestMessage = TransactionRequestCompiler(database: database).makeRollbackRequest(
            transactionID: transactionID
        )

        try await executeFiniteRPC(message: requestMessage) { request in
            try await client.rollback(
                request: request,
                options: self.callOptions
            ) { response in
                _ = try response.message
            }
        }
    }
}

extension FirestoreGRPCRuntime: FirestoreTransactionRuntime {
    package func beginTransactionID(
        readOnly: Bool,
        readTime: Timestamp?,
        retryTransactionID: Data?
    ) async throws -> Data {
        let response = try await beginTransaction(
            readOnly: readOnly,
            readTime: readTime,
            retryTransactionID: retryTransactionID
        )
        return response.transaction
    }

    package func commitWrites(_ writes: [WriteData], transactionID: Data?) async throws -> Bool {
        let response = try await executeCommit(writes: writes, transactionID: transactionID)
        return response.hasCommitTime
    }

    package func rollbackTransactionID(transactionID: Data) async throws {
        try await rollbackTransaction(transactionID: transactionID)
    }
}
