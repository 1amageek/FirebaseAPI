import Foundation
import GRPCCore

extension FirestoreGRPCRuntime {
    internal func makeFiniteRPCRequest<Message: Sendable>(
        message: Message
    ) async throws -> ClientRequest<Message> {
        ClientRequest(
            message: message,
            metadata: try await authorizedMetadata()
        )
    }

    internal func executeFiniteRPC<Message: Sendable, Output: Sendable>(
        message: Message,
        _ operation: @escaping @Sendable (ClientRequest<Message>) async throws -> Output
    ) async throws -> Output {
        try await finiteRPCExecutor.executeWithRetry {
            let request = try await self.makeFiniteRPCRequest(message: message)
            return try await operation(request)
        }
    }

    internal func executeFiniteRPCWithoutAutomaticRetry<Message: Sendable, Output: Sendable>(
        message: Message,
        _ operation: @escaping @Sendable (ClientRequest<Message>) async throws -> Output
    ) async throws -> Output {
        try await finiteRPCExecutor.executeWithoutAutomaticRetry {
            let request = try await self.makeFiniteRPCRequest(message: message)
            return try await operation(request)
        }
    }
}
